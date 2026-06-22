-- Migrasi 0021: Narrow RLS policies
-- Tanggal: 2026-06-20
-- Alasan: Production hardening — hapus anon SELECT dari tabel sensitif.
--         Tambah granular authenticated-user policies.
--         Anon SELECT hanya dipertahankan untuk products, system_settings, canteen_operators.
--
-- Migration terkait:
-- - 0016_enable_rls.sql (sumber policy anon SELECT yang akan dihapus)
-- - 20260617000400_fix_rls_policies_keuangan.sql (memperbaiki policy keuangan)

-- =====================================================================
-- 1. HAPUS ANON SELECT POLICIES DARI TABEL SENSITIF
-- =====================================================================
-- Policy names berikut dibuat di 0016_enable_rls.sql bagian 3

DROP POLICY IF EXISTS "Semua user anon dapat membaca data audit log"
    ON public.audit_logs;
DROP POLICY IF EXISTS "Semua user anon dapat membaca data transaksi"
    ON public.transactions;
DROP POLICY IF EXISTS "Semua user anon dapat membaca data item transaksi"
    ON public.transaction_items;
DROP POLICY IF EXISTS "Semua user anon dapat membaca data notifikasi"
    ON public.notifications;
DROP POLICY IF EXISTS "Semua user anon dapat membaca data parent_students"
    ON public.parent_students;
DROP POLICY IF EXISTS "Semua user anon dapat membaca data siswa"
    ON public.students;
DROP POLICY IF EXISTS "Semua user anon dapat membaca data petugas keuangan"
    ON public.finance_officers;

-- =====================================================================
-- 2. PERTAHANKAN ANON SELECT UNTUK DATA PUBLIK ESENSIAL
-- =====================================================================

-- Products: untuk tampilan menu publik
DROP POLICY IF EXISTS "Allow anon read products" ON public.products;
CREATE POLICY "Allow anon read products" ON public.products
    FOR SELECT TO anon USING (true);

-- System settings: untuk konfigurasi publik (maintenance mode, fee, dll.)
DROP POLICY IF EXISTS "Allow anon read system_settings" ON public.system_settings;
CREATE POLICY "Allow anon read system_settings" ON public.system_settings
    FOR SELECT TO anon USING (true);

-- Canteen operators: info terbatas untuk publik (nama stan — tanpa balance_earned!)
DROP POLICY IF EXISTS "Allow anon read canteen_operators" ON public.canteen_operators;
CREATE POLICY "Allow anon read canteen_operators" ON public.canteen_operators
    FOR SELECT TO anon USING (true);

-- =====================================================================
-- 3. TAMBAHKAN AUTHENTICATED POLICIES YANG GRANULAR
-- =====================================================================

-- Students: semua authenticated user dapat membaca data siswa
-- (melengkapi policy self-access dan petugas_kantin yang sudah ada)
CREATE POLICY "Allow authenticated read students" ON public.students
    FOR SELECT TO authenticated USING (true);

-- Audit logs: hanya admin/keuangan yang dapat membaca
CREATE POLICY "Allow admin read audit_logs" ON public.audit_logs
    FOR SELECT TO authenticated
    USING (
        (SELECT role FROM public.profiles WHERE id = auth.uid())
        IN ('super_admin', 'admin', 'petugas_keuangan')
    );

-- Transactions: siswa lihat transaksi sendiri, operator lihat transaksi stan,
-- admin/keuangan lihat semua
CREATE POLICY "Allow read transactions" ON public.transactions
    FOR SELECT TO authenticated
    USING (
        student_id = auth.uid()
        OR operator_id = auth.uid()
        OR (SELECT role FROM public.profiles WHERE id = auth.uid())
           IN ('super_admin', 'admin', 'petugas_keuangan')
    );

-- Transaction items: kebijakan yang sama dengan transactions (via EXISTS)
CREATE POLICY "Allow read transaction_items" ON public.transaction_items
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.transactions t
            WHERE t.id = transaction_id
            AND (
                t.student_id = auth.uid()
                OR t.operator_id = auth.uid()
                OR (SELECT role FROM public.profiles WHERE id = auth.uid())
                   IN ('super_admin', 'admin', 'petugas_keuangan')
            )
        )
    );

-- Notifications: siswa hanya melihat notifikasi miliknya sendiri
CREATE POLICY "Allow read own notifications" ON public.notifications
    FOR SELECT TO authenticated
    USING (student_id = auth.uid());

-- Parent students: parent melihat linkage sendiri
CREATE POLICY "Allow read own parent_students" ON public.parent_students
    FOR SELECT TO authenticated
    USING (parent_id = auth.uid());

-- Finance officers: hanya admin/keuangan yang dapat melihat data petugas keuangan
-- (hapus policy lama yang terlalu permisif: semua authenticated bisa lihat)
DROP POLICY IF EXISTS "Semua user terautentikasi dapat membaca data petugas keuangan"
    ON public.finance_officers;
CREATE POLICY "Allow read finance_officers" ON public.finance_officers
    FOR SELECT TO authenticated
    USING (
        (SELECT role FROM public.profiles WHERE id = auth.uid())
        IN ('super_admin', 'admin', 'petugas_keuangan')
    );
