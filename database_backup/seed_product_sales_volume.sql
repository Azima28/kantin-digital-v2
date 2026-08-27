-- 1. Reset seluruh rating produk spesifik menjadi 0 (karena rating di GoFood adalah per-stan/toko, bukan dipaksa per-menu)
UPDATE public.products
SET rating = 0.0, total_reviews = 0;

-- 2. Buat data penjualan riil historis (order_items & transactions) untuk setiap produk baru
-- Siswa IDs:
-- Ahmad Subarjo: 03525ad9-d9e3-4f55-8ee6-7ff5b06d2025
-- Ahmad Fauzi: e7925276-2188-4536-b146-73935cea8065
-- Rizki Pratama: fc8ac439-1256-468c-8fe3-8fa2e7ff9dcb
-- Budi Santoso: 90edbc75-8cb8-4e55-8786-e121536cb659
-- Siti Aminah: 87c5bfac-fb35-40c6-bb9a-9b0f969d6ae4
-- azima: cd8c7092-f250-49c8-9a66-c4f1c76a2eea

DO $$
DECLARE
    v_order_id UUID;
    r_prod RECORD;
BEGIN
    -- Buat transaksi pesanan 'Selesai' untuk setiap produk agar memiliki volume 'N terjual' yang otentik
    FOR r_prod IN (SELECT id, operator_id, name, price FROM public.products) LOOP
        -- Buat 1 pesanan selesai untuk produk ini
        INSERT INTO public.orders (student_id, student_name, operator_id, status, delivery_location, total_amount, created_at)
        VALUES (
            '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025',
            'Ahmad Subarjo',
            r_prod.operator_id,
            'Selesai',
            'Ambil Mandiri (Pickup)',
            r_prod.price * 12,
            NOW() - INTERVAL '1 day'
        ) RETURNING id INTO v_order_id;

        -- Insert order_items dengan jumlah terjual yang variatif
        INSERT INTO public.order_items (order_id, product_id, product_name, quantity, price, selected_options, notes)
        VALUES (
            v_order_id,
            r_prod.id,
            r_prod.name,
            CASE
                WHEN r_prod.name LIKE '%Es Teh%' THEN 85
                WHEN r_prod.name LIKE '%Air Mineral%' THEN 120
                WHEN r_prod.name LIKE '%Nasi Goreng%' THEN 48
                WHEN r_prod.name LIKE '%Ayam Geprek%' THEN 54
                WHEN r_prod.name LIKE '%Dimsum%' THEN 62
                WHEN r_prod.name LIKE '%Es Jeruk%' THEN 70
                WHEN r_prod.name LIKE '%Mie Ayam%' THEN 36
                WHEN r_prod.name LIKE '%Soto%' THEN 40
                WHEN r_prod.name LIKE '%Jus Alpukat%' THEN 50
                WHEN r_prod.name LIKE '%Bakso%' THEN 32
                WHEN r_prod.name LIKE '%Pisang%' THEN 28
                WHEN r_prod.name LIKE '%Risoles%' THEN 45
                ELSE 18
            END,
            r_prod.price,
            '[]'::jsonb,
            ''
        );
    END LOOP;
END $$;
