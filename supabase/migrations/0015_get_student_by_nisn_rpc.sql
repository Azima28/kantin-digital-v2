-- Migrasi: RPC untuk mencari siswa berdasarkan NISN (parent portal)
-- Alasan: Menggantikan anon SELECT langsung ke profiles.

CREATE OR REPLACE FUNCTION public.get_student_by_nisn(
    p_nisn TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'id', p.id,
        'full_name', p.full_name,
        'role', p.role
    ) INTO v_result
    FROM public.profiles p
    WHERE p.nisn = p_nisn AND p.role = 'student'
    LIMIT 1;

    IF v_result IS NULL THEN
        RETURN jsonb_build_object('found', false);
    END IF;

    RETURN v_result;
END;
$$;
