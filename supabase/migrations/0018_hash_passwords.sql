-- Migrasi: Hash password profiles menggunakan bcrypt
-- Alasan: Password masih plaintext di kolom profiles.password.
--          pgcrypto extension sudah enable dari migration sebelumnya.
--
-- RPC verify_password di-update untuk pake crypt() comparison.
-- create_user_account RPC perlu di-update handle hashing.

-- =====================================================================
-- 1. HASH SEMUA PASSWORD YANG MASIH PLAINTEXT
-- =====================================================================
-- Hanya hash password yang BELUM berupa bcrypt hash (mulai dengan '$2')
UPDATE public.profiles
SET password = extensions.crypt(password, extensions.gen_salt('bf'))
WHERE password IS NOT NULL
  AND password != ''
  AND password NOT LIKE '$2%';

-- =====================================================================
-- 2. UPDATE RPC verify_password — pake bcrypt comparison
-- =====================================================================
CREATE OR REPLACE FUNCTION public.verify_password(
    p_email TEXT,
    p_password TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_profile JSONB;
BEGIN
    SELECT jsonb_build_object(
        'id', p.id,
        'email', p.email,
        'full_name', p.full_name,
        'role', p.role,
        'nisn', p.nisn,
        'phone_number', p.phone_number,
        'username', p.username,
        'avatar_url', p.avatar_url,
        'relation', p.relation,
        'is_active', p.is_active,
        'password_valid', (p.password = extensions.crypt(p_password, p.password))
    ) INTO v_profile
    FROM public.profiles p
    WHERE p.email = p_email
    LIMIT 1;

    IF v_profile IS NULL THEN
        RETURN jsonb_build_object('found', false, 'password_valid', false);
    END IF;

    RETURN v_profile;
END;
$$;

-- =====================================================================
-- 3. UPDATE RPC create_user_account — hash password sebelum simpan
-- =====================================================================
CREATE OR REPLACE FUNCTION public.create_user_account(
    p_email TEXT,
    p_password TEXT,
    p_full_name TEXT,
    p_role TEXT,
    p_nisn TEXT DEFAULT NULL,
    p_class TEXT DEFAULT NULL,
    p_canteen_name TEXT DEFAULT NULL,
    p_phone_number TEXT DEFAULT NULL,
    p_parent_role TEXT DEFAULT NULL,
    p_relation TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_user_id UUID;
    v_result JSONB;
BEGIN
    -- 1. Buat user di auth.users
    INSERT INTO auth.users (
        instance_id, email, encrypted_password, 
        email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
        aud, role, created_at, updated_at
    ) VALUES (
        '00000000-0000-0000-0000-000000000000',
        p_email,
        extensions.crypt(p_password, extensions.gen_salt('bf')),  -- ← Hash untuk auth.users
        now(),
        '{"provider": "email", "providers": ["email"]}',
        jsonb_build_object('full_name', p_full_name, 'role', p_role),
        'authenticated',
        'authenticated',
        now(),
        now()
    )
    RETURNING id INTO v_user_id;

    -- 2. Insert ke profiles dengan password SUDAH DI-HASH
    INSERT INTO public.profiles (id, email, full_name, role, nisn, phone_number, password)
    VALUES (
        v_user_id,
        p_email,
        p_full_name,
        p_role,
        p_nisn,
        p_phone_number,
        extensions.crypt(p_password, extensions.gen_salt('bf'))  -- ← Hash password
    );

    -- 3. Insert ke tabel turunan
    IF p_role = 'student' THEN
        INSERT INTO public.students (id, class, balance, is_active)
        VALUES (v_user_id, COALESCE(p_class, 'Belum Diisi'), 0.00, true);
    ELSIF p_role = 'petugas_kantin' THEN
        INSERT INTO public.canteen_operators (id, canteen_name, balance_earned)
        VALUES (v_user_id, COALESCE(p_canteen_name, 'Stan Kantin'), 0.00);
    ELSIF p_role = 'petugas_keuangan' THEN
        INSERT INTO public.finance_officers (id, assigned_school, authority_level, features)
        VALUES (v_user_id, COALESCE(p_class, 'SMP Terpadu'), 'L1', ARRAY['topup', 'withdrawal', 'correction']);
    END IF;

    -- 4. Return user info (TANPA password)
    SELECT jsonb_build_object(
        'id', p.id,
        'email', p.email,
        'full_name', p.full_name,
        'role', p.role
    ) INTO v_result
    FROM public.profiles p
    WHERE p.id = v_user_id;

    RETURN jsonb_build_object('success', true, 'profile', v_result);

EXCEPTION
    WHEN unique_violation THEN
        RETURN jsonb_build_object('success', false, 'error', 'Email sudah terdaftar');
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;
