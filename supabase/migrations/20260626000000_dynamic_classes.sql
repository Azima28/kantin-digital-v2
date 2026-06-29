-- Migrasi: Dynamic Classes
-- Tanggal: 2026-06-26

-- 1. Buat tabel master classes jika belum ada
CREATE TABLE IF NOT EXISTS public.classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    level INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Seed default classes untuk memastikan selalu ada data awal jika tabel kosong
INSERT INTO public.classes (name, level)
VALUES 
    ('7-A', 7), ('7-B', 7), ('7-C', 7),
    ('8-A', 8), ('8-B', 8), ('8-C', 8),
    ('9-A', 9), ('9-B', 9), ('9-C', 9),
    ('Belum Diisi', 0)
ON CONFLICT (name) DO NOTHING;

-- 2. Migrasi data unik kelas yang sudah ada dari students ke tabel classes
-- Dapatkan level secara dinamis dari digit angka pertama di nama kelas
INSERT INTO public.classes (name, level)
SELECT DISTINCT class, COALESCE(SUBSTRING(class FROM '^[0-9]+')::INTEGER, 0)
FROM public.students
WHERE class IS NOT NULL AND class <> '' AND class NOT IN (SELECT name FROM public.classes)
ON CONFLICT (name) DO NOTHING;

-- 3. Tambahkan kolom class_id ke tabel students
ALTER TABLE public.students 
ADD COLUMN IF NOT EXISTS class_id UUID REFERENCES public.classes(id) ON DELETE SET NULL;

-- 4. Hubungkan data students yang ada ke class_id yang sesuai
UPDATE public.students s
SET class_id = c.id
FROM public.classes c
WHERE s.class = c.name;

-- 5. Drop kolom class lama di students
ALTER TABLE public.students DROP COLUMN IF EXISTS class;

-- 6. Perbarui fungsi trigger handle_new_user agar menggunakan tabel classes secara dinamis
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_role TEXT;
    v_name TEXT;
    v_class_name TEXT;
    v_class_id UUID;
BEGIN
    -- Menentukan role default
    v_role := COALESCE(new.raw_user_meta_data->>'role', 'student');
    v_name := COALESCE(new.raw_user_meta_data->>'full_name', 'User Baru');

    -- Memasukkan data ke tabel public.profiles
    INSERT INTO public.profiles (id, email, full_name, role)
    VALUES (new.id, new.email, v_name, v_role)
    ON CONFLICT (id) DO NOTHING;

    -- Memasukkan data ke tabel turunan berdasarkan role
    IF v_role = 'student' THEN
        v_class_name := COALESCE(new.raw_user_meta_data->>'class', 'Belum Diisi');
        
        -- Dapatkan atau buat kelas secara dinamis
        SELECT id INTO v_class_id FROM public.classes WHERE name = v_class_name;
        IF v_class_id IS NULL THEN
            INSERT INTO public.classes (name, level)
            VALUES (
                v_class_name, 
                COALESCE(SUBSTRING(v_class_name FROM '^[0-9]+')::INTEGER, 0)
            )
            RETURNING id INTO v_class_id;
        END IF;

        INSERT INTO public.students (id, class_id, balance, is_active)
        VALUES (new.id, v_class_id, 0.00, true)
        ON CONFLICT (id) DO UPDATE SET class_id = EXCLUDED.class_id;
    ELSIF v_role = 'petugas_kantin' THEN
        INSERT INTO public.canteen_operators (id, canteen_name, balance_earned)
        VALUES (new.id, COALESCE(new.raw_user_meta_data->>'canteen_name', 'Stan Kantin'), 0.00)
        ON CONFLICT (id) DO NOTHING;
    END IF;

    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Perbarui fungsi create_user_account agar menggunakan class_id secara dinamis
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
        -- Cari atau buat kelas secara dinamis
        IF p_class IS NOT NULL AND p_class <> '' THEN
            SELECT id INTO v_class_id FROM public.classes WHERE name = p_class;
            IF v_class_id IS NULL THEN
                INSERT INTO public.classes (name, level)
                VALUES (
                    p_class, 
                    COALESCE(SUBSTRING(p_class FROM '^[0-9]+')::INTEGER, 0)
                )
                RETURNING id INTO v_class_id;
            END IF;
        ELSE
            SELECT id INTO v_class_id FROM public.classes WHERE name = 'Belum Diisi';
        END IF;

        UPDATE public.students
        SET class_id = v_class_id,
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
                extensions.crypt(p_password, extensions.gen_salt('bf')), -- Password ortu samakan dengan siswa
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

        -- Hubungkan Orang Tua dan Siswa di tabel parent_students
        INSERT INTO public.parent_students (parent_id, student_id)
        VALUES (v_parent_id, v_id)
        ON CONFLICT DO NOTHING;
    END IF;

    -- Return profile info
    SELECT row_to_json(p)::jsonb INTO v_profile 
    FROM public.profiles p 
    WHERE id = v_id;
    
    RETURN v_profile;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Aktifkan RLS dan atur kebijakan hak akses pada tabel classes
ALTER TABLE public.classes ENABLE ROW LEVEL SECURITY;

-- Semua user terautentikasi bisa membaca kelas
CREATE POLICY "Semua pengguna terautentikasi dapat melihat kelas"
    ON public.classes FOR SELECT TO authenticated USING (true);

-- Hanya petugas keuangan, admin, dan super admin yang bisa mengubah kelas
CREATE POLICY "Admin dan Keuangan dapat mengelola kelas"
    ON public.classes FOR ALL TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'petugas_keuangan')
        )
    ) WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'petugas_keuangan')
        )
    );
