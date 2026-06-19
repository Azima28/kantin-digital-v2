-- Migrasi: Auto-Create Akun Orang Tua & Retroactive Sync
-- Tanggal: 2026-06-19

-- 1. Hapus fungsi lama dengan 13 parameter
DROP FUNCTION IF EXISTS public.create_user_account(
    p_email TEXT,
    p_password TEXT,
    p_full_name TEXT,
    p_role TEXT,
    p_phone_number TEXT,
    p_username TEXT,
    p_nisn TEXT,
    p_class TEXT,
    p_canteen_name TEXT,
    p_relation TEXT,
    p_is_active BOOLEAN,
    p_rfid_uid TEXT,
    p_parent_phone TEXT
);

-- 2. Buat fungsi baru dengan penanganan auto-create Orang Tua untuk role student
CREATE OR REPLACE FUNCTION public.create_user_account(
    p_email TEXT,
    p_password TEXT,
    p_full_name TEXT,
    p_role TEXT,
    p_phone_number TEXT DEFAULT NULL,
    p_username TEXT DEFAULT NULL,
    p_nisn TEXT DEFAULT NULL,
    p_class TEXT DEFAULT NULL,
    p_canteen_name TEXT DEFAULT NULL,
    p_relation TEXT DEFAULT NULL,
    p_is_active BOOLEAN DEFAULT true,
    p_rfid_uid TEXT DEFAULT NULL,
    p_parent_phone TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_id UUID;
    v_profile JSONB;
    v_parent_id UUID;
    v_parent_email TEXT;
    v_parent_username TEXT;
BEGIN
    -- Validasi email unik
    IF EXISTS (SELECT 1 FROM public.profiles WHERE email = p_email) THEN
        RAISE EXCEPTION 'Email % sudah terdaftar', p_email;
    END IF;

    -- Validasi NISN unik (jika diisi)
    IF p_nisn IS NOT NULL AND p_nisn <> '' AND EXISTS (SELECT 1 FROM public.profiles WHERE nisn = p_nisn) THEN
        RAISE EXCEPTION 'NISN % sudah terdaftar', p_nisn;
    END IF;

    -- Validasi username unik (jika diisi)
    IF p_username IS NOT NULL AND p_username <> '' AND EXISTS (SELECT 1 FROM public.profiles WHERE username = p_username) THEN
        RAISE EXCEPTION 'Username % sudah digunakan', p_username;
    END IF;

    -- Generate UUID baru
    v_id := gen_random_uuid();

    -- Insert ke auth.users
    INSERT INTO auth.users (
        id,
        instance_id,
        email,
        encrypted_password,
        email_confirmed_at,
        raw_app_meta_data,
        raw_user_meta_data,
        aud,
        role,
        created_at,
        updated_at
    )
    VALUES (
        v_id,
        '00000000-0000-0000-0000-000000000000'::uuid,
        p_email,
        extensions.crypt(p_password, extensions.gen_salt('bf')),
        now(),
        jsonb_build_object('provider', 'email', 'providers', ARRAY['email']),
        jsonb_build_object(
            'full_name', p_full_name,
            'role', p_role,
            'class', p_class,
            'canteen_name', p_canteen_name,
            'assigned_school', 'SMP Terpadu'
        ),
        'authenticated',
        'authenticated',
        now(),
        now()
    );

    -- Update field tambahan di profiles
    UPDATE public.profiles
    SET username = p_username,
        password = p_password,
        phone_number = p_phone_number,
        nisn = p_nisn,
        is_active = p_is_active,
        relation = p_relation
    WHERE id = v_id;

    -- Update tabel relasional spesifik role
    IF p_role = 'student' THEN
        UPDATE public.students
        SET class = COALESCE(p_class, class),
            is_active = p_is_active,
            rfid_uid = p_rfid_uid,
            parent_phone = p_parent_phone
        WHERE id = v_id;

        -- =====================================================================
        -- AUTO-CREATE AKUN ORANG TUA
        -- =====================================================================
        v_parent_email := 'parent.' || p_email;
        v_parent_username := 'parent_' || COALESCE(p_username, 'student_' || p_nisn);
        v_parent_id := NULL;

        -- Cari apakah wali dengan no telp yang sama sudah ada di sistem
        IF p_parent_phone IS NOT NULL AND p_parent_phone <> '' THEN
            SELECT id INTO v_parent_id 
            FROM public.profiles 
            WHERE phone_number = p_parent_phone AND role = 'parent' 
            LIMIT 1;
        END IF;

        -- Cari apakah wali dengan email ini sudah ada di sistem
        IF v_parent_id IS NULL THEN
            SELECT id INTO v_parent_id 
            FROM public.profiles 
            WHERE email = v_parent_email 
            LIMIT 1;
        END IF;

        -- Jika belum ada wali, buat akun wali baru
        IF v_parent_id IS NULL THEN
            v_parent_id := gen_random_uuid();
            
            INSERT INTO auth.users (
                id,
                instance_id,
                email,
                encrypted_password,
                email_confirmed_at,
                raw_app_meta_data,
                raw_user_meta_data,
                aud,
                role,
                created_at,
                updated_at
            )
            VALUES (
                v_parent_id,
                '00000000-0000-0000-0000-000000000000'::uuid,
                v_parent_email,
                extensions.crypt(p_password, extensions.gen_salt('bf')),
                now(),
                jsonb_build_object('provider', 'email', 'providers', ARRAY['email']),
                jsonb_build_object(
                    'full_name', 'Orang Tua ' || p_full_name,
                    'role', 'parent'
                ),
                'authenticated',
                'authenticated',
                now(),
                now()
            );

            UPDATE public.profiles
            SET username = v_parent_username,
                password = p_password,
                phone_number = p_parent_phone,
                is_active = true
            WHERE id = v_parent_id;
        END IF;

        -- Hubungkan siswa dengan wali
        INSERT INTO public.parent_students (parent_id, student_id)
        VALUES (v_parent_id, v_id)
        ON CONFLICT (parent_id, student_id) DO NOTHING;

    ELSIF p_role = 'petugas_kantin' AND p_canteen_name IS NOT NULL THEN
        UPDATE public.canteen_operators
        SET canteen_name = p_canteen_name
        WHERE id = v_id;
    END IF;

    -- Ambil profil yang baru dibuat
    SELECT jsonb_build_object(
        'id', id,
        'email', email,
        'full_name', full_name,
        'role', role,
        'nisn', nisn,
        'username', username,
        'password', password,
        'phone_number', phone_number,
        'relation', relation,
        'is_active', is_active
    ) INTO v_profile
    FROM public.profiles
    WHERE id = v_id;

    RETURN v_profile;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 3. Retroactive Sync: Buat akun Orang Tua untuk semua siswa lama yang belum memilikinya
DO $$
DECLARE
    r RECORD;
    v_parent_id UUID;
    v_parent_email TEXT;
    v_parent_username TEXT;
    v_student_email TEXT;
    v_student_name TEXT;
    v_student_username TEXT;
    v_parent_phone TEXT;
    v_password TEXT;
BEGIN
    FOR r IN 
        SELECT s.id, p.email, p.full_name, p.username, p.password, s.parent_phone, p.nisn
        FROM public.students s
        JOIN public.profiles p ON s.id = p.id
        LEFT JOIN public.parent_students ps ON s.id = ps.student_id
        WHERE ps.student_id IS NULL
    LOOP
        v_student_email := r.email;
        v_student_name := r.full_name;
        v_student_username := COALESCE(r.username, 'student_' || COALESCE(r.nisn, r.id::text));
        v_parent_phone := r.parent_phone;
        v_password := COALESCE(r.password, 'password123');
        
        v_parent_email := 'parent.' || v_student_email;
        v_parent_username := 'parent_' || v_student_username;
        v_parent_id := NULL;

        -- Cek jika wali dengan no hp ini sudah ada
        IF v_parent_phone IS NOT NULL AND v_parent_phone <> '' THEN
            SELECT id INTO v_parent_id 
            FROM public.profiles 
            WHERE phone_number = v_parent_phone AND role = 'parent' 
            LIMIT 1;
        END IF;

        -- Cek jika wali dengan email ini sudah ada
        IF v_parent_id IS NULL THEN
            SELECT id INTO v_parent_id 
            FROM public.profiles 
            WHERE email = v_parent_email 
            LIMIT 1;
        END IF;

        -- Jika belum ada, buat akun wali baru
        IF v_parent_id IS NULL THEN
            v_parent_id := gen_random_uuid();
            
            INSERT INTO auth.users (
                id,
                instance_id,
                email,
                encrypted_password,
                email_confirmed_at,
                raw_app_meta_data,
                raw_user_meta_data,
                aud,
                role,
                created_at,
                updated_at
            )
            VALUES (
                v_parent_id,
                '00000000-0000-0000-0000-000000000000'::uuid,
                v_parent_email,
                extensions.crypt(v_password, extensions.gen_salt('bf')),
                now(),
                jsonb_build_object('provider', 'email', 'providers', ARRAY['email']),
                jsonb_build_object(
                    'full_name', 'Orang Tua ' || v_student_name,
                    'role', 'parent'
                ),
                'authenticated',
                'authenticated',
                now(),
                now()
            );

            UPDATE public.profiles
            SET username = v_parent_username,
                password = v_password,
                phone_number = v_parent_phone,
                is_active = true
            WHERE id = v_parent_id;
        END IF;

        -- Hubungkan siswa dengan wali
        INSERT INTO public.parent_students (parent_id, student_id)
        VALUES (v_parent_id, r.id)
        ON CONFLICT (parent_id, student_id) DO NOTHING;
    END LOOP;
END;
$$;
