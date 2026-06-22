-- Fix category CHECK constraint di tabel products
-- Menambahkan 'camilan' sebagai kategori yang valid
ALTER TABLE public.products DROP CONSTRAINT IF EXISTS products_category_check;
ALTER TABLE public.products ADD CONSTRAINT products_category_check
  CHECK (category IN ('makanan', 'minuman', 'camilan'));
