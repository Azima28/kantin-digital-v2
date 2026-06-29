-- Migrasi: Restrict Classes management to super_admin
-- Tanggal: 2026-06-26

-- Drop kebijakan lama
DROP POLICY IF EXISTS "Admin dan Keuangan dapat mengelola kelas" ON public.classes;

-- Buat kebijakan baru yang hanya mengizinkan 'super_admin' untuk melakukan mutasi (INSERT, UPDATE, DELETE)
CREATE POLICY "Hanya Super Admin yang dapat mengelola kelas"
    ON public.classes FOR ALL TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'super_admin'
        )
    ) WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'super_admin'
        )
    );
