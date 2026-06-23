-- Fix resolve_parent_login RPC: column "name" tidak ada di profiles, yang ada adalah "full_name"
-- Error: column "name" does not exist saat orang tua login

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
    SELECT id, nisn, full_name
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
