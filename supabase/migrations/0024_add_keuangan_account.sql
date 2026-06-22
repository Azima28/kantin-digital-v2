-- Migration: Tambah akun keuangan/keuangan123 untuk kemudahan testing
-- Tanggal: 2026-06-22

-- Pastikan pgcrypto terinstall (untuk gen_salt)
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA extensions;

-- Buat akun baru di auth.users
INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role, created_at, updated_at)
VALUES (
    'f1e4f12d-a2f2-45e0-94e8-9999cdf99999'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'keuangan@sekolah.sch.id',
    extensions.crypt('keuangan123', extensions.gen_salt('bf')),
    now(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"full_name": "Petugas Keuangan", "role": "petugas_keuangan", "assigned_school": "SMP Terpadu"}'::jsonb,
    'authenticated',
    'authenticated',
    now(),
    now()
) ON CONFLICT (id) DO NOTHING;

-- Set username & password di public.profiles
UPDATE public.profiles
SET username = 'keuangan', password = 'keuangan123', phone_number = '+62 857 1111 3333'
WHERE id = 'f1e4f12d-a2f2-45e0-94e8-9999cdf99999'::uuid;

-- Insert ke finance_officers
INSERT INTO public.finance_officers (id, assigned_school, authority_level, features)
VALUES (
    'f1e4f12d-a2f2-45e0-94e8-9999cdf99999'::uuid,
    'SMP Terpadu',
    'L1',
    ARRAY['topup', 'withdrawal', 'correction']
) 
ON CONFLICT (id) DO UPDATE SET
    assigned_school = EXCLUDED.assigned_school,
    authority_level = EXCLUDED.authority_level,
    features = EXCLUDED.features;
