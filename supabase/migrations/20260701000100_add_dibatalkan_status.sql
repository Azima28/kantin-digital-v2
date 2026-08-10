-- Migration: Add 'Dibatalkan' to orders status check constraint
-- Tujuan: Izinkan status 'Dibatalkan' pada tabel orders (pembatalan oleh siswa/petugas)

ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_status_check;

ALTER TABLE public.orders
  ADD CONSTRAINT orders_status_check
  CHECK (status IN ('Baru', 'Sedang Dimasak', 'Siap Diambil', 'Siap Diantar', 'Selesai', 'Dibatalkan'));
