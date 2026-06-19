-- Migrasi: Penyesuaian Registrasi Akun Pengguna via RPC & Penambahan Kolom Relation
-- Tanggal: 2026-06-19

-- 1. Tambahkan kolom relation ke public.profiles jika belum ada
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS relation TEXT;

-- 2. Hapus trigger dan fungsi sinkronisasi lama agar tidak mengganggu constraint
DROP TRIGGER IF EXISTS tr_sync_profile_to_auth ON public.profiles;
DROP FUNCTION IF EXISTS public.sync_profile_to_auth();
DROP FUNCTION IF EXISTS public.create_user_account(p_email TEXT, p_password TEXT, p_full_name TEXT, p_role TEXT, p_phone_number TEXT, p_username TEXT, p_nisn TEXT, p_class TEXT, p_canteen_name TEXT, p_relation TEXT, p_is_active BOOLEAN);

-- 3. Kembalikan fungsi handle_new_user ke bentuk standar yang aman
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_role TEXT;
    v_name TEXT;
BEGIN
    v_role := COALESCE(new.raw_user_meta_data->>'role', 'student');
    v_name := COALESCE(new.raw_user_meta_data->>'full_name', 'User Baru');

    -- Memasukkan data ke tabel public.profiles
    INSERT INTO public.profiles (id, email, full_name, role)
    VALUES (new.id, new.email, v_name, v_role)
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = EXCLUDED.full_name,
        role = EXCLUDED.role;

    -- Memasukkan data ke tabel turunan berdasarkan role
    IF v_role = 'student' THEN
        INSERT INTO public.students (id, class, balance, is_active)
        VALUES (new.id, COALESCE(new.raw_user_meta_data->>'class', 'Belum Diisi'), 0.00, true)
        ON CONFLICT (id) DO NOTHING;
    ELSIF v_role = 'petugas_kantin' THEN
        INSERT INTO public.canteen_operators (id, canteen_name, balance_earned)
        VALUES (new.id, COALESCE(new.raw_user_meta_data->>'canteen_name', 'Stan Kantin'), 0.00)
        ON CONFLICT (id) DO NOTHING;
    ELSIF v_role = 'petugas_keuangan' THEN
        INSERT INTO public.finance_officers (id, assigned_school, authority_level, features)
        VALUES (new.id, COALESCE(new.raw_user_meta_data->>'assigned_school', 'SMP Terpadu'), 'L1', ARRAY['topup', 'withdrawal', 'correction'])
        ON CONFLICT (id) DO NOTHING;
    END IF;

    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Buat fungsi RPC secure create_user_account
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
