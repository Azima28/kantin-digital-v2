-- Migrasi: Nonaktifkan RLS (Row Level Security) untuk development
-- Tanggal: 2026-06-17
-- Alasan: Selama fase development (belum production), RLS menghambat testing.
--         RLS akan diaktifkan kembali saat menjelang production deployment.

-- Nonaktifkan RLS di semua tabel
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.students DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.canteen_operators DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.products DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.transaction_items DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.parent_students DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.finance_officers DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_settings DISABLE ROW LEVEL SECURITY;
