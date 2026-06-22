-- Migrasi: RPC untuk verifikasi password (menggantikan SELECT langsung ke profiles.password)
-- Alasan: Saat RLS aktif, anon tidak bisa SELECT profiles. Tapi fallback auth
--          tetap perlu verifikasi password sebelum login. RPC ini pake SECURITY DEFINER
--          sehingga bisa bypass RLS untuk tujuan spesifik ini.

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
    -- Cari profile by email
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
        'password_valid', (p.password = p_password)
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
