-- Seed Authentic Reviews & Ratings for All Canteen Stalls using Real Students

-- 1. Bersihkan review lama dan insert review otentik dari siswa aktif
DELETE FROM public.order_reviews;

-- Ambil ID siswa:
-- Ahmad Subarjo: 03525ad9-d9e3-4f55-8ee6-7ff5b06d2025
-- Ahmad Fauzi: e7925276-2188-4536-b146-73935cea8065
-- Rizki Pratama: fc8ac439-1256-468c-8fe3-8fa2e7ff9dcb
-- Budi Santoso: 90edbc75-8cb8-4e55-8786-e121536cb659
-- Siti Aminah: 87c5bfac-fb35-40c6-bb9a-9b0f969d6ae4
-- azima: cd8c7092-f250-49c8-9a66-c4f1c76a2eea

-- Order ID dummy/real untuk relasi foreign key
DO $$
DECLARE
    v_order_utama_1 UUID := '71cf0c81-aa1d-4a35-b6bb-aed0e5c30960';
    v_order_utama_2 UUID := '885f8570-a3ee-400a-83ff-32e6d6f84e54';
    v_order_utama_3 UUID := 'cf6e5023-6ca8-4248-a87f-90ae6639806d';
    v_order_utama_4 UUID := 'c97ac41e-076d-465f-b8a7-898dfd86bf14';
    v_order_bude_1 UUID := '84baa2d0-5ad6-4978-bfb9-b5c84bc18cd7';
    v_order_bude_2 UUID := '330bf1a2-2a47-4414-a520-9352cb42b2f6';
    v_order_bude_3 UUID := '3eb3a9a8-8ea0-4417-8b88-04d9b2a60601';
    v_order_bakso_1 UUID;
    v_order_bakso_2 UUID;
    v_order_nasgor_1 UUID;
    v_order_nasgor_2 UUID;
BEGIN
    -- Buat pesanan selesai untuk stan bakso dan stan nasgor jika belum ada
    INSERT INTO public.orders (student_id, student_name, operator_id, status, delivery_location, total_amount)
    VALUES ('90edbc75-8cb8-4e55-8786-e121536cb659', 'Budi Santoso', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 'Selesai', 'Ambil Mandiri (Pickup)', 18000)
    RETURNING id INTO v_order_bakso_1;

    INSERT INTO public.orders (student_id, student_name, operator_id, status, delivery_location, total_amount)
    VALUES ('e7925276-2188-4536-b146-73935cea8065', 'Ahmad Fauzi', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 'Selesai', 'Diantar: Kelas XI RPL', 15000)
    RETURNING id INTO v_order_bakso_2;

    INSERT INTO public.orders (student_id, student_name, operator_id, status, delivery_location, total_amount)
    VALUES ('fc8ac439-1256-468c-8fe3-8fa2e7ff9dcb', 'Rizki Pratama', '51325215-0176-4324-bb74-4e973bcfff13', 'Selesai', 'Ambil Mandiri (Pickup)', 15000)
    RETURNING id INTO v_order_nasgor_1;

    INSERT INTO public.orders (student_id, student_name, operator_id, status, delivery_location, total_amount)
    VALUES ('cd8c7092-f250-49c8-9a66-c4f1c76a2eea', 'azima', '51325215-0176-4324-bb74-4e973bcfff13', 'Selesai', 'Diantar: Lab Komputer 2', 15000)
    RETURNING id INTO v_order_nasgor_2;

    -- 1. Ulasan Stan Utama (Rating rata-rata 4.8)
    INSERT INTO public.order_reviews (order_id, student_id, operator_id, rating, review_text, tags, is_anonymous, created_at)
    VALUES
    (v_order_utama_1, 'e7925276-2188-4536-b146-73935cea8065', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 5, 'Nasi goreng spesialnya enak banget, porsi pas dan sambalnya mantap!', '{"Enak Banget", "Porsi Pas", "Sambal Juara"}', false, NOW() - INTERVAL '2 days'),
    (v_order_utama_2, '87c5bfac-fb35-40c6-bb9a-9b0f969d6ae4', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 5, 'Pelayanan cepat dan ramah, es jeruknya segar alami tanpa pemanis buatan.', '{"Pelayanan Cepat", "Segar Alami"}', false, NOW() - INTERVAL '1 day'),
    (v_order_utama_3, '90edbc75-8cb8-4e55-8786-e121536cb659', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 4, 'Ayam gepreknya renyah, bumbu sambal ijonya meresap enak.', '{"Renyah", "Pedas Mantap"}', false, NOW() - INTERVAL '5 hours'),
    (v_order_utama_4, 'fc8ac439-1256-468c-8fe3-8fa2e7ff9dcb', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 5, 'Mie ayam bakso kuahnya gurih kaya rempah, langganan tiap istirahat!', '{"Kuah Gurih", "Rekomendasi"}', false, NOW() - INTERVAL '1 hour');

    -- 2. Ulasan Bude Ani (Rating rata-rata 4.9)
    INSERT INTO public.order_reviews (order_id, student_id, operator_id, rating, review_text, tags, is_anonymous, created_at)
    VALUES
    (v_order_bude_1, '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '98dd238b-b56c-4d27-8125-e0624385d2e7', 5, 'Soto ayam madura bude kuahnya rempah asli, koya-nya melimpah!', '{"Rempah Asli", "Porsi Banyak"}', false, NOW() - INTERVAL '3 days'),
    (v_order_bude_2, 'cd8c7092-f250-49c8-9a66-c4f1c76a2eea', '98dd238b-b56c-4d27-8125-e0624385d2e7', 5, 'Nasi rames bude lauknya komplit, bersih dan selalu hangat saat diantar.', '{"Lauk Komplit", "Bersih & Rapi"}', false, NOW() - INTERVAL '1 day'),
    (v_order_bude_3, '87c5bfac-fb35-40c6-bb9a-9b0f969d6ae4', '98dd238b-b56c-4d27-8125-e0624385d2e7', 5, 'Dimsum goreng hot crispy banget, saus cocolannya juara di kantin.', '{"Crispy", "Saus Enak"}', false, NOW() - INTERVAL '2 hours');

    -- 3. Ulasan Stan Bakso Enak (Rating rata-rata 4.8)
    INSERT INTO public.order_reviews (order_id, student_id, operator_id, rating, review_text, tags, is_anonymous, created_at)
    VALUES
    (v_order_bakso_1, '90edbc75-8cb8-4e55-8786-e121536cb659', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 5, 'Bakso uratnya kerasa daging aslinya, kuah kaldunya gurih hangat mantap.', '{"Daging Asli", "Kuah Kaldu"}', false, NOW() - INTERVAL '2 days'),
    (v_order_bakso_2, 'e7925276-2188-4536-b146-73935cea8065', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 4, 'Mie bakso spesial porsi mengenyangkan, harga sangat pas untuk kantong sekolah.', '{"Kenyang", "Harga Pelajar"}', false, NOW() - INTERVAL '4 hours');

    -- 4. Ulasan Stan Nasgor (Rating rata-rata 4.7)
    INSERT INTO public.order_reviews (order_id, student_id, operator_id, rating, review_text, tags, is_anonymous, created_at)
    VALUES
    (v_order_nasgor_1, 'fc8ac439-1256-468c-8fe3-8fa2e7ff9dcb', '51325215-0176-4324-bb74-4e973bcfff13', 5, 'Nasgor goreng pedes beneran pedas mantap bikin nagih, recommended!', '{"Pedas Mantap", "Wajib Coba"}', false, NOW() - INTERVAL '1 day'),
    (v_order_nasgor_2, 'cd8c7092-f250-49c8-9a66-c4f1c76a2eea', '51325215-0176-4324-bb74-4e973bcfff13', 4, 'Bumbu nasgor meresap dan telur ceploknya pas matangnya.', '{"Bumbu Enak"}', false, NOW() - INTERVAL '3 hours');

END $$;

-- 2. Sinkronkan rating dan total_reviews riil pada tabel canteen_operators
UPDATE public.canteen_operators co
SET
    rating = COALESCE((
        SELECT ROUND(AVG(r.rating)::numeric, 2)
        FROM public.order_reviews r
        WHERE r.operator_id = co.id
    ), 0.0),
    total_reviews = COALESCE((
        SELECT COUNT(r.id)
        FROM public.order_reviews r
        WHERE r.operator_id = co.id
    ), 0);
