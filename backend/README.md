# Kantin Digital v2.0 - Dedicated Backend (Golang & PostgreSQL)

Backend mandiri berkinerja tinggi berbasis **Golang (Go Fiber)** dan **PostgreSQL 16 Murni** untuk ekosistem **Kantin Digital v2.0 (Mobile APK & Web)**.

---

## 🚀 Fitur Utama Backend
- **ACID Transaction Engine**: Row-Level Locking (`SELECT ... FOR UPDATE`) untuk mencegah *double-spending* saldo siswa.
- **Single-Merchant Order Lifecycle**: Pengendalian pesanan online, multi-stall cart guard, notifikasi realtime.
- **WebSocket Realtime Hub**: Live alert pesanan baru untuk kasir POS dan update status ke siswa.
- **Media Upload Server**: Upload foto menu dan avatar dengan penyimpanan lokal disk cepat di `/uploads/`.
- **RBAC Security**: Role-based Access Control (`student`, `petugas_kantin`, `petugas_keuangan`, `parent`, `super_admin`) menggunakan stateless JWT.

---

## 🛠️ Cara Menjalankan dengan Docker Compose (Satu Perintah)

```bash
cd backend
docker-compose up -d
```

Server Go dan PostgreSQL 16 akan otomatis berjalan:
- **API URL**: `http://localhost:8080`
- **Health Check**: `http://localhost:8080/health`
- **WebSocket**: `ws://localhost:8080/ws?room=canteen:{id}`
- **Database**: `localhost:5432` (Database: `kantin_digital`, User: `postgres`, Pass: `postgrespassword`)

---

## 📡 Daftar Endpoint API Utama

### 1. Autentikasi (`/api/v1/auth`)
- `POST /api/v1/auth/login` — Login Siswa (NISN/Username), Kasir, Staf, Admin
- `GET /api/v1/auth/me` — Cek status profil login terautentikasi
- `POST /api/v1/auth/change-password` — Ganti kata sandi

### 2. Katalog & Menu (`/api/v1/canteens` & `/api/v1/products`)
- `GET /api/v1/canteens` — Daftar seluruh stan kantin aktif
- `GET /api/v1/products?category=...&canteenId=...` — Katalog menu makanan/minuman
- `POST /api/v1/pos/products` — Tambah menu (Khusus Kasir)
- `PUT /api/v1/pos/products/:id` — Edit menu (Khusus Kasir)
- `DELETE /api/v1/pos/products/:id` — Hapus menu (Khusus Kasir)
- `PATCH /api/v1/pos/delivery-settings` — Atur status aktif Delivery & tarif ongkir stan

### 3. Pemesanan Online (`/api/v1/orders`)
- `POST /api/v1/orders` — Siswa membuat pesanan makanan
- `GET /api/v1/orders/student` — Riwayat pesanan aktif siswa
- `GET /api/v1/orders/operator` — Daftar pesanan masuk ke dapur kasir
- `PATCH /api/v1/orders/:id/status` — Ubah status (*Baru -> Sedang Dimasak -> Siap Diantar/Diambil -> Selesai*)
- `POST /api/v1/orders/:id/messages` — Kirim chat pesan order
- `GET /api/v1/orders/:id/messages` — Ambil percakapan order

### 4. Kasir POS & Kartu RFID (`/api/v1/pos`)
- `GET /api/v1/pos/scan-card?rfid=...` — Tap/Scan UID kartu RFID siswa
- `POST /api/v1/pos/checkout` — Transaksi instan kasir pemotongan saldo (ACID)
- `GET /api/v1/pos/sales-history` — Riwayat omzet kasir stan

### 5. Siswa & Keuangan (`/api/v1/student` & `/api/v1/finance`)
- `GET /api/v1/student/me` — Info saldo dan kartu siswa
- `GET /api/v1/student/transactions` — Buku besar riwayat jajan
- `GET /api/v1/student/notifications` — Notifikasi transaksi & pesanan
- `POST /api/v1/finance/topup` — Top-up saldo siswa oleh petugas keuangan

### 6. Upload Media (`/api/v1/upload`)
- `POST /api/v1/upload/product-image` — Upload foto makanan (Multipart Form)
- `POST /api/v1/upload/avatar` — Upload foto profil pengguna
- `GET /uploads/products/:filename` — Akses file gambar publik langsung
