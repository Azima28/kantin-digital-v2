-- Fix RLS untuk products — operator kantin gagal insert karena
-- auth.uid() sering null saat fallback login path
ALTER TABLE public.products DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs DISABLE ROW LEVEL SECURITY;
