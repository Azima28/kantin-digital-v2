-- Migrasi: Split Classes and Rombels
-- Tanggal: 2026-06-26

-- 1. Buat tabel master rombels jika belum ada
CREATE TABLE IF NOT EXISTS public.rombels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Seed default rombel data
INSERT INTO public.rombels (name)
VALUES ('A'), ('B'), ('C'), ('-')
ON CONFLICT (name) DO NOTHING;

-- 2. Tambahkan kolom rombel_id ke tabel students
ALTER TABLE public.students 
ADD COLUMN IF NOT EXISTS rombel_id UUID REFERENCES public.rombels(id) ON DELETE SET NULL;

-- 3. Loop untuk memisahkan data kelas gabungan lama ("7-A" menjadi Kelas "7" dan Rombel "A")
DO $$
DECLARE
    r RECORD;
    v_grade_name TEXT;
    v_rombel_name TEXT;
    v_rombel_id UUID;
    v_class_id UUID;
BEGIN
    FOR r IN SELECT * FROM public.classes LOOP
        -- Deteksi hyphen '-' untuk pemisahan
        IF POSITION('-' IN r.name) > 0 THEN
            v_grade_name := SPLIT_PART(r.name, '-', 1);
            v_rombel_name := SPLIT_PART(r.name, '-', 2);
        ELSE
            v_grade_name := r.name;
            v_rombel_name := '-';
        END IF;

        -- Trim spasi
        v_grade_name := TRIM(v_grade_name);
        v_rombel_name := TRIM(v_rombel_name);
        IF v_rombel_name = '' THEN
            v_rombel_name := '-';
        END IF;

        -- Dapatkan atau buat rombel
        INSERT INTO public.rombels (name)
        VALUES (v_rombel_name)
        ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
        RETURNING id INTO v_rombel_id;

        -- Dapatkan atau buat grade kelas
        INSERT INTO public.classes (name, level)
        VALUES (v_grade_name, r.level)
        ON CONFLICT (name) DO UPDATE SET level = EXCLUDED.level
        RETURNING id INTO v_class_id;

        -- Perbarui data siswa yang terasosiasi ke id kelas gabungan lama ini
        UPDATE public.students
        SET class_id = v_class_id,
            rombel_id = v_rombel_id
        WHERE class_id = r.id;
    END LOOP;
END;
$$;

-- 4. Bersihkan data kelas lama yang masih menggunakan format gabungan (yang tidak dirujuk siswa lagi)
DELETE FROM public.classes 
WHERE name LIKE '%-%' 
  AND id NOT IN (SELECT DISTINCT class_id FROM public.students WHERE class_id IS NOT NULL);

-- 5. Aktifkan RLS dan atur kebijakan hak akses pada tabel rombels
ALTER TABLE public.rombels ENABLE ROW LEVEL SECURITY;

-- Semua user terautentikasi bisa membaca rombel
CREATE POLICY "Semua pengguna terautentikasi dapat melihat rombel"
    ON public.rombels FOR SELECT TO authenticated USING (true);

-- Hanya super admin yang bisa memodifikasi rombel
CREATE POLICY "Hanya Super Admin yang dapat mengelola rombel"
    ON public.rombels FOR ALL TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'super_admin'
        )
    ) WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'super_admin'
        )
    );

-- 6. Perbarui trigger handle_new_user agar mendukung pemisahan kelas & rombel secara otomatis
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_role TEXT;
    v_name TEXT;
    v_class_raw TEXT;
    v_grade_name TEXT;
    v_rombel_name TEXT;
    v_class_id UUID;
    v_rombel_id UUID;
BEGIN
    v_role := COALESCE(new.raw_user_meta_data->>'role', 'student');
    v_name := COALESCE(new.raw_user_meta_data->>'full_name', 'User Baru');

    INSERT INTO public.profiles (id, email, full_name, role)
    VALUES (new.id, new.email, v_name, v_role)
    ON CONFLICT (id) DO NOTHING;

    IF v_role = 'student' THEN
        v_class_raw := COALESCE(new.raw_user_meta_data->>'class', 'Belum Diisi');
        
        -- Deteksi pemisahan kelas
        IF POSITION('-' IN v_class_raw) > 0 THEN
            v_grade_name := TRIM(SPLIT_PART(v_class_raw, '-', 1));
            v_rombel_name := TRIM(SPLIT_PART(v_class_raw, '-', 2));
        ELSE
            v_grade_name := TRIM(v_class_raw);
            v_rombel_name := '-';
        END IF;

        IF v_rombel_name = '' THEN
            v_rombel_name := '-';
        END IF;
        
        -- Dapatkan atau buat kelas
        SELECT id INTO v_class_id FROM public.classes WHERE name = v_grade_name;
        IF v_class_id IS NULL THEN
            INSERT INTO public.classes (name, level)
            VALUES (
                v_grade_name, 
                COALESCE(SUBSTRING(v_grade_name FROM '^[0-9]+')::INTEGER, 0)
            )
            RETURNING id INTO v_class_id;
        END IF;

        -- Dapatkan atau buat rombel
        SELECT id INTO v_rombel_id FROM public.rombels WHERE name = v_rombel_name;
        IF v_rombel_id IS NULL THEN
            INSERT INTO public.rombels (name)
            VALUES (v_rombel_name)
            RETURNING id INTO v_rombel_id;
        END IF;

        INSERT INTO public.students (id, class_id, rombel_id, balance, is_active)
        VALUES (new.id, v_class_id, v_rombel_id, 0.00, true)
        ON CONFLICT (id) DO UPDATE SET class_id = EXCLUDED.class_id, rombel_id = EXCLUDED.rombel_id;
    ELSIF v_role = 'petugas_kantin' THEN
        INSERT INTO public.canteen_operators (id, canteen_name, balance_earned)
        VALUES (new.id, COALESCE(new.raw_user_meta_data->>'canteen_name', 'Stan Kantin'), 0.00)
        ON CONFLICT (id) DO NOTHING;
    END IF;

    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Perbarui RPC create_user_account agar mendukung pemisahan kelas & rombel secara otomatis
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
    v_class_id UUID;
    v_rombel_id UUID;
    v_grade_name TEXT;
    v_rombel_name TEXT;
BEGIN
    IF EXISTS (SELECT 1 FROM public.profiles WHERE email = p_email) THEN
        RAISE EXCEPTION 'Email % sudah terdaftar', p_email;
    END IF;

    IF p_nisn IS NOT NULL AND p_nisn <> '' AND EXISTS (SELECT 1 FROM public.profiles WHERE nisn = p_nisn) THEN
        RAISE EXCEPTION 'NISN % sudah terdaftar', p_nisn;
    END IF;

    IF p_username IS NOT NULL AND p_username <> '' AND EXISTS (SELECT 1 FROM public.profiles WHERE username = p_username) THEN
        RAISE EXCEPTION 'Username % sudah digunakan', p_username;
    END IF;

    v_id := gen_random_uuid();

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

    UPDATE public.profiles
    SET username = p_username,
        password = p_password,
        phone_number = p_phone_number,
        nisn = p_nisn,
        is_active = p_is_active,
        relation = p_relation
    WHERE id = v_id;

    IF p_role = 'student' THEN
        IF p_class IS NOT NULL AND p_class <> '' THEN
            IF POSITION('-' IN p_class) > 0 THEN
                v_grade_name := TRIM(SPLIT_PART(p_class, '-', 1));
                v_rombel_name := TRIM(SPLIT_PART(p_class, '-', 2));
            ELSE
                v_grade_name := TRIM(p_class);
                v_rombel_name := '-';
            END IF;
            IF v_rombel_name = '' THEN
                v_rombel_name := '-';
            END IF;
        ELSE
            v_grade_name := 'Belum Diisi';
            v_rombel_name := '-';
        END IF;

        -- Cari atau buat kelas
        SELECT id INTO v_class_id FROM public.classes WHERE name = v_grade_name;
        IF v_class_id IS NULL THEN
            INSERT INTO public.classes (name, level)
            VALUES (
                v_grade_name, 
                COALESCE(SUBSTRING(v_grade_name FROM '^[0-9]+')::INTEGER, 0)
            )
            RETURNING id INTO v_class_id;
        END IF;

        -- Cari atau buat rombel
        SELECT id INTO v_rombel_id FROM public.rombels WHERE name = v_rombel_name;
        IF v_rombel_id IS NULL THEN
            INSERT INTO public.rombels (name)
            VALUES (v_rombel_name)
            RETURNING id INTO v_rombel_id;
        END IF;

        UPDATE public.students
        SET class_id = v_class_id,
            rombel_id = v_rombel_id,
            is_active = p_is_active,
            rfid_uid = p_rfid_uid,
            parent_phone = p_parent_phone
        WHERE id = v_id;

        v_parent_email := 'parent.' || p_email;
        v_parent_username := 'parent_' || COALESCE(p_username, 'student_' || p_nisn);
        v_parent_id := NULL;

        IF p_parent_phone IS NOT NULL AND p_parent_phone <> '' THEN
            SELECT id INTO v_parent_id 
            FROM public.profiles 
            WHERE phone_number = p_parent_phone AND role = 'parent' 
            LIMIT 1;
        END IF;

        IF v_parent_id IS NULL THEN
            SELECT id INTO v_parent_id 
            FROM public.profiles 
            WHERE email = v_parent_email 
            LIMIT 1;
        END IF;

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
                    'full_name', 'Ortu ' || p_full_name,
                    'role', 'parent',
                    'relation', 'Wali'
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
                is_active = true,
                relation = 'Wali'
            WHERE id = v_parent_id;
        END IF;

        INSERT INTO public.parent_students (parent_id, student_id)
        VALUES (v_parent_id, v_id)
        ON CONFLICT DO NOTHING;
    END IF;

    SELECT row_to_json(p)::jsonb INTO v_profile 
    FROM public.profiles p 
    WHERE id = v_id;
    
    RETURN v_profile;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
