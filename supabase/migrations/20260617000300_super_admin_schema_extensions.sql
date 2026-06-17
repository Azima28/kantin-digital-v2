-- Migrasi: Ekstensi Skema Database untuk Fitur Super Admin Mobile Cockpit
-- Tanggal: 2026-06-17

-- =====================================================================
-- 1. MODIFIKASI TABEL PROFILES & ROLE CONSTRAINT
-- =====================================================================

-- Hapus check constraint peran lama
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_role_check;

-- Tambahkan check constraint baru yang mencakup seluruh role
ALTER TABLE public.profiles ADD CONSTRAINT profiles_role_check 
    CHECK (role IN ('student', 'petugas_kantin', 'parent', 'petugas_keuangan', 'admin', 'super_admin'));

-- Tambahkan kolom password ke profiles jika belum ada untuk menyederhanakan demo/autentikasi lokal
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS password TEXT DEFAULT 'password123';

-- Tambahkan kolom phone_number ke profiles jika belum ada
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone_number TEXT DEFAULT NULL;

-- Tambahkan kolom is_active ke profiles untuk manajemen pemblokiran seluruh akun role
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true NOT NULL;


-- =====================================================================
-- 2. PEMBUATAN TABEL RELASI ORANG TUA - SISWA (PARENT-STUDENTS)
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.parent_students (
    parent_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    student_id UUID REFERENCES public.students(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    PRIMARY KEY (parent_id, student_id)
);

-- Aktifkan Row Level Security (RLS)
ALTER TABLE public.parent_students ENABLE ROW LEVEL SECURITY;

-- Buat Policies RLS untuk parent_students
DROP POLICY IF EXISTS "Semua user terautentikasi dapat membaca data parent_students" ON public.parent_students;
DROP POLICY IF EXISTS "Semua user anon dapat membaca data parent_students" ON public.parent_students;

CREATE POLICY "Semua user terautentikasi dapat membaca data parent_students"
    ON public.parent_students FOR SELECT TO authenticated USING (true);

CREATE POLICY "Semua user anon dapat membaca data parent_students"
    ON public.parent_students FOR SELECT TO anon USING (true);


-- =====================================================================
-- 3. PEMBUATAN TABEL PETUGAS KEUANGAN (FINANCE OFFICERS)
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.finance_officers (
    id UUID REFERENCES public.profiles(id) ON DELETE CASCADE PRIMARY KEY,
    assigned_school TEXT NOT NULL,
    authority_level TEXT NOT NULL CHECK (authority_level IN ('L1', 'L2', 'L3')),
    features TEXT[] DEFAULT '{}'::text[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Aktifkan RLS
ALTER TABLE public.finance_officers ENABLE ROW LEVEL SECURITY;

-- Buat Policies RLS untuk finance_officers
DROP POLICY IF EXISTS "Semua user terautentikasi dapat membaca data petugas keuangan" ON public.finance_officers;
DROP POLICY IF EXISTS "Semua user anon dapat membaca data petugas keuangan" ON public.finance_officers;

CREATE POLICY "Semua user terautentikasi dapat membaca data petugas keuangan"
    ON public.finance_officers FOR SELECT TO authenticated USING (true);

CREATE POLICY "Semua user anon dapat membaca data petugas keuangan"
    ON public.finance_officers FOR SELECT TO anon USING (true);


-- =====================================================================
-- 4. PEMBUATAN TABEL RIWAYAT AUDIT (AUDIT LOGS)
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    actor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    actor_name TEXT NOT NULL,
    action_type TEXT NOT NULL,
    description TEXT NOT NULL,
    target_id UUID,
    old_value JSONB DEFAULT '{}'::jsonb,
    new_value JSONB DEFAULT '{}'::jsonb,
    ip_address TEXT,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Aktifkan RLS
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Buat Policies RLS untuk audit_logs (Hanya Admin, Super Admin, dan Anon Read-Only untuk dashboard)
DROP POLICY IF EXISTS "Admin dan Super Admin dapat melihat audit log" ON public.audit_logs;
DROP POLICY IF EXISTS "Semua user anon dapat membaca data audit log" ON public.audit_logs;

CREATE POLICY "Admin dan Super Admin dapat melihat audit log"
    ON public.audit_logs FOR SELECT TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
    );

CREATE POLICY "Semua user anon dapat membaca data audit log"
    ON public.audit_logs FOR SELECT TO anon USING (true);


-- =====================================================================
-- 5. PEMBUATAN TABEL SETELAN GLOBAL SISTEM (SYSTEM SETTINGS)
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.system_settings (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL,
    updated_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Aktifkan RLS
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

-- Buat Policies RLS untuk system_settings
DROP POLICY IF EXISTS "Semua user terautentikasi dapat membaca data pengaturan sistem" ON public.system_settings;
DROP POLICY IF EXISTS "Hanya admin dan super_admin yang dapat memperbarui pengaturan sistem" ON public.system_settings;
DROP POLICY IF EXISTS "Semua user anon dapat membaca data pengaturan sistem" ON public.system_settings;

CREATE POLICY "Semua user terautentikasi dapat membaca data pengaturan sistem"
    ON public.system_settings FOR SELECT TO authenticated USING (true);

CREATE POLICY "Hanya admin dan super_admin yang dapat memperbarui pengaturan sistem"
    ON public.system_settings FOR ALL TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
    );

CREATE POLICY "Semua user anon dapat membaca data pengaturan sistem"
    ON public.system_settings FOR SELECT TO anon USING (true);

-- Isi Setelan Global Utama
INSERT INTO public.system_settings (key, value)
VALUES 
    ('maintenance_mode', 'false'::jsonb),
    ('midtrans_config', '{"mode": "sandbox", "client_key": "SB-Mid-client-1234567890", "is_active": true}'::jsonb),
    ('canteen_fee', '2.0'::jsonb)
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;


-- =====================================================================
-- 6. PEMBARUAN TRIGGER HANDLE NEW USER UNTUK ROLE BARU
-- =====================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_role TEXT;
    v_name TEXT;
BEGIN
    v_role := COALESCE(new.raw_user_meta_data->>'role', 'student');
    v_name := COALESCE(new.raw_user_meta_data->>'full_name', 'User Baru');

    -- Memasukkan data ke tabel public.profiles
    INSERT INTO public.profiles (id, email, full_name, role)
    VALUES (new.id, new.email, v_name, v_role);

    -- Memasukkan data ke tabel turunan berdasarkan role
    IF v_role = 'student' THEN
        INSERT INTO public.students (id, class, balance, is_active)
        VALUES (new.id, COALESCE(new.raw_user_meta_data->>'class', 'Belum Diisi'), 0.00, true);
    ELSIF v_role = 'petugas_kantin' THEN
        INSERT INTO public.canteen_operators (id, canteen_name, balance_earned)
        VALUES (new.id, COALESCE(new.raw_user_meta_data->>'canteen_name', 'Stan Kantin'), 0.00);
    ELSIF v_role = 'petugas_keuangan' THEN
        INSERT INTO public.finance_officers (id, assigned_school, authority_level, features)
        VALUES (new.id, COALESCE(new.raw_user_meta_data->>'assigned_school', 'SMP Terpadu'), 'L1', ARRAY['topup', 'withdrawal', 'correction']);
    END IF;

    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- =====================================================================
-- 7. PENYEDIAAN DATA MOCKUP (MOCK DATA)
-- =====================================================================

-- Enable pgcrypto for password hashing
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Mock Akun Orang Tua (Salim Subarjo) ke auth.users
INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role, created_at, updated_at)
VALUES (
    '6a4e32d5-45c1-4b10-86d9-f5d60b571111'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'salim.subarjo@example.com',
    crypt('parent123', gen_salt('bf')),
    now(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"full_name": "Salim Subarjo", "role": "parent"}'::jsonb,
    'authenticated',
    'authenticated',
    now(),
    now()
) ON CONFLICT (id) DO NOTHING;

-- Mock Akun Petugas Keuangan (Budi Hartono) ke auth.users
INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role, created_at, updated_at)
VALUES (
    'dbe4f12d-a2f2-45e0-94e8-8888bdf12345'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'budi.finance@f.com',
    crypt('budi123', gen_salt('bf')),
    now(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"full_name": "Budi Hartono", "role": "petugas_keuangan", "assigned_school": "SMP Terpadu"}'::jsonb,
    'authenticated',
    'authenticated',
    now(),
    now()
) ON CONFLICT (id) DO NOTHING;

-- Mock Akun Super Admin ke auth.users
INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role, created_at, updated_at)
VALUES (
    '88888888-8888-8888-8888-888888888888'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'superadmin@kantindigital.com',
    crypt('admin123', gen_salt('bf')),
    now(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"full_name": "Super Admin", "role": "super_admin"}'::jsonb,
    'authenticated',
    'authenticated',
    now(),
    now()
) ON CONFLICT (id) DO NOTHING;

-- Update metadata tambahan di public.profiles yang tidak ditangani trigger default
UPDATE public.profiles
SET username = 'salim_s', password = 'parent123', phone_number = '+62 812 3456 7890'
WHERE id = '6a4e32d5-45c1-4b10-86d9-f5d60b571111'::uuid;

UPDATE public.profiles
SET username = 'budi_fin', password = 'budi123', phone_number = '+62 857 1111 2222'
WHERE id = 'dbe4f12d-a2f2-45e0-94e8-8888bdf12345'::uuid;

UPDATE public.profiles
SET username = 'superadmin', password = 'admin123', phone_number = '+62 800 0000 0000'
WHERE id = '88888888-8888-8888-8888-888888888888'::uuid;

-- Link Orang Tua ke Murid Ahmad Subarjo (student_id: 03525ad9-d9e3-4f55-8ee6-7ff5b06d2025)
INSERT INTO public.parent_students (parent_id, student_id)
VALUES (
    '6a4e32d5-45c1-4b10-86d9-f5d60b571111'::uuid,
    '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025'::uuid
) ON CONFLICT DO NOTHING;

-- Pastikan detail petugas keuangan terisi dengan benar di finance_officers
INSERT INTO public.finance_officers (id, assigned_school, authority_level, features)
VALUES (
    'dbe4f12d-a2f2-45e0-94e8-8888bdf12345'::uuid,
    'SMP Terpadu',
    'L1',
    ARRAY['topup', 'withdrawal', 'correction']
) 
ON CONFLICT (id) DO UPDATE SET
    assigned_school = EXCLUDED.assigned_school,
    authority_level = EXCLUDED.authority_level,
    features = EXCLUDED.features;


-- Mock Awal Data Log Audit
INSERT INTO public.audit_logs (actor_name, action_type, description, old_value, new_value, ip_address, user_agent)
VALUES
    (
        'Budi Hartono', 
        'KOREKSI_SALDO', 
        'Koreksi saldo siswa Anita Rahman (ID: 10293)', 
        '{"balance": 50000}'::jsonb, 
        '{"balance": 150000}'::jsonb, 
        '192.168.1.15', 
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)'
    ),
    (
        'Siti Aminah', 
        'REGISTRASI_KARTU', 
        'Pendaftaran kartu NFC baru UID: A4B9C2D8 untuk murid Rina (10A)', 
        '{}'::jsonb, 
        '{"rfid_uid": "A4B9C2D8", "student": "Rina"}'::jsonb, 
        '192.168.1.20', 
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)'
    ),
    (
        'Super Admin', 
        'SETELAN_SISTEM', 
        'Mengubah persentase biaya transaksi kantin (Fee) dari 2.0% ke 2.5%', 
        '{"canteen_fee": 2.0}'::jsonb, 
        '{"canteen_fee": 2.5}'::jsonb, 
        '10.0.0.5', 
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)'
    );
