-- Migrasi: Perbaikan Kebijakan RLS untuk Operasi Admin Keuangan & Super Admin
-- Tanggal: 2026-06-17
-- Masalah: Tabel audit_logs, students, dan notifications tidak memiliki policy INSERT/UPDATE
--          yang memadai untuk role petugas_keuangan dan admin, menyebabkan error RLS 42501.

-- =====================================================================
-- 1. PERBAIKAN POLICIES TABEL AUDIT_LOGS
-- =====================================================================

-- Hapus policy SELECT lama yang hanya mencakup admin & super_admin
DROP POLICY IF EXISTS "Admin dan Super Admin dapat melihat audit log" ON public.audit_logs;

-- Buat policy SELECT yang lebih inklusif (admin, super_admin, petugas_keuangan)
CREATE POLICY "Admin, Super Admin, dan Keuangan dapat membaca audit log"
    ON public.audit_logs FOR SELECT TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'petugas_keuangan')
        )
    );

-- Tambahkan policy INSERT untuk petugas_keuangan dan admin agar bisa mencatat audit log
CREATE POLICY "Petugas Keuangan dan Admin dapat menambah audit log"
    ON public.audit_logs FOR INSERT TO authenticated WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'petugas_keuangan')
        )
    );

-- =====================================================================
-- 2. PERBAIKAN POLICIES TABEL STUDENTS (UNTUK KOREKSI & REGISTRASI KARTU)
-- =====================================================================

-- Tambahkan policy UPDATE untuk petugas_keuangan dan admin (koreksi saldo, freeze/unfreeze kartu, registrasi NFC)
CREATE POLICY "Petugas Keuangan dan Admin dapat memperbarui data siswa"
    ON public.students FOR UPDATE TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'petugas_keuangan')
        )
    ) WITH CHECK (true);

-- Tambahkan policy INSERT untuk admin (menambah data siswa baru)
CREATE POLICY "Admin dapat menambah data siswa baru"
    ON public.students FOR INSERT TO authenticated WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'petugas_keuangan')
        )
    );

-- =====================================================================
-- 3. PERBAIKAN POLICIES TABEL NOTIFICATIONS (UNTUK KIRIM NOTIFIKASI SISTEM)
-- =====================================================================

-- Tambahkan policy INSERT untuk petugas_keuangan dan admin (mengirim notifikasi koreksi/top-up ke siswa)
CREATE POLICY "Petugas Keuangan dan Admin dapat menambah notifikasi"
    ON public.notifications FOR INSERT TO authenticated WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'petugas_keuangan')
        )
    );

-- =====================================================================
-- 4. PERBAIKAN POLICIES TABEL TRANSACTIONS (UNTUK TOP-UP MANUAL)
-- =====================================================================

-- Tambahkan policy INSERT untuk petugas_keuangan (mencatat transaksi top-up tunai)
CREATE POLICY "Petugas Keuangan dan Admin dapat menambah transaksi"
    ON public.transactions FOR INSERT TO authenticated WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'petugas_keuangan')
        )
    );

-- =====================================================================
-- 5. PERBAIKAN POLICIES TABEL PROFILES (UNTUK MANAJEMEN USER)
-- =====================================================================

-- Tambahkan policy INSERT untuk admin (membuat akun baru via dashboard)
CREATE POLICY "Admin dan Super Admin dapat menambah profil pengguna"
    ON public.profiles FOR INSERT TO authenticated WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
    );

-- Tambahkan policy UPDATE untuk admin (mengubah role, status aktif, password user lain)
CREATE POLICY "Admin dan Super Admin dapat memperbarui profil pengguna"
    ON public.profiles FOR UPDATE TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
    ) WITH CHECK (true);

-- =====================================================================
-- 6. PERBAIKAN POLICIES TABEL CANTEEN_OPERATORS (UNTUK MANAJEMEN KANTIN)
-- =====================================================================

-- Tambahkan policy SELECT yang lebih luas untuk admin
CREATE POLICY "Admin dan Keuangan dapat membaca semua data operator kantin"
    ON public.canteen_operators FOR SELECT TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'petugas_keuangan')
        )
    );

-- =====================================================================
-- 7. PERBAIKAN POLICIES TABEL FINANCE_OFFICERS (UNTUK DETAIL KEUANGAN)
-- =====================================================================

-- Tambahkan policy UPDATE untuk admin
CREATE POLICY "Admin dan Super Admin dapat memperbarui data petugas keuangan"
    ON public.finance_officers FOR UPDATE TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
    ) WITH CHECK (true);

-- Tambahkan policy INSERT untuk admin
CREATE POLICY "Admin dan Super Admin dapat menambah petugas keuangan"
    ON public.finance_officers FOR INSERT TO authenticated WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
    );
