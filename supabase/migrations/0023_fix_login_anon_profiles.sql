-- Migration 0023: Fix login broken by 0016 RLS tightening
-- Tanggal: 2026-06-20
-- Alasan: Migrasi 0016_enable_rls.sql (line 35) drop anon SELECT dari profiles,
--         sehingga login siswa/petugas/kasir gagal karena email resolution
--         di auth_service.dart SELECT profiles sebagai anon → ditolak RLS.
--
-- Fix: RPC get_email_for_login + resolve_parent_login
--      Update auth_service.dart untuk tidak SELECT profiles sebagai anon.
--
-- Migration terkait:
-- - 0016_enable_rls.sql (penyebab — drop anon profiles SELECT)
-- - 0022_rate_limiting_and_error_handling.sql (verify_password terakhir)

-- =====================================================================
-- 1. RPC: get_email_for_login
--    Mengembalikan email terdaftar berdasarkan NISN atau username.
--    SECURITY DEFINER — bypasses RLS restrictions for anon users.
--    Hanya return email + id + role — tidak expose data sensitif.
-- =====================================================================
CREATE OR REPLACE FUNCTION public.get_email_for_login(p_input TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_profile RECORD;
BEGIN
    -- Search by NISN, username, or email
    SELECT id, email, role
    INTO v_profile
    FROM public.profiles
    WHERE nisn = p_input
       OR username = p_input
       OR email = p_input
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('found', false);
    END IF;

    RETURN jsonb_build_object(
        'found', true,
        'email', v_profile.email,
        'role', v_profile.role,
        'id', v_profile.id
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_email_for_login TO anon, public;

-- =====================================================================
-- 2. RPC: resolve_parent_login
--    Menerima NISN siswa, mencari parent yang terhubung,
--    mengembalikan info login parent (email, id, role).
--    SECURITY DEFINER — bypasses RLS.
-- =====================================================================
CREATE OR REPLACE FUNCTION public.resolve_parent_login(p_student_nisn TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_student RECORD;
    v_link RECORD;
    v_parent RECORD;
BEGIN
    -- Step 1: Find student by NISN
    SELECT id, nisn, name
    INTO v_student
    FROM public.profiles
    WHERE nisn = p_student_nisn AND role = 'student';

    IF NOT FOUND THEN
        RETURN jsonb_build_object('found', false, 'error', 'NISN Anak tidak terdaftar.');
    END IF;

    -- Step 2: Find parent link
    SELECT parent_id
    INTO v_link
    FROM public.parent_students
    WHERE student_id = v_student.id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('found', false, 'error', 'Akun Orang Tua belum dikaitkan dengan siswa ini.');
    END IF;

    -- Step 3: Get parent profile
    SELECT id, email, role
    INTO v_parent
    FROM public.profiles
    WHERE id = v_link.parent_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('found', false, 'error', 'Profil Orang Tua tidak ditemukan.');
    END IF;

    RETURN jsonb_build_object(
        'found', true,
        'email', v_parent.email,
        'role', v_parent.role,
        'id', v_parent.id,
        'student_id', v_student.id
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.resolve_parent_login TO anon, public;

-- =====================================================================
-- 3. Verify existing GRANT for verify_password (re-assert for safety)
-- =====================================================================
GRANT EXECUTE ON FUNCTION public.verify_password TO anon, public;

-- =====================================================================
-- 4. Verify: test queries (uncomment to test)
-- =====================================================================
-- SELECT public.get_email_for_login('1234567890');  -- by NISN
-- SELECT public.get_email_for_login('siswa_user');   -- by username
-- SELECT public.get_email_for_login('siswa@email.com'); -- by email
-- SELECT public.get_email_for_login('nonexistent');  -- not found
-- SELECT public.resolve_parent_login('1234567890');  -- parent by student NISN
