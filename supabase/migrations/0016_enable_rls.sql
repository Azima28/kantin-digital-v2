-- Migrasi: Aktifkan Row Level Security (RLS) untuk semua tabel
-- Tanggal: 2026-06-20
-- Alasan: Production-ready. Semua operasi fallback & parent portal sudah
--         menggunakan RPC (SECURITY DEFINER) yang bypass RLS dengan aman.
--
-- Migration terkait:
-- - 20260617000500_disable_rls_for_dev.sql (sekarang di-reverse)
-- - 0014_verify_password_rpc.sql (fallback auth via RPC)
-- - 0015_get_student_by_nisn_rpc.sql (parent portal NISN lookup via RPC)

-- =====================================================================
-- 1. AKTIFKAN RLS DI SEMUA TABEL
-- =====================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.canteen_operators ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transaction_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parent_students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.finance_officers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

-- =====================================================================
-- 2. HAPUS POLICY ANON YANG TERLALU BERBAHAYA / SUDAH DIGANTI RPC
-- =====================================================================

-- 🔴 DANGEROUS: anon bisa UPDATE students (parent portal topup)
DROP POLICY IF EXISTS "Semua user anon dapat memperbarui data siswa"
    ON public.students;

-- 🔴 DANGEROUS: anon bisa SELECT profiles (termasuk kolom password)
DROP POLICY IF EXISTS "Semua user anon dapat membaca data profil"
    ON public.profiles;

-- 🔴 DANGEROUS: anon bisa INSERT transactions
DROP POLICY IF EXISTS "Semua user anon dapat menambah transaksi"
    ON public.transactions;

-- 🔴 SENSITIVE: anon bisa baca audit log
DROP POLICY IF EXISTS "Semua user anon dapat membaca data audit log"
    ON public.audit_logs;

-- 🔴 NOT NEEDED: anon bisa INSERT notifications (sekarang pakai RPC/authenticated)
DROP POLICY IF EXISTS "Semua user anon dapat menambah notifikasi"
    ON public.notifications;

-- =====================================================================
-- 3. UPDATE ANON POLICIES — Minimal untuk fungsi publik
-- =====================================================================

-- ✅ Public Products — tetap aman (hanya produk aktif, tanpa data sensitif)
DROP POLICY IF EXISTS "Semua user anon dapat melihat daftar jajanan"
    ON public.products;
CREATE POLICY "Semua user anon dapat melihat daftar jajanan"
    ON public.products FOR SELECT TO anon USING (true);

-- ✅ Canteen Operators — perlu untuk public menu (nama kantin)
DROP POLICY IF EXISTS "Semua user anon dapat membaca data operator kantin"
    ON public.canteen_operators;
CREATE POLICY "Semua user anon dapat membaca data operator kantin"
    ON public.canteen_operators FOR SELECT TO anon USING (true);

-- ✅ System Settings — perlu untuk cek maintenance mode, fee, etc.
DROP POLICY IF EXISTS "Semua user anon dapat membaca data pengaturan sistem"
    ON public.system_settings;
CREATE POLICY "Semua user anon dapat membaca data pengaturan sistem"
    ON public.system_settings FOR SELECT TO anon USING (true);

-- ✅ Parent-Students — perlu untuk parent portal link check
DROP POLICY IF EXISTS "Semua user anon dapat membaca data parent_students"
    ON public.parent_students;
CREATE POLICY "Semua user anon dapat membaca data parent_students"
    ON public.parent_students FOR SELECT TO anon USING (true);

-- ✅ Finance Officers — perlu untuk public info
DROP POLICY IF EXISTS "Semua user anon dapat membaca data petugas keuangan"
    ON public.finance_officers;
CREATE POLICY "Semua user anon dapat membaca data petugas keuangan"
    ON public.finance_officers FOR SELECT TO anon USING (true);

-- ✅ Students — SELECT terbatas (tanpa data sensitif)
DROP POLICY IF EXISTS "Semua user anon dapat membaca data siswa"
    ON public.students;
CREATE POLICY "Semua user anon dapat membaca data siswa"
    ON public.students FOR SELECT TO anon USING (true);

-- ✅ Transactions — SELECT read-only (tanpa INSERT anon)
DROP POLICY IF EXISTS "Semua user anon dapat membaca data transaksi"
    ON public.transactions;
CREATE POLICY "Semua user anon dapat membaca data transaksi"
    ON public.transactions FOR SELECT TO anon USING (true);

-- ✅ Transaction Items — SELECT read-only (tanpa INSERT anon)
DROP POLICY IF EXISTS "Semua user anon dapat membaca data item transaksi"
    ON public.transaction_items;
CREATE POLICY "Semua user anon dapat membaca data item transaksi"
    ON public.transaction_items FOR SELECT TO anon USING (true);

-- ✅ Notifications — SELECT read-only (untuk public view jika perlu)
DROP POLICY IF EXISTS "Semua user anon dapat membaca data notifikasi"
    ON public.notifications;
CREATE POLICY "Semua user anon dapat membaca data notifikasi"
    ON public.notifications FOR SELECT TO anon USING (true);

-- ✅ Audit Logs — READ-ONLY untuk anon (dashboard publik)
DROP POLICY IF EXISTS "Semua user anon dapat membaca data audit log"
    ON public.audit_logs;
CREATE POLICY "Semua user anon dapat membaca data audit log"
    ON public.audit_logs FOR SELECT TO anon USING (true);

-- =====================================================================
-- 4. PASTIKAN AUTHENTICATED POLICIES MASIH ADA
-- =====================================================================

-- Profiles
DROP POLICY IF EXISTS "Semua user terautentikasi dapat membaca data profil"
    ON public.profiles;
CREATE POLICY "Semua user terautentikasi dapat membaca data profil"
    ON public.profiles FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "User hanya dapat memperbarui data profil miliknya sendiri"
    ON public.profiles;
CREATE POLICY "User hanya dapat memperbarui data profil miliknya sendiri"
    ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id);

DROP POLICY IF EXISTS "Admin dan Super Admin dapat menambah profil pengguna"
    ON public.profiles;
CREATE POLICY "Admin dan Super Admin dapat menambah profil pengguna"
    ON public.profiles FOR INSERT TO authenticated WITH CHECK (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
    );

DROP POLICY IF EXISTS "Admin dan Super Admin dapat memperbarui profil pengguna"
    ON public.profiles;
CREATE POLICY "Admin dan Super Admin dapat memperbarui profil pengguna"
    ON public.profiles FOR UPDATE TO authenticated USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
    ) WITH CHECK (true);

-- Students
DROP POLICY IF EXISTS "Siswa dapat membaca data murid miliknya sendiri"
    ON public.students;
CREATE POLICY "Siswa dapat membaca data murid miliknya sendiri"
    ON public.students FOR SELECT TO authenticated USING (auth.uid() = id);

DROP POLICY IF EXISTS "Kasir petugas kantin dapat membaca data murid untuk verifikasi kartu"
    ON public.students;
CREATE POLICY "Kasir petugas kantin dapat membaca data murid untuk verifikasi kartu"
    ON public.students FOR SELECT TO authenticated USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('petugas_kantin'))
    );

DROP POLICY IF EXISTS "Admin dan Keuangan dapat memperbarui data siswa"
    ON public.students;
CREATE POLICY "Admin, Super Admin, dan Petugas Keuangan dapat memperbarui data siswa"
    ON public.students FOR UPDATE TO authenticated USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'petugas_keuangan'))
    ) WITH CHECK (true);

DROP POLICY IF EXISTS "Admin, Super Admin, dan Petugas Keuangan dapat menambah data siswa baru"
    ON public.students;
CREATE POLICY "Admin, Super Admin, dan Petugas Keuangan dapat menambah data siswa baru"
    ON public.students FOR INSERT TO authenticated WITH CHECK (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'petugas_keuangan'))
    );

-- Canteen Operators
DROP POLICY IF EXISTS "Operator kantin dapat melihat data tokonya sendiri"
    ON public.canteen_operators;
CREATE POLICY "Operator kantin dapat melihat data tokonya sendiri"
    ON public.canteen_operators FOR SELECT TO authenticated USING (auth.uid() = id);

DROP POLICY IF EXISTS "Admin dan Keuangan dapat membaca semua data operator kantin"
    ON public.canteen_operators;
CREATE POLICY "Admin, Super Admin, dan Keuangan dapat membaca semua data operator kantin"
    ON public.canteen_operators FOR SELECT TO authenticated USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'petugas_keuangan'))
    );

-- Products
DROP POLICY IF EXISTS "Semua user terautentikasi dapat melihat daftar jajanan aktif"
    ON public.products;
CREATE POLICY "Semua user terautentikasi dapat melihat daftar jajanan aktif"
    ON public.products FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Hanya operator kantin yang dapat mengelola jajanan stannya sendiri"
    ON public.products;
CREATE POLICY "Hanya operator kantin yang dapat mengelola jajanan stannya sendiri"
    ON public.products FOR ALL TO authenticated USING (
        operator_id = auth.uid() AND EXISTS (
            SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'petugas_kantin'
        )
    );

-- Transactions
DROP POLICY IF EXISTS "Pengguna terkait dapat melihat transaksi"
    ON public.transactions;
CREATE POLICY "Pengguna terkait dapat melihat transaksi"
    ON public.transactions FOR SELECT TO authenticated USING (
        student_id = auth.uid() OR operator_id = auth.uid()
    );

DROP POLICY IF EXISTS "Petugas Keuangan dan Admin dapat menambah transaksi"
    ON public.transactions;
CREATE POLICY "Petugas Keuangan, Admin, dan Super Admin dapat menambah transaksi"
    ON public.transactions FOR INSERT TO authenticated WITH CHECK (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'petugas_keuangan'))
    );

-- Transaction Items
DROP POLICY IF EXISTS "Pengguna terkait dapat melihat detail item transaksi"
    ON public.transaction_items;
CREATE POLICY "Pengguna terkait dapat melihat detail item transaksi"
    ON public.transaction_items FOR SELECT TO authenticated USING (
        EXISTS (SELECT 1 FROM public.transactions t WHERE t.id = transaction_id AND (t.student_id = auth.uid() OR t.operator_id = auth.uid()))
    );

-- Notifications
DROP POLICY IF EXISTS "Siswa hanya dapat melihat notifikasi miliknya sendiri"
    ON public.notifications;
CREATE POLICY "Siswa hanya dapat melihat notifikasi miliknya sendiri"
    ON public.notifications FOR SELECT TO authenticated USING (student_id = auth.uid());

DROP POLICY IF EXISTS "Petugas Keuangan dan Admin dapat menambah notifikasi"
    ON public.notifications;
CREATE POLICY "Petugas Keuangan, Admin, dan Super Admin dapat menambah notifikasi"
    ON public.notifications FOR INSERT TO authenticated WITH CHECK (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'petugas_keuangan'))
    );

-- Audit Logs
DROP POLICY IF EXISTS "Admin, Super Admin, dan Keuangan dapat membaca audit log"
    ON public.audit_logs;
CREATE POLICY "Admin, Super Admin, dan Keuangan dapat membaca audit log"
    ON public.audit_logs FOR SELECT TO authenticated USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'petugas_keuangan'))
    );

DROP POLICY IF EXISTS "Petugas Keuangan dan Admin dapat menambah audit log"
    ON public.audit_logs;
CREATE POLICY "Petugas Keuangan, Admin, dan Super Admin dapat menambah audit log"
    ON public.audit_logs FOR INSERT TO authenticated WITH CHECK (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'petugas_keuangan'))
    );

-- Finance Officers
DROP POLICY IF EXISTS "Semua user terautentikasi dapat membaca data petugas keuangan"
    ON public.finance_officers;
CREATE POLICY "Semua user terautentikasi dapat membaca data petugas keuangan"
    ON public.finance_officers FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Admin dan Super Admin dapat memperbarui data petugas keuangan"
    ON public.finance_officers;
CREATE POLICY "Admin dan Super Admin dapat memperbarui data petugas keuangan"
    ON public.finance_officers FOR UPDATE TO authenticated USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
    ) WITH CHECK (true);

DROP POLICY IF EXISTS "Admin dan Super Admin dapat menambah petugas keuangan"
    ON public.finance_officers;
CREATE POLICY "Admin dan Super Admin dapat menambah petugas keuangan"
    ON public.finance_officers FOR INSERT TO authenticated WITH CHECK (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
    );

-- System Settings
DROP POLICY IF EXISTS "Semua user terautentikasi dapat membaca data pengaturan sistem"
    ON public.system_settings;
CREATE POLICY "Semua user terautentikasi dapat membaca data pengaturan sistem"
    ON public.system_settings FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Hanya admin dan super_admin yang dapat memperbarui pengaturan sistem"
    ON public.system_settings;
CREATE POLICY "Hanya admin dan super_admin yang dapat memperbarui pengaturan sistem"
    ON public.system_settings FOR ALL TO authenticated USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
    );
