-- Seed Authentic Reviews & Ratings per Product using Real Students

-- 1. Bersihkan review lama dan buat review per produk yang valid
DELETE FROM public.order_reviews;

DO $$
DECLARE
    -- Siswa Real ID
    v_std_ahmad UUID := '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025'; -- Ahmad Subarjo
    v_std_fauzi UUID := 'e7925276-2188-4536-b146-73935cea8065'; -- Ahmad Fauzi
    v_std_rizki UUID := 'fc8ac439-1256-468c-8fe3-8fa2e7ff9dcb'; -- Rizki Pratama
    v_std_budi  UUID := '90edbc75-8cb8-4e55-8786-e121536cb659'; -- Budi Santoso
    v_std_siti  UUID := '87c5bfac-fb35-40c6-bb9a-9b0f969d6ae4'; -- Siti Aminah
    v_std_azima UUID := 'cd8c7092-f250-49c8-9a66-c4f1c76a2eea'; -- azima

    -- Operator Stan ID
    v_op_utama  UUID := '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c'; -- Petugas Kantin / Stan Utama
    v_op_bude   UUID := '98dd238b-b56c-4d27-8125-e0624385d2e7'; -- Stan Bude Ani
    v_op_bakso  UUID := '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3'; -- Stan Bakso Enak
    v_op_nasgor UUID := '51325215-0176-4324-bb74-4e973bcfff13'; -- Stan Nasi Goreng

    -- Produk Stan Utama
    v_prod_geprek    UUID := 'f3f402ae-63cb-443c-818e-16fab62a79cf'; -- Ayam Geprek Sambal Ijo
    v_prod_mie_ayam  UUID := 'a30e1a4b-fd91-435d-83db-3959402932bd'; -- Mie Ayam Bakso
    v_prod_nasgor_sp UUID := 'ad805ac8-75b0-4e9c-a055-9abd72a14a38'; -- Nasi Goreng Spesial
    v_prod_bakso_mc  UUID := 'a86158a5-9702-4b1c-a9b0-fa0e2029d749'; -- Bakso Mercon Spesial
    v_prod_es_jeruk  UUID := '97607bc8-c362-4265-a286-bbfecf1605e7'; -- Es Jeruk Segar
    v_prod_es_teh    UUID := '8db00359-2755-4951-b3cf-37d147f47f47'; -- Es Teh Manis
    v_prod_air_min   UUID := 'e0cd8847-7406-4599-bdbb-66c5806bc6e3'; -- Air Mineral Dingin

    -- Produk Stan Bude Ani
    v_prod_soto      UUID := 'd9795046-f5dc-4871-b369-a2b23b7f2944'; -- Soto Ayam Madura
    v_prod_rames     UUID := '03918dfe-c3fa-4519-b8eb-a3bd19732ebe'; -- Nasi Rames Komplit
    v_prod_dimsum    UUID := '78e1ec4f-362e-4ae9-b92c-3a74a8d276ff'; -- Dimsum Goreng Hot
    v_prod_risoles   UUID := '01dbd547-d0a9-42f1-b253-898335c274c5'; -- Risoles Mayo Crispy

    -- Produk Stan Bakso
    v_prod_mie_bakso UUID := '40671946-314a-4df1-9608-d71d74455b61'; -- Mie Bakso Urat
    v_prod_bakso_kmp UUID := '5db939da-0420-4d45-9e9e-e8a50c7bd7ef'; -- Bakso Urat Komplit

    -- Produk Stan Nasgor
    v_prod_nasgor_pd UUID := '9db00708-26b6-4ccf-b7f8-25bd3f4e999a'; -- Nasi Goreng Pedas Gila
    v_prod_pisang    UUID := '8e0f9715-4809-467a-84a3-e1f98f12a561'; -- Pisang Goreng Keju
    v_prod_wafer     UUID := 'a5029eee-e60b-4cf5-94e5-4ca693c35bbf'; -- Tango Wafer Cokelat
    v_prod_jus_alpk  UUID := '1eb4af50-9a49-468b-9e9b-10f42f95cded'; -- Jus Alpukat Kocok

    v_order_id UUID;
BEGIN
    -- 1. Review Ayam Geprek Sambal Ijo (Stan Utama)
    INSERT INTO public.orders (student_id, student_name, operator_id, status, delivery_location, total_amount)
    VALUES (v_std_budi, 'Budi Santoso', v_op_utama, 'Selesai', 'Ambil di Stan', 16000)
    RETURNING id INTO v_order_id;
    INSERT INTO public.order_items (order_id, product_id, product_name, quantity, price)
    VALUES (v_order_id, v_prod_geprek, 'Ayam Geprek Sambal Ijo', 1, 16000);
    INSERT INTO public.order_reviews (order_id, student_id, operator_id, product_id, product_name, rating, review_text, tags, is_anonymous, created_at)
    VALUES (v_order_id, v_std_budi, v_op_utama, v_prod_geprek, 'Ayam Geprek Sambal Ijo', 5, 'Ayam gepreknya renyah garing, sambal ijonya pedas gurih nagih banget!', '{"Renyah", "Sambal Juara", "Porsi Pas"}', false, NOW() - INTERVAL '5 hours');

    INSERT INTO public.orders (student_id, student_name, operator_id, status, delivery_location, total_amount)
    VALUES (v_std_siti, 'Siti Aminah', v_op_utama, 'Selesai', 'Ambil di Stan', 16000)
    RETURNING id INTO v_order_id;
    INSERT INTO public.order_items (order_id, product_id, product_name, quantity, price)
    VALUES (v_order_id, v_prod_geprek, 'Ayam Geprek Sambal Ijo', 1, 16000);
    INSERT INTO public.order_reviews (order_id, student_id, operator_id, product_id, product_name, rating, review_text, tags, is_anonymous, created_at)
    VALUES (v_order_id, v_std_siti, v_op_utama, v_prod_geprek, 'Ayam Geprek Sambal Ijo', 5, 'Daging ayamnya empuk dan sambalnya fresh baru diulek. Juara!', '{"Ayam Empuk", "Fresh"}', false, NOW() - INTERVAL '1 day');

    -- 2. Review Mie Ayam Bakso (Stan Utama)
    INSERT INTO public.orders (student_id, student_name, operator_id, status, delivery_location, total_amount)
    VALUES (v_std_rizki, 'Rizki Pratama', v_op_utama, 'Selesai', 'Ambil di Stan', 14000)
    RETURNING id INTO v_order_id;
    INSERT INTO public.order_items (order_id, product_id, product_name, quantity, price)
    VALUES (v_order_id, v_prod_mie_ayam, 'Mie Ayam Bakso', 1, 14000);
    INSERT INTO public.order_reviews (order_id, student_id, operator_id, product_id, product_name, rating, review_text, tags, is_anonymous, created_at)
    VALUES (v_order_id, v_std_rizki, v_op_utama, v_prod_mie_ayam, 'Mie Ayam Bakso', 5, 'Mie ayam bakso kuahnya gurih kaya rempah, langganan tiap istirahat!', '{"Kuah Gurih", "Rekomendasi"}', false, NOW() - INTERVAL '1 hour');

    -- 3. Review Nasi Goreng Spesial (Stan Utama)
    INSERT INTO public.orders (student_id, student_name, operator_id, status, delivery_location, total_amount)
    VALUES (v_std_fauzi, 'Ahmad Fauzi', v_op_utama, 'Selesai', 'Ambil di Stan', 15000)
    RETURNING id INTO v_order_id;
    INSERT INTO public.order_items (order_id, product_id, product_name, quantity, price)
    VALUES (v_order_id, v_prod_nasgor_sp, 'Nasi Goreng Spesial', 1, 15000);
    INSERT INTO public.order_reviews (order_id, student_id, operator_id, product_id, product_name, rating, review_text, tags, is_anonymous, created_at)
    VALUES (v_order_id, v_std_fauzi, v_op_utama, v_prod_nasgor_sp, 'Nasi Goreng Spesial', 5, 'Nasi goreng spesialnya enak banget, porsi pas dan bumbunya mantap!', '{"Enak Banget", "Porsi Pas"}', false, NOW() - INTERVAL '2 days');

    -- 4. Review Bakso Mercon Spesial (Stan Utama)
    INSERT INTO public.orders (student_id, student_name, operator_id, status, delivery_location, total_amount)
    VALUES (v_std_azima, 'azima', v_op_utama, 'Selesai', 'Ambil di Stan', 15000)
    RETURNING id INTO v_order_id;
    INSERT INTO public.order_items (order_id, product_id, product_name, quantity, price)
    VALUES (v_order_id, v_prod_bakso_mc, 'Bakso Mercon Spesial', 1, 15000);
    INSERT INTO public.order_reviews (order_id, student_id, operator_id, product_id, product_name, rating, review_text, tags, is_anonymous, created_at)
    VALUES (v_order_id, v_std_azima, v_op_utama, v_prod_bakso_mc, 'Bakso Mercon Spesial', 5, 'Pedas merconnya nendang banget dan baksonya padat berurat.', '{"Pedas Nendang", "Bakso Padat"}', false, NOW() - INTERVAL '3 hours');

    -- 5. Review Es Jeruk Segar (Stan Utama)
    INSERT INTO public.orders (student_id, student_name, operator_id, status, delivery_location, total_amount)
    VALUES (v_std_siti, 'Siti Aminah', v_op_utama, 'Selesai', 'Ambil di Stan', 5000)
    RETURNING id INTO v_order_id;
    INSERT INTO public.order_items (order_id, product_id, product_name, quantity, price)
    VALUES (v_order_id, v_prod_es_jeruk, 'Es Jeruk Segar', 1, 5000);
    INSERT INTO public.order_reviews (order_id, student_id, operator_id, product_id, product_name, rating, review_text, tags, is_anonymous, created_at)
    VALUES (v_order_id, v_std_siti, v_op_utama, v_prod_es_jeruk, 'Es Jeruk Segar', 5, 'Pelayanan cepat dan ramah, es jeruknya segar alami tanpa pemanis buatan.', '{"Segar Alami", "Cepat"}', false, NOW() - INTERVAL '1 day');

    -- 6. Review Es Teh Manis & Air Mineral (Stan Utama)
    INSERT INTO public.orders (student_id, student_name, operator_id, status, delivery_location, total_amount)
    VALUES (v_std_ahmad, 'Ahmad Subarjo', v_op_utama, 'Selesai', 'Ambil di Stan', 4000)
    RETURNING id INTO v_order_id;
    INSERT INTO public.order_items (order_id, product_id, product_name, quantity, price)
    VALUES (v_order_id, v_prod_es_teh, 'Es Teh Manis', 1, 4000);
    INSERT INTO public.order_reviews (order_id, student_id, operator_id, product_id, product_name, rating, review_text, tags, is_anonymous, created_at)
    VALUES (v_order_id, v_std_ahmad, v_op_utama, v_prod_es_teh, 'Es Teh Manis', 5, 'Manisnya pas dan es batunya bersih bening.', '{"Manis Pas", "Segar"}', false, NOW() - INTERVAL '6 hours');

    INSERT INTO public.orders (student_id, student_name, operator_id, status, delivery_location, total_amount)
    VALUES (v_std_fauzi, 'Ahmad Fauzi', v_op_utama, 'Selesai', 'Ambil di Stan', 3000)
    RETURNING id INTO v_order_id;
    INSERT INTO public.order_items (order_id, product_id, product_name, quantity, price)
    VALUES (v_order_id, v_prod_air_min, 'Air Mineral Dingin', 1, 3000);
    INSERT INTO public.order_reviews (order_id, student_id, operator_id, product_id, product_name, rating, review_text, tags, is_anonymous, created_at)
    VALUES (v_order_id, v_std_fauzi, v_op_utama, v_prod_air_min, 'Air Mineral Dingin', 5, 'Dinginnya segar pas istirahat.', '{"Dingin Segar"}', false, NOW() - INTERVAL '8 hours');

    -- 7. Review Soto Ayam Madura (Stan Bude Ani)
    INSERT INTO public.orders (student_id, student_name, operator_id, status, delivery_location, total_amount)
    VALUES (v_std_ahmad, 'Ahmad Subarjo', v_op_bude, 'Selesai', 'Ambil di Stan', 15000)
    RETURNING id INTO v_order_id;
    INSERT INTO public.order_items (order_id, product_id, product_name, quantity, price)
    VALUES (v_order_id, v_prod_soto, 'Soto Ayam Madura', 1, 15000);
    INSERT INTO public.order_reviews (order_id, student_id, operator_id, product_id, product_name, rating, review_text, tags, is_anonymous, created_at)
    VALUES (v_order_id, v_std_ahmad, v_op_bude, v_prod_soto, 'Soto Ayam Madura', 5, 'Soto ayam madura bude kuahnya rempah asli, koya-nya melimpah!', '{"Rempah Asli", "Porsi Banyak"}', false, NOW() - INTERVAL '3 days');

    -- 8. Review Nasi Rames Komplit (Stan Bude Ani)
    INSERT INTO public.orders (student_id, student_name, operator_id, status, delivery_location, total_amount)
    VALUES (v_std_azima, 'azima', v_op_bude, 'Selesai', 'Ambil di Stan', 14000)
    RETURNING id INTO v_order_id;
    INSERT INTO public.order_items (order_id, product_id, product_name, quantity, price)
    VALUES (v_order_id, v_prod_rames, 'Nasi Rames Komplit', 1, 14000);
    INSERT INTO public.order_reviews (order_id, student_id, operator_id, product_id, product_name, rating, review_text, tags, is_anonymous, created_at)
    VALUES (v_order_id, v_std_azima, v_op_bude, v_prod_rames, 'Nasi Rames Komplit', 5, 'Nasi rames bude lauknya komplit, bersih dan selalu hangat saat diantar.', '{"Lauk Komplit", "Bersih & Rapi"}', false, NOW() - INTERVAL '1 day');

    -- 9. Review Dimsum Goreng Hot (Stan Bude Ani)
    INSERT INTO public.orders (student_id, student_name, operator_id, status, delivery_location, total_amount)
    VALUES (v_std_siti, 'Siti Aminah', v_op_bude, 'Selesai', 'Ambil di Stan', 12000)
    RETURNING id INTO v_order_id;
    INSERT INTO public.order_items (order_id, product_id, product_name, quantity, price)
    VALUES (v_order_id, v_prod_dimsum, 'Dimsum Goreng Hot', 1, 12000);
    INSERT INTO public.order_reviews (order_id, student_id, operator_id, product_id, product_name, rating, review_text, tags, is_anonymous, created_at)
    VALUES (v_order_id, v_std_siti, v_op_bude, v_prod_dimsum, 'Dimsum Goreng Hot', 5, 'Dimsum goreng hot crispy banget, saus cocolannya juara di kantin.', '{"Crispy", "Saus Enak"}', false, NOW() - INTERVAL '2 hours');

    -- 10. Review Risoles Mayo Crispy (Stan Bude Ani)
    INSERT INTO public.orders (student_id, student_name, operator_id, status, delivery_location, total_amount)
    VALUES (v_std_budi, 'Budi Santoso', v_op_bude, 'Selesai', 'Ambil di Stan', 5000)
    RETURNING id INTO v_order_id;
    INSERT INTO public.order_items (order_id, product_id, product_name, quantity, price)
    VALUES (v_order_id, v_prod_risoles, 'Risoles Mayo Crispy', 1, 5000);
    INSERT INTO public.order_reviews (order_id, student_id, operator_id, product_id, product_name, rating, review_text, tags, is_anonymous, created_at)
    VALUES (v_order_id, v_std_budi, v_op_bude, v_prod_risoles, 'Risoles Mayo Crispy', 5, 'Kulit risol renyah dan isian mayonya lumer lezat.', '{"Lumer", "Crispy"}', false, NOW() - INTERVAL '4 hours');

    -- 11. Review Mie Bakso Urat (Stan Bakso Enak)
    INSERT INTO public.orders (student_id, student_name, operator_id, status, delivery_location, total_amount)
    VALUES (v_std_fauzi, 'Ahmad Fauzi', v_op_bakso, 'Selesai', 'Ambil di Stan', 15000)
    RETURNING id INTO v_order_id;
    INSERT INTO public.order_items (order_id, product_id, product_name, quantity, price)
    VALUES (v_order_id, v_prod_mie_bakso, 'Mie Bakso Urat', 1, 15000);
    INSERT INTO public.order_reviews (order_id, student_id, operator_id, product_id, product_name, rating, review_text, tags, is_anonymous, created_at)
    VALUES (v_order_id, v_std_fauzi, v_op_bakso, v_prod_mie_bakso, 'Mie Bakso Urat', 5, 'Mie bakso spesial porsi mengenyangkan, harga sangat pas untuk kantong sekolah.', '{"Kenyang", "Harga Pelajar"}', false, NOW() - INTERVAL '4 hours');

    -- 12. Review Bakso Urat Komplit (Stan Bakso Enak)
    INSERT INTO public.orders (student_id, student_name, operator_id, status, delivery_location, total_amount)
    VALUES (v_std_budi, 'Budi Santoso', v_op_bakso, 'Selesai', 'Ambil di Stan', 18000)
    RETURNING id INTO v_order_id;
    INSERT INTO public.order_items (order_id, product_id, product_name, quantity, price)
    VALUES (v_order_id, v_prod_bakso_kmp, 'Bakso Urat Komplit', 1, 18000);
    INSERT INTO public.order_reviews (order_id, student_id, operator_id, product_id, product_name, rating, review_text, tags, is_anonymous, created_at)
    VALUES (v_order_id, v_std_budi, v_op_bakso, v_prod_bakso_kmp, 'Bakso Urat Komplit', 5, 'Bakso uratnya kerasa daging aslinya, kuah kaldunya gurih hangat mantap.', '{"Daging Asli", "Kuah Kaldu"}', false, NOW() - INTERVAL '2 days');

    -- 13. Review Nasi Goreng Pedas Gila (Stan Nasgor)
    INSERT INTO public.orders (student_id, student_name, operator_id, status, delivery_location, total_amount)
    VALUES (v_std_rizki, 'Rizki Pratama', v_op_nasgor, 'Selesai', 'Ambil di Stan', 15000)
    RETURNING id INTO v_order_id;
    INSERT INTO public.order_items (order_id, product_id, product_name, quantity, price)
    VALUES (v_order_id, v_prod_nasgor_pd, 'Nasi Goreng Pedas Gila', 1, 15000);
    INSERT INTO public.order_reviews (order_id, student_id, operator_id, product_id, product_name, rating, review_text, tags, is_anonymous, created_at)
    VALUES (v_order_id, v_std_rizki, v_op_nasgor, v_prod_nasgor_pd, 'Nasi Goreng Pedas Gila', 5, 'Nasgor pedas gila beneran pedas mantap bikin nagih, recommended!', '{"Pedas Mantap", "Wajib Coba"}', false, NOW() - INTERVAL '1 day');

    -- 14. Review Pisang Goreng Keju & Jus Alpukat (Stan Nasgor)
    INSERT INTO public.orders (student_id, student_name, operator_id, status, delivery_location, total_amount)
    VALUES (v_std_azima, 'azima', v_op_nasgor, 'Selesai', 'Ambil di Stan', 8000)
    RETURNING id INTO v_order_id;
    INSERT INTO public.order_items (order_id, product_id, product_name, quantity, price)
    VALUES (v_order_id, v_prod_pisang, 'Pisang Goreng Keju', 1, 8000);
    INSERT INTO public.order_reviews (order_id, student_id, operator_id, product_id, product_name, rating, review_text, tags, is_anonymous, created_at)
    VALUES (v_order_id, v_std_azima, v_op_nasgor, v_prod_pisang, 'Pisang Goreng Keju', 5, 'Pisang gorengnya manis legit dan taburan kejunya melimpah.', '{"Manis Legit", "Keju Melimpah"}', false, NOW() - INTERVAL '3 hours');

    INSERT INTO public.orders (student_id, student_name, operator_id, status, delivery_location, total_amount)
    VALUES (v_std_ahmad, 'Ahmad Subarjo', v_op_nasgor, 'Selesai', 'Ambil di Stan', 10000)
    RETURNING id INTO v_order_id;
    INSERT INTO public.order_items (order_id, product_id, product_name, quantity, price)
    VALUES (v_order_id, v_prod_jus_alpk, 'Jus Alpukat Kocok', 1, 10000);
    INSERT INTO public.order_reviews (order_id, student_id, operator_id, product_id, product_name, rating, review_text, tags, is_anonymous, created_at)
    VALUES (v_order_id, v_std_ahmad, v_op_nasgor, v_prod_jus_alpk, 'Jus Alpukat Kocok', 5, 'Jus alpukatnya kental manis dan cokelatnya berlimpah.', '{"Kental Manis", "Segar"}', false, NOW() - INTERVAL '2 hours');

END $$;

-- 2. Sinkronkan rating dan total_reviews riil per produk pada tabel products
UPDATE public.products p
SET
    rating = COALESCE((
        SELECT ROUND(AVG(r.rating)::numeric, 1)
        FROM public.order_reviews r
        WHERE r.product_id = p.id
    ), 4.8),
    total_reviews = COALESCE((
        SELECT COUNT(r.id)
        FROM public.order_reviews r
        WHERE r.product_id = p.id
    ), 0);

-- Pastikan semua produk yang memiliki ulasan di atas memiliki rating riil yang sinkron
UPDATE public.products p
SET
    rating = COALESCE((
        SELECT ROUND(AVG(r.rating)::numeric, 1)
        FROM public.order_reviews r
        WHERE r.product_id = p.id
    ), 4.8),
    total_reviews = (
        SELECT COUNT(r.id)
        FROM public.order_reviews r
        WHERE r.product_id = p.id
    );

-- 3. Sinkronkan rating dan total_reviews riil pada tabel canteen_operators
UPDATE public.canteen_operators co
SET
    rating = COALESCE((
        SELECT ROUND(AVG(r.rating)::numeric, 1)
        FROM public.order_reviews r
        WHERE r.operator_id = co.id
    ), 4.8),
    total_reviews = COALESCE((
        SELECT COUNT(r.id)
        FROM public.order_reviews r
        WHERE r.operator_id = co.id
    ), 0);
