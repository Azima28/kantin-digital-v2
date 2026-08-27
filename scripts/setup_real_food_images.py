import urllib.request
import os
import subprocess
import json

# Output directories
local_uploads_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'backend', 'uploads', 'products'))
os.makedirs(local_uploads_dir, exist_ok=True)

# Curated High-Quality Food Pictures from Unsplash
IMAGE_SOURCES = {
    "product_nasi_goreng.jpg": "https://images.unsplash.com/photo-1603133872878-684f208fb84b?auto=format&fit=crop&w=800&q=80",
    "product_mie_ayam.jpg": "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=800&q=80",
    "product_ayam_geprek.jpg": "https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?auto=format&fit=crop&w=800&q=80",
    "product_bakso_mercon.jpg": "https://images.unsplash.com/photo-1594041680534-e8c8cdebd659?auto=format&fit=crop&w=800&q=80",
    "product_soto_ayam.jpg": "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80",
    "product_nasi_rames.jpg": "https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=800&q=80",
    "product_dimsum_goreng.jpg": "https://images.unsplash.com/photo-1496116218417-1a781b1c416c?auto=format&fit=crop&w=800&q=80",
    "product_es_jeruk.jpg": "https://images.unsplash.com/photo-1613478223719-2ab802602423?auto=format&fit=crop&w=800&q=80",
    "product_es_teh.jpg": "https://images.unsplash.com/photo-1556679343-c7306c1976bc?auto=format&fit=crop&w=800&q=80",
    "product_jus_alpukat.jpg": "https://images.unsplash.com/photo-1553530666-ba11a7da3888?auto=format&fit=crop&w=800&q=80",
    "product_air_mineral.jpg": "https://images.unsplash.com/photo-1559839914-1b34645a380e?auto=format&fit=crop&w=800&q=80",
    "product_pisang_keju.jpg": "https://images.unsplash.com/photo-1528735602780-2552fd46c7af?auto=format&fit=crop&w=800&q=80",
    "product_tango_wafer.jpg": "https://images.unsplash.com/photo-1599599810769-bcde5a160d32?auto=format&fit=crop&w=800&q=80",
    "product_risoles_mayo.jpg": "https://images.unsplash.com/photo-1541592106381-b31e9677c0e5?auto=format&fit=crop&w=800&q=80"
}

headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}

print("📥 [1/3] Mengunduh foto makanan riil beresolusi tinggi...")
for filename, url in IMAGE_SOURCES.items():
    filepath = os.path.join(local_uploads_dir, filename)
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req) as resp, open(filepath, 'wb') as f:
            f.write(resp.read())
        print(f"  ✓ {filename} ({os.path.getsize(filepath)} bytes)")
    except Exception as e:
        print(f"  ✗ Gagal download {filename}: {e}")

print("\n🚀 [2/3] Menyalin file gambar ke Docker container 'kantin_api'...")
for filename in IMAGE_SOURCES.keys():
    src = os.path.join(local_uploads_dir, filename)
    if os.path.exists(src):
        cmd = f'docker cp "{src}" kantin_api:/app/uploads/products/{filename}'
        subprocess.run(cmd, shell=True, check=True)
print("  ✓ Semua gambar berhasil disalin ke container /app/uploads/products/")

print("\n🗄️ [3/3] Memperbarui database PostgreSQL dengan data menu makanan & URL riil...")

BASE_URL = "https://kantin.zitech.web.id/uploads/products"

sql_script = f"""
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
('6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Nasi Goreng Spesial', 15000, 'makanan', true, '{BASE_URL}/product_nasi_goreng.jpg', '["Pedas Sedang", "Pedas Banget", "Tidak Pedas", "Telur Dadar (+Rp 3.000)"]', 4.9, 48),
('6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Mie Ayam Bakso', 13000, 'makanan', true, '{BASE_URL}/product_mie_ayam.jpg', '["Pangsit Goreng (+Rp 2.000)", "Bakso Tambahan (+Rp 3.000)", "Tanpa Sayur"]', 4.8, 35),
('6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Ayam Geprek Sambal Ijo', 16000, 'makanan', true, '{BASE_URL}/product_ayam_geprek.jpg', '["Level 1 (Sedang)", "Level 3 (Pedas)", "Level 5 (Super Pedas)", "Ekstra Keju (+Rp 3.000)"]', 4.9, 52),
('6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Bakso Mercon Spesial', 15000, 'makanan', true, '{BASE_URL}/product_bakso_mercon.jpg', '["Kuah Pedas Mercon", "Kuah Bening", "Bihun Ekstra"]', 4.7, 29),
('6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Es Jeruk Segar', 5000, 'minuman', true, '{BASE_URL}/product_es_jeruk.jpg', '["Sedikit Es (Less Ice)", "Tanpa Es", "Gula Sedikit (Less Sugar)"]', 4.9, 64),
('6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Es Teh Manis', 3000, 'minuman', true, '{BASE_URL}/product_es_teh.jpg', '["Sedikit Es (Less Ice)", "Manis Sedang", "Tawar Dingin"]', 4.8, 80),
('6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Air Mineral Dingin', 3000, 'minuman', true, '{BASE_URL}/product_air_mineral.jpg', '["Dingin", "Biasa (Suhu Ruang)"]', 5.0, 95);

-- ── BUDE ANI (Soto, Nasi Rames & Dimsum) ──
INSERT INTO public.products (operator_id, name, price, category, is_available, image_url, customizable_options, rating, total_reviews)
VALUES
('98dd238b-b56c-4d27-8125-e0624385d2e7', 'Soto Ayam Madura', 14000, 'makanan', true, '{BASE_URL}/product_soto_ayam.jpg', '["Koya Banyak", "Jeruk Nipis Tambahan", "Nasi Dipisah (+Rp 3.000)"]', 5.0, 42),
('98dd238b-b56c-4d27-8125-e0624385d2e7', 'Nasi Rames Komplit', 12000, 'makanan', true, '{BASE_URL}/product_nasi_rames.jpg', '["Lauk Ayam Suwir", "Lauk Telur Balado", "Sambal Goreng Kentang"]', 4.9, 38),
('98dd238b-b56c-4d27-8125-e0624385d2e7', 'Dimsum Goreng Hot', 5000, 'camilan', true, '{BASE_URL}/product_dimsum_goreng.jpg', '["Saus Sambal Bangkok", "Mayonaise", "Bubuk Cabe"]', 5.0, 60),
('98dd238b-b56c-4d27-8125-e0624385d2e7', 'Risoles Mayo Crispy', 4000, 'camilan', true, '{BASE_URL}/product_risoles_mayo.jpg', '["Isi Smoked Beef & Telur", "Cabe Rawit Hijau"]', 4.8, 31);

-- ── STAN BAKSO ENAK (Spesialis Bakso) ──
INSERT INTO public.products (operator_id, name, price, category, is_available, image_url, customizable_options, rating, total_reviews)
VALUES
('45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 'Bakso Urat Komplit', 18000, 'makanan', true, '{BASE_URL}/product_bakso_mercon.jpg', '["Campur Mie & Bihun", "Bihun Saja", "Mie Kuning Saja"]', 4.8, 27),
('45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 'Mie Bakso Urat', 15000, 'makanan', true, '{BASE_URL}/product_mie_ayam.jpg', '["Pedas", "Sedang", "Kuah Bening"]', 4.6, 22);

-- ── STAN NASGOR & JUS (Spesialis Nasi Goreng & Jus Buah) ──
INSERT INTO public.products (operator_id, name, price, category, is_available, image_url, customizable_options, rating, total_reviews)
VALUES
('51325215-0176-4324-bb74-4e973bcfff13', 'Nasi Goreng Pedas Gila', 14000, 'makanan', true, '{BASE_URL}/product_nasi_goreng.jpg', '["Level 1", "Level 2", "Level 3 Gila", "Telur Ceplok (+Rp 3.000)"]', 4.7, 33),
('51325215-0176-4324-bb74-4e973bcfff13', 'Pisang Goreng Keju', 6000, 'camilan', true, '{BASE_URL}/product_pisang_keju.jpg', '["Cokelat Keju", "Keju Susu", "Original Crispy"]', 4.9, 45),
('51325215-0176-4324-bb74-4e973bcfff13', 'Tango Wafer Cokelat', 7000, 'camilan', true, '{BASE_URL}/product_tango_wafer.jpg', '["Wafer Cokelat", "Wafer Vanila"]', 4.5, 19),
('51325215-0176-4324-bb74-4e973bcfff13', 'Jus Alpukat Kocok', 8000, 'minuman', true, '{BASE_URL}/product_jus_alpukat.jpg', '["Susu Cokelat", "Susu Putih", "Gula Sedikit"]', 4.9, 57);
"""

sql_file = os.path.join(os.path.dirname(__file__), 'populate_real_food_products.sql')
with open(sql_file, 'w', encoding='utf-8') as f:
    f.write(sql_script)

print(f"  ✓ SQL Script berhasil dibuat di {sql_file}")

cmd = f'Get-Content -Raw "{sql_file}" | docker exec -i kantin_postgres psql -U postgres -d kantin_digital'
ps_res = subprocess.run(["powershell", "-Command", cmd], capture_output=True, text=True)
print(f"  ✓ Output Database: {ps_res.stdout.strip()}")
if ps_res.stderr:
    print(f"  ! Error: {ps_res.stderr.strip()}")

print("\n🎉 Selesai! Semua produk dan gambar makanan riil telah siap.")
