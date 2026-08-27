
-- 1. Bersihkan produk lama dan perbarui dengan menu lengkap berkualitas tinggi
DELETE FROM public.products;

-- Operator IDs:
-- Stan Utama: 6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c
-- Bude Ani: 98dd238b-b56c-4d27-8125-e0624385d2e7
-- Stan Bakso Enak: 45ad99e3-5f4b-42ff-9f84-a85467cbe9b3
-- Stan Nasgor: 51325215-0176-4324-bb74-4e973bcfff13

-- ── STAN UTAMA (Aneka Nasi & Minuman) ──
INSERT INTO public.products (operator_id, name, price, category, is_available, image_url, customizable_options, rating, total_reviews)
VALUES
('6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Nasi Goreng Spesial', 15000, 'makanan', true, 'https://kantin.zitech.web.id/uploads/products/product_nasi_goreng.jpg', '["Pedas Sedang", "Pedas Banget", "Tidak Pedas", "Telur Dadar (+Rp 3.000)"]', 4.9, 48),
('6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Mie Ayam Bakso', 13000, 'makanan', true, 'https://kantin.zitech.web.id/uploads/products/product_mie_ayam.jpg', '["Pangsit Goreng (+Rp 2.000)", "Bakso Tambahan (+Rp 3.000)", "Tanpa Sayur"]', 4.8, 35),
('6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Ayam Geprek Sambal Ijo', 16000, 'makanan', true, 'https://kantin.zitech.web.id/uploads/products/product_ayam_geprek.jpg', '["Level 1 (Sedang)", "Level 3 (Pedas)", "Level 5 (Super Pedas)", "Ekstra Keju (+Rp 3.000)"]', 4.9, 52),
('6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Bakso Mercon Spesial', 15000, 'makanan', true, 'https://kantin.zitech.web.id/uploads/products/product_bakso_mercon.jpg', '["Kuah Pedas Mercon", "Kuah Bening", "Bihun Ekstra"]', 4.7, 29),
('6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Es Jeruk Segar', 5000, 'minuman', true, 'https://kantin.zitech.web.id/uploads/products/product_es_jeruk.jpg', '["Sedikit Es (Less Ice)", "Tanpa Es", "Gula Sedikit (Less Sugar)"]', 4.9, 64),
('6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Es Teh Manis', 3000, 'minuman', true, 'https://kantin.zitech.web.id/uploads/products/product_es_teh.jpg', '["Sedikit Es (Less Ice)", "Manis Sedang", "Tawar Dingin"]', 4.8, 80),
('6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Air Mineral Dingin', 3000, 'minuman', true, 'https://kantin.zitech.web.id/uploads/products/product_air_mineral.jpg', '["Dingin", "Biasa (Suhu Ruang)"]', 5.0, 95);

-- ── BUDE ANI (Soto, Nasi Rames & Dimsum) ──
INSERT INTO public.products (operator_id, name, price, category, is_available, image_url, customizable_options, rating, total_reviews)
VALUES
('98dd238b-b56c-4d27-8125-e0624385d2e7', 'Soto Ayam Madura', 14000, 'makanan', true, 'https://kantin.zitech.web.id/uploads/products/product_soto_ayam.jpg', '["Koya Banyak", "Jeruk Nipis Tambahan", "Nasi Dipisah (+Rp 3.000)"]', 5.0, 42),
('98dd238b-b56c-4d27-8125-e0624385d2e7', 'Nasi Rames Komplit', 12000, 'makanan', true, 'https://kantin.zitech.web.id/uploads/products/product_nasi_rames.jpg', '["Lauk Ayam Suwir", "Lauk Telur Balado", "Sambal Goreng Kentang"]', 4.9, 38),
('98dd238b-b56c-4d27-8125-e0624385d2e7', 'Dimsum Goreng Hot', 5000, 'camilan', true, 'https://kantin.zitech.web.id/uploads/products/product_dimsum_goreng.jpg', '["Saus Sambal Bangkok", "Mayonaise", "Bubuk Cabe"]', 5.0, 60),
('98dd238b-b56c-4d27-8125-e0624385d2e7', 'Risoles Mayo Crispy', 4000, 'camilan', true, 'https://kantin.zitech.web.id/uploads/products/product_risoles_mayo.jpg', '["Isi Smoked Beef & Telur", "Cabe Rawit Hijau"]', 4.8, 31);

-- ── STAN BAKSO ENAK (Spesialis Bakso) ──
INSERT INTO public.products (operator_id, name, price, category, is_available, image_url, customizable_options, rating, total_reviews)
VALUES
('45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 'Bakso Urat Komplit', 18000, 'makanan', true, 'https://kantin.zitech.web.id/uploads/products/product_bakso_mercon.jpg', '["Campur Mie & Bihun", "Bihun Saja", "Mie Kuning Saja"]', 4.8, 27),
('45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 'Mie Bakso Urat', 15000, 'makanan', true, 'https://kantin.zitech.web.id/uploads/products/product_mie_ayam.jpg', '["Pedas", "Sedang", "Kuah Bening"]', 4.6, 22);

-- ── STAN NASGOR & JUS (Spesialis Nasi Goreng & Jus Buah) ──
INSERT INTO public.products (operator_id, name, price, category, is_available, image_url, customizable_options, rating, total_reviews)
VALUES
('51325215-0176-4324-bb74-4e973bcfff13', 'Nasi Goreng Pedas Gila', 14000, 'makanan', true, 'https://kantin.zitech.web.id/uploads/products/product_nasi_goreng.jpg', '["Level 1", "Level 2", "Level 3 Gila", "Telur Ceplok (+Rp 3.000)"]', 4.7, 33),
('51325215-0176-4324-bb74-4e973bcfff13', 'Pisang Goreng Keju', 6000, 'camilan', true, 'https://kantin.zitech.web.id/uploads/products/product_pisang_keju.jpg', '["Cokelat Keju", "Keju Susu", "Original Crispy"]', 4.9, 45),
('51325215-0176-4324-bb74-4e973bcfff13', 'Tango Wafer Cokelat', 7000, 'camilan', true, 'https://kantin.zitech.web.id/uploads/products/product_tango_wafer.jpg', '["Wafer Cokelat", "Wafer Vanila"]', 4.5, 19),
('51325215-0176-4324-bb74-4e973bcfff13', 'Jus Alpukat Kocok', 8000, 'minuman', true, 'https://kantin.zitech.web.id/uploads/products/product_jus_alpukat.jpg', '["Susu Cokelat", "Susu Putih", "Gula Sedikit"]', 4.9, 57);
