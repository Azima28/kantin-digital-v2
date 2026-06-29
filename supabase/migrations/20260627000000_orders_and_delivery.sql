-- ============================================================================
-- Migration: Orders System + Delivery Feature
-- 20260627000000_orders_and_delivery.sql
-- ============================================================================

-- 1. Tambah kolom delivery ke canteen_operators
ALTER TABLE public.canteen_operators
  ADD COLUMN IF NOT EXISTS delivery_enabled BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS delivery_fee     INTEGER  NOT NULL DEFAULT 0 CHECK (delivery_fee >= 0);

-- 2. Tabel lokasi pengiriman (dikelola Super Admin)
CREATE TABLE IF NOT EXISTS public.delivery_locations (
  id         UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name       TEXT NOT NULL,
  type       TEXT NOT NULL DEFAULT 'class'
             CHECK (type IN ('class', 'room', 'other')),
  is_active  BOOLEAN NOT NULL DEFAULT true,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Tabel orders utama
CREATE TABLE IF NOT EXISTS public.orders (
  id                UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  student_id        UUID NOT NULL REFERENCES public.students(id) ON DELETE RESTRICT,
  operator_id       UUID NOT NULL REFERENCES public.canteen_operators(id) ON DELETE RESTRICT,
  transaction_id    UUID REFERENCES public.transactions(id),
  status            TEXT NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending','accepted','preparing','ready','completed','cancelled')),
  delivery_type     TEXT NOT NULL DEFAULT 'takeaway'
                    CHECK (delivery_type IN ('takeaway','delivery')),
  delivery_location TEXT,           -- nama lokasi (custom atau dari list)
  delivery_fee      INTEGER NOT NULL DEFAULT 0 CHECK (delivery_fee >= 0),
  student_phone     TEXT,           -- nomor WA (wajib jika delivery)
  subtotal          INTEGER NOT NULL CHECK (subtotal > 0),
  total_amount      INTEGER NOT NULL CHECK (total_amount > 0),
  note              TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. Tabel item per order
CREATE TABLE IF NOT EXISTS public.order_items (
  id         UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  order_id   UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
  quantity   INTEGER NOT NULL CHECK (quantity > 0),
  unit_price INTEGER NOT NULL CHECK (unit_price > 0),
  note       TEXT
);

-- 5. Auto-update updated_at trigger
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS orders_updated_at ON public.orders;
CREATE TRIGGER orders_updated_at
  BEFORE UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 6. Index untuk performa query
CREATE INDEX IF NOT EXISTS idx_orders_student_id  ON public.orders(student_id);
CREATE INDEX IF NOT EXISTS idx_orders_operator_id ON public.orders(operator_id);
CREATE INDEX IF NOT EXISTS idx_orders_status       ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at   ON public.orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items(order_id);

-- 7. Seed lokasi default (diambil dari tabel classes jika ada, plus ruangan umum)
INSERT INTO public.delivery_locations (name, type, sort_order) VALUES
  ('Ruang Guru',        'room',  1),
  ('Perpustakaan',      'room',  2),
  ('UKS',               'room',  3),
  ('Ruang BK',          'room',  4),
  ('Lapangan',          'other', 5),
  ('Parkiran',          'other', 6)
ON CONFLICT DO NOTHING;
