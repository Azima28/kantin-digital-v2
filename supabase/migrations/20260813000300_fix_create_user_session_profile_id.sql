-- =====================================================================
-- Migration: Fix create_user_session User ID Extraction
-- Tanggal: 2026-08-13
-- Tujuan: Mengakses field 'profile' -> 'id' secara benar dari hasil
--         verify_password RPC agar tidak null dan tidak 400 Bad Request.
-- =====================================================================

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
    v_res JSONB;
    v_profile JSONB;
    v_user_id UUID;
    v_token UUID;
    v_token_hash TEXT;
    v_expires_at TIMESTAMP WITH TIME ZONE;
BEGIN
    v_res := public.verify_password(p_email, p_password);

    IF v_res IS NULL OR (v_res->>'found')::BOOLEAN = false OR (v_res->>'password_valid')::BOOLEAN = false THEN
        RETURN jsonb_build_object('success', false, 'error', 'Email/Username/NISN atau kata sandi salah.');
    END IF;

    -- verify_password mengembalikan {found: true, password_valid: true, profile: {...}}
    IF v_res->'profile' IS NOT NULL AND jsonb_typeof(v_res->'profile') = 'object' THEN
        v_profile := v_res->'profile';
    ELSE
        v_profile := v_res;
    END IF;

    v_user_id := (v_profile->>'id')::UUID;

    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'User ID tidak ditemukan.');
    END IF;

    -- Batalkan sesi lama milik user ini
    DELETE FROM public.user_sessions WHERE user_id = v_user_id;

    -- Buat token UUID baru & hash SHA-256
    v_token := gen_random_uuid();
    v_token_hash := encode(digest(v_token::TEXT, 'sha256'), 'hex');
    v_expires_at := now() + INTERVAL '12 hours';

    -- Simpan hash ke database
    INSERT INTO public.user_sessions (user_id, token_hash, expires_at)
    VALUES (v_user_id, v_token_hash, v_expires_at);

    RETURN jsonb_build_object(
        'success', true,
        'session_token', v_token::TEXT,
        'profile', v_profile
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_user_session(TEXT, TEXT) TO authenticated, anon, public;
