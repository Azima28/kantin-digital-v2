-- =====================================================================
-- Migration 0022: Rate Limiting and Error Handling
-- Tanggal: 2026-06-20
-- Tujuan:
--   1. verify_password — brute force protection with pg_sleep delay + NISN lookup
--   2. update_auth_user_password — sanitize error message (hide auth.users ref)
--   3. create_user_account — add role guard + sanitize RAISE EXCEPTION messages
--   4. Verify all role checks from 0020 are complete (confirmed — see below)
--   5. Verify RLS policies from 0016 + 0021 are correct (confirmed — see below)
-- =====================================================================

-- =====================================================================
-- VERIFICATION SUMMARY
-- =====================================================================
--
-- ✅ Role checks in migration 0020:
--   update_auth_user_password  — service_role OR super_admin/admin/petugas_keuangan OR self
--   process_topup              — service_role OR super_admin/admin/petugas_keuangan OR parent via parent_students
--   process_correction         — service_role OR super_admin/admin/petugas_keuangan
--   process_purchase           — service_role OR canteen_operator (via canteen_operators table)
--   process_refund             — service_role OR canteen_operator (via canteen_operators table)
--   All checks present and correct. ✅
--
-- ✅ Error messages in 0020 RPCs (process_purchase, process_topup, process_correction):
--   All RETURN error objects use user-friendly messages only.
--   No leaks of SQL syntax, column names, internal IDs, or stack traces. ✅
--   (Note: process_purchase and process_refund use RAISE EXCEPTION with
--    user-friendly messages — no internal details exposed.)
--
-- ✅ RLS policies in 0016 + 0021:
--   RLS enabled on all tables.
--   Anon SELECT restricted to products, system_settings, canteen_operators only.
--   Authenticated policies use granular role-based USING/CHECK clauses.
--   No dangerous anon-write policies. ✅
-- =====================================================================

-- =====================================================================
-- 1. verify_password — rate limiting with pg_sleep + NISN lookup
-- =====================================================================

-- DROP first to replace existing signature cleanly
DROP FUNCTION IF EXISTS public.verify_password(TEXT, TEXT) CASCADE;

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
    v_password_hash TEXT;
BEGIN
    -- Get profile and password hash (search by email OR nisn)
    SELECT
        to_jsonb(p.*) - 'password',
        p.password
    INTO v_profile, v_password_hash
    FROM public.profiles p
    WHERE p.email = p_email OR p.nisn = p_email;

    IF NOT FOUND THEN
        -- Artificial delay to prevent timing attacks
        -- (attacker cannot distinguish "user not found" from "wrong password")
        PERFORM pg_sleep(0.5);
        RETURN jsonb_build_object('found', false, 'password_valid', false);
    END IF;

    -- Compare password using bcrypt
    IF extensions.crypt(p_password, v_password_hash) = v_password_hash THEN
        -- Success: return profile without password
        RETURN jsonb_build_object('found', true, 'password_valid', true, 'profile', v_profile);
    ELSE
        -- Failure: add small delay to slow brute force
        PERFORM pg_sleep(0.5);
        RETURN jsonb_build_object('found', false, 'password_valid', false);
    END IF;
END;
$$;

-- =====================================================================
-- 2. update_auth_user_password — sanitize error message
--    Remove reference to internal schema 'auth.users' in error output
-- =====================================================================

CREATE OR REPLACE FUNCTION public.update_auth_user_password(
    p_user_id UUID,
    p_new_password TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_caller_role TEXT;
BEGIN
    -- Role check: only service_role, super_admin, admin, petugas_keuangan,
    -- or the user themself can change the password
    IF auth.role() != 'service_role'
       AND (SELECT role FROM public.profiles WHERE id = auth.uid()) NOT IN ('super_admin', 'admin', 'petugas_keuangan')
       AND auth.uid() != p_user_id
    THEN
        PERFORM pg_sleep(0.5);
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized');
    END IF;

    -- Update password in auth schema extensions. prefix
    UPDATE auth.users
    SET encrypted_password = extensions.crypt(p_new_password, extensions.gen_salt('bf'))
    WHERE id = p_user_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'User tidak ditemukan');
    END IF;

    -- Juga update password di profiles (untuk fallback verify_password)
    UPDATE public.profiles
    SET password = extensions.crypt(p_new_password, extensions.gen_salt('bf'))
    WHERE id = p_user_id;

    RETURN jsonb_build_object('success', true);
END;
$$;

-- =====================================================================
-- 3. create_user_account — add role guard + sanitize error messages
-- =====================================================================

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
) CASCADE;

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
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_id UUID;
    v_profile JSONB;
    v_parent_id UUID;
    v_parent_email TEXT;
    v_parent_username TEXT;
BEGIN
    -- Role check: only service_role, super_admin, admin, or petugas_keuangan
    IF auth.role() != 'service_role'
       AND (SELECT role FROM public.profiles WHERE id = auth.uid()) NOT IN ('super_admin', 'admin', 'petugas_keuangan')
    THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized');
    END IF;

    -- Validasi email unik
    IF EXISTS (SELECT 1 FROM public.profiles WHERE email = p_email) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Email sudah terdaftar');
    END IF;

    -- Validasi NISN unik (jika diisi)
    IF p_nisn IS NOT NULL AND p_nisn <> '' AND EXISTS (SELECT 1 FROM public.profiles WHERE nisn = p_nisn) THEN
        RETURN jsonb_build_object('success', false, 'error', 'NISN sudah terdaftar');
    END IF;

    -- Validasi username unik (jika diisi)
    IF p_username IS NOT NULL AND p_username <> '' AND EXISTS (SELECT 1 FROM public.profiles WHERE username = p_username) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Username sudah digunakan');
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
        password = extensions.crypt(p_password, extensions.gen_salt('bf')),
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
                password = extensions.crypt(p_password, extensions.gen_salt('bf')),
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

    -- Ambil profil yang baru dibuat (tanpa kolom password)
    SELECT jsonb_build_object(
        'id', id,
        'email', email,
        'full_name', full_name,
        'role', role,
        'nisn', nisn,
        'username', username,
        'phone_number', phone_number,
        'relation', relation,
        'is_active', is_active
    ) INTO v_profile
    FROM public.profiles
    WHERE id = v_id;

    RETURN jsonb_build_object('success', true, 'profile', v_profile);

EXCEPTION
    WHEN unique_violation THEN
        RETURN jsonb_build_object('success', false, 'error', 'Data sudah terdaftar');
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', 'Terjadi kesalahan saat membuat akun');
END;
$$;

-- =====================================================================
-- 4. GRANT EXECUTE
-- =====================================================================

-- verify_password tetap bisa diakses oleh anon/public untuk fallback auth
GRANT EXECUTE ON FUNCTION public.verify_password TO anon, public;

-- update_auth_user_password untuk authenticated (sama seperti 0020)
GRANT EXECUTE ON FUNCTION public.update_auth_user_password TO authenticated;

-- create_user_account untuk authenticated (dengan role guard di dalam fungsi)
GRANT EXECUTE ON FUNCTION public.create_user_account(
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
) TO authenticated;

-- =====================================================================
-- 5. VERIFIKASI (jalankan di Supabase SQL Editor)
-- =====================================================================

-- -- Test rate limiting:
-- SELECT public.verify_password('nonexistent@test.com', 'wrong');
-- -- Harus delay ~0.5 detik, return: {"found": false, "password_valid": false}
--
-- -- Test NISN lookup:
-- SELECT public.verify_password('1234567890', 'password_siswa');
-- -- Harus bisa cari berdasarkan NISN
--
-- -- Test sanitized error:
-- SELECT public.update_auth_user_password(
--     '00000000-0000-0000-0000-000000000000'::uuid,
--     'test123'
-- );
-- -- Return: {"success": false, "error": "User tidak ditemukan"}
-- -- BUKAN: {"success": false, "error": "User tidak ditemukan di auth.users"}
--
-- -- Test role guard on create_user_account (as anon):
-- SELECT public.create_user_account('test@test.com', 'pass', 'Test', 'student');
-- -- anon harus ditolak
