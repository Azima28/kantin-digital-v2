-- =====================================================================
-- Migration: Fix create_user_session Search Path and pgcrypto
-- Tanggal: 2026-08-13
-- Tujuan: Memastikan extension pgcrypto terpasang dan search_path
--         memasukkan 'public' dan 'extensions' agar RPC create_user_session
--         tidak gagal saat dipanggil dari REST API Supabase.
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION public.create_user_session(
    p_email TEXT,
    p_password TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
    v_profile JSONB;
    v_token UUID;
    v_token_hash TEXT;
    v_expires_at TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Verifikasi password menggunakan verify_password RPC
    v_profile := public.verify_password(p_email, p_password);

    IF v_profile IS NULL OR (v_profile->>'found')::BOOLEAN = false OR (v_profile->>'password_valid')::BOOLEAN = false THEN
        RETURN jsonb_build_object('success', false, 'error', 'Email/Username/NISN atau kata sandi salah.');
    END IF;

    -- Batalkan sesi lama milik user ini
    DELETE FROM public.user_sessions WHERE user_id = (v_profile->>'id')::UUID;

    -- Buat token UUID baru & hash SHA-256
    v_token := gen_random_uuid();
    v_token_hash := encode(digest(v_token::TEXT, 'sha256'), 'hex');
    v_expires_at := now() + INTERVAL '12 hours';

    -- Simpan hash ke database
    INSERT INTO public.user_sessions (user_id, token_hash, expires_at)
    VALUES ((v_profile->>'id')::UUID, v_token_hash, v_expires_at);

    RETURN jsonb_build_object(
        'success', true,
        'session_token', v_token::TEXT,
        'profile', v_profile
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_user_session(TEXT, TEXT) TO authenticated, anon, public;
