-- Migrasi: Perbaikan akun autentikasi siswa (Ahmad Subarjo)
-- Tanggal: 2026-06-17
-- Masalah: Siswa (NISN: 20260012) tidak memiliki entry di auth.users,
--          sehingga login via Supabase Auth selalu gagal dengan
--          "Invalid login credentials". Profile siswa ada di public.profiles
--          tetapi tidak ada akun auth yang sesuai.
-- Solusi: Membuat/memperbarui entry auth.users untuk siswa dengan
--         password yang benar (password123).

-- =====================================================================
-- 1. UPDATE PASSWORD JIKA auth.users SUDAH ADA (by email atau id)
-- =====================================================================
UPDATE auth.users
SET encrypted_password = extensions.crypt('password123', extensions.gen_salt('bf')),
    email = '20260012@sekolah.sch.id',
    updated_at = now()
WHERE email = '20260012@sekolah.sch.id'
   OR id = '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025'::uuid;

-- =====================================================================
-- 2. INSERT auth.users JIKA BELUM ADA
-- =====================================================================
INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role, created_at, updated_at)
SELECT
    '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    '20260012@sekolah.sch.id',
    extensions.crypt('password123', extensions.gen_salt('bf')),
    now(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"full_name": "Ahmad Subarjo", "role": "student"}'::jsonb,
    'authenticated',
    'authenticated',
    now(),
    now()
WHERE NOT EXISTS (
    SELECT 1 FROM auth.users
    WHERE email = '20260012@sekolah.sch.id'
       OR id = '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025'::uuid
);

-- =====================================================================
-- 3. PASTIKAN PROFILE SISWA LENGKAP & SESUAI
-- =====================================================================
-- Pastikan profile ada (jika belum, insert; jika sudah, update)
INSERT INTO public.profiles (id, email, full_name, role, username, nisn, password, is_active)
VALUES (
    '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025'::uuid,
    '20260012@sekolah.sch.id',
    'Ahmad Subarjo',
    'student',
    'ahmad',
    '20260012',
    'password123',
    true
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = EXCLUDED.full_name,
    role = EXCLUDED.role,
    username = EXCLUDED.username,
    nisn = EXCLUDED.nisn,
    password = EXCLUDED.password,
    is_active = EXCLUDED.is_active;

-- =====================================================================
-- 4. PASTIKAN DATA STUDENTS ADA
-- =====================================================================
INSERT INTO public.students (id, class, balance, is_active)
VALUES (
    '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025'::uuid,
    '8-B',
    50000.00,
    true
)
ON CONFLICT (id) DO UPDATE SET
    is_active = EXCLUDED.is_active;
