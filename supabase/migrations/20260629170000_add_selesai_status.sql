-- Migration: Add 'Selesai' to orders status check constraint
-- Tujuan: Izinkan status 'Selesai' pada tabel orders

ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_status_check;

ALTER TABLE public.orders
  ADD CONSTRAINT orders_status_check
  CHECK (status IN ('Baru', 'Sedang Dimasak', 'Siap Diambil', 'Siap Diantar', 'Selesai'));
