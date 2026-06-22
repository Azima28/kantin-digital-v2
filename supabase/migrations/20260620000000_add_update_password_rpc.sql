-- Migrasi: Add update_auth_user_password RPC function
-- Tanggal: 2026-06-20
-- Fungsi ini menggunakan SECURITY DEFINER untuk mengupdate password auth.users

CREATE OR REPLACE FUNCTION public.update_auth_user_password(
  p_user_id UUID,
  p_new_password TEXT
) RETURNS JSONB
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Update password directly in auth schema
  UPDATE auth.users
  SET encrypted_password = crypt(p_new_password, gen_salt('bf'))
  WHERE id = p_user_id;

  RETURN jsonb_build_object('success', true);
END;
$$;
