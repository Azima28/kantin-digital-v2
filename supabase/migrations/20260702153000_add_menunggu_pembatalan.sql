-- Migration: Add 'Menunggu Pembatalan' status and cancel_request_reason column
-- Tujuan: Memungkinkan pengajuan pembatalan oleh siswa yang harus disetujui petugas kantin.

ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_status_check;

ALTER TABLE public.orders
  ADD CONSTRAINT orders_status_check
  CHECK (status IN ('Baru', 'Sedang Dimasak', 'Siap Diambil', 'Siap Diantar', 'Selesai', 'Dibatalkan', 'Menunggu Pembatalan'));

ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS cancel_request_reason TEXT;
