-- =====================================================================
-- Migration: Fix update_auth_user_password fallback authorization
-- Tanggal: 2026-06-24
-- Tujuan: Mengizinkan role anon/public mengeksekusi update_auth_user_password 
--         dalam mode fallback auth dengan memvalidasi parameter p_caller_id 
--         sebagai pengganti auth.uid().
-- =====================================================================

-- 1. DROP fungsi lama dengan signature 2 parameter
DROP FUNCTION IF EXISTS public.update_auth_user_password(UUID, TEXT) CASCADE;

-- 2. CREATE fungsi baru dengan signature 3 parameter (p_caller_id optional)
CREATE OR REPLACE FUNCTION public.update_auth_user_password(
    p_user_id UUID,
    p_new_password TEXT,
    p_caller_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_caller_uid UUID;
BEGIN
    v_caller_uid := COALESCE(auth.uid(), p_caller_id);

    -- Role check: hanya service_role, super_admin, admin, petugas_keuangan,
    -- atau user itu sendiri yang dapat mengubah kata sandi
    IF auth.role() != 'service_role'
       AND (SELECT role FROM public.profiles WHERE id = v_caller_uid) NOT IN ('super_admin', 'admin', 'petugas_keuangan')
       AND v_caller_uid != p_user_id
    THEN
        PERFORM pg_sleep(0.5);
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized');
    END IF;

    -- Update kata sandi di skema auth.users
    UPDATE auth.users
    SET encrypted_password = extensions.crypt(p_new_password, extensions.gen_salt('bf'))
    WHERE id = p_user_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'User tidak ditemukan');
    END IF;

    -- Juga update kata sandi di profiles (untuk sinkronisasi verify_password)
    UPDATE public.profiles
    SET password = extensions.crypt(p_new_password, extensions.gen_salt('bf'))
    WHERE id = p_user_id;

    RETURN jsonb_build_object('success', true);
END;
$$;

-- 3. GRANT permissions secara eksplisit ke role authenticated, anon, dan public
GRANT EXECUTE ON FUNCTION public.update_auth_user_password(UUID, TEXT, UUID) TO authenticated, anon, public;
