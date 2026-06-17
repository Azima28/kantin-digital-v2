# 🎨 Design Direction & Rancangan UI Per Role

Dokumen ini mendefinisikan panduan visual (design system), warna, tipografi, serta spesifikasi rinci untuk setiap layar/halaman (screens) yang disesuaikan berdasarkan **5 peran (role)** pengguna. Karena hak akses berbeda, setiap role memiliki layout dan fitur antarmuka yang sangat spesifik.

---

## 7.1 Panduan Visual (Design System)

### 1. Skema Warna (Color Tokens)
- **Primary Teal (`#0E8A8A`)**: Digunakan sebagai warna dominan pada tombol aksi utama, header dashboard, dan status sukses. Memberikan kesan aman, stabil, dan finansial terpercaya.
- **Accent Orange (`#F2994A`)**: Digunakan untuk tombol pembayaran, penanda nominal top-up, dan notifikasi penting. Memberikan kesan ramah, makanan hangat, dan aksi instan.
- **Surface Clean (`#F8F9FA` & `#FFFFFF`)**: Latar belakang putih gading dengan card putih bersih untuk kejelasan data.
- **Charcoal Text (`#1A1A1A`)**: Warna teks utama demi kontras dan keterbacaan tinggi.
- **Grey Text (`#7A7A7A`)**: Warna teks keterangan, tanggal, dan sub-informasi.

### 2. Tipografi (Poppins Font)
- **Heading 1 (26px, Bold)**: Nilai saldo, total kas, angka pendapatan.
- **Heading 2 (18px, SemiBold)**: Judul halaman, nama stan, header card.
- **Body Large (16px, Medium)**: Nama pengguna, label form input.
- **Body Regular (14px, Regular)**: Teks umum, nominal transaksi kecil, tombol standar.
- **Caption (12px, Light/Regular)**: Waktu transaksi (jam/tanggal), ID Transaksi, status log.

---

## 7.2 Rancangan Tampilan Halaman Per Role

Aplikasi ini dirancang dengan prinsip **"Satu Identitas Visual, Fungsi Berbeda"**. Semua role berbagi tema, warna, dan tipografi yang sama (sehingga terasa mirip sebagai satu kesatuan sistem Kantin Digital), namun memiliki struktur tata letak (layout) dan fokus interaksi yang berbeda menyesuaikan kebutuhan tugas masing-masing role.

### Perbandingan Karakteristik Antar Role:

| Aspek Desain | 📱 Siswa (Mobile) | 📱 Petugas Kantin (Mobile) | 🌐 Admin Keuangan (Web) | 📱 Super Admin (Mobile) |
|---|---|---|---|---|
| **Kemiripan (Branding)** | Teal & Orange accent, font Poppins, rounded card 16px | Teal & Orange accent, font Poppins, rounded card 16px | Teal & Orange accent, font Poppins, rounded card 8px | Teal & Orange accent, font Be Vietnam Pro, rounded card 24px |
| **Gaya Layout** | **Personal Dashboard** (Layout ala e-wallet personal, navigasi bottom bar) | **Cashier Terminal / POS** (Layout katalog produk grid besar, navigasi bottom bar) | **Admin Portal** (Layout sidebar navigasi kiri, tabel data, & dashboard metrik) | **Master Control Cockpit** (Layout dashboard ringkas, grafik tren & kontribusi, bottom bar) |
| **Fokus Utama Visual** | Saldo pribadi & riwayat konsumsi harian | Keranjang belanja, grid menu makanan, & area deteksi kartu | Formulir input top-up tunai, registrasi kartu, & tabel siswa | Tren transaksi global, donasi kontribusi harian, & log keamanan |
| **Interaksi Utama** | Membaca saldo, bayar top-up online via Midtrans | Memilih makanan, tambah biaya tambahan, scan NFC kartu siswa | Memasukkan NIS, memverifikasi uang fisik, cetak laporan | Memantau grafik volume harian, push broadcast alert, lock status |

---

## 7.2 Dokumen Spesifikasi UI Detail Per Role

Detail spesifikasi rancangan antarmuka pengguna (UI/UX) untuk setiap role telah dipisahkan ke dalam berkas-berkas tersendiri di bawah folder `design/`. Setiap berkas memuat struktur halaman (ASCII Mockup), daftar tombol beserta aksi kliknya, data dinamis yang ditampilkan, dan logic backend yang terlibat dari awal hingga akhir aplikasi.

Silakan pilih dokumen spesifikasi per role di bawah ini untuk ditinjau secara terperinci:

### 📱 A. Siswa (Aplikasi Mobile Android/iOS)
- **Spesifikasi Lengkap**: **[siswa-mobile.md](file:///c:/Work/Project%20PKL/sistem%20kantin%20digital/docs/perencanaan/design/siswa-mobile.md)**
- **Konten**: Halaman Login, Dashboard Saldo, Layar Pilihan Nominal & Pembayaran Online Midtrans, Riwayat & Detail Transaksi, Manajemen Link Kartu NFC, dan Form Edit Profil.

### 📱 B. Petugas Kantin / Kasir (Aplikasi Mobile POS)
- **Spesifikasi Lengkap**: **[petugas-kantin-mobile.md](file:///c:/Work/Project%20PKL/sistem%20kantin%20digital/docs/perencanaan/design/petugas-kantin-mobile.md)**
- **Konten**: Halaman Login Kasir, Katalog Produk & Keranjang Belanja (POS), Penambahan Biaya Kustom (Extra Portion) dengan Catatan Wajib, Modal Pemindaian NFC (Sukses/Saldo Kurang), Manajemen Menu Makanan (CRUD & Switch Stok), Riwayat Pendapatan, dan Refund Transaksi (maksimal 10 menit).

### 🌐 C. Admin Keuangan (Web Dashboard Sekolah)
- **Spesifikasi Lengkap**: **[admin-keuangan-web.md](file:///c:/Work/Project%20PKL/sistem%20kantin%20digital/docs/perencanaan/design/admin-keuangan-web.md)**
- **Konten**: Portal Login Admin Keuangan, Dashboard Kas Sekolah, Manajemen Siswa & Link Kartu via USB Reader, Form Input Top-up Tunai (Koperasi), Modul Koreksi Saldo (Adjustment) dengan input alasan wajib & catatan audit log otomatis, Laporan setoran per stan jajan, dan Export Excel/PDF.

### 📱 D. Super Admin (Aplikasi Mobile Master Control)
- **Spesifikasi Lengkap**: **[super-admin-mobile.md](file:///c:/Work/Project%20PKL/sistem%20kantin%20digital/docs/perencanaan/design/super-admin-mobile.md)**
- **Konten**: Login Biometrik & Master PIN, Dashboard Cockpit (Metrik Global, Area Chart Tren Transaksi, Donut Chart Kontribusi, status kesehatan server), CRUD data sekolah mitra, manajemen status akun user (aktif/blokir instan), Audit Log Explorer, Broadcast Center (Push Alert), dan Setelan Global API (FCM, Midtrans, Maintenance Mode).

### 🌐 E. Orang Tua (Web Publik Tanpa Login)
- **Spesifikasi Lengkap**: **[orang-tua-web.md](file:///c:/Work/Project%20PKL/sistem%20kantin%20digital/docs/perencanaan/design/orang-tua-web.md)**
- **Konten**: Portal pencarian NIS, Dashboard pantau saldo & 5 aktivitas jajan terakhir anak, Form input nominal top-up online instan, Pop-up Midtrans Snap, dan Download E-Receipt (PDF) Bukti Pembayaran Lunas.

---

---

## 7.3 Matriks Visibilitas Fitur Berdasarkan Layar Bersama

Pada layar yang secara visual mirip (seperti halaman Profil atau Layar Detail Transaksi), elemen UI akan disembunyikan/ditampilkan berdasarkan role:

| Layar Bersama | Elemen UI | Super Admin | Admin Keuangan | Petugas Kantin | Siswa | Orang Tua |
|---|---|:---:|:---:|:---:|:---:|:---:|
| **Detail Transaksi** | Tombol Refund | ❌ | ❌ | ✅ (max 10 menit) | ❌ | ❌ |
| **Detail Transaksi** | Nama Operator | ✅ | ✅ | ❌ | ✅ | ✅ |
| **Edit Profil** | Ubah NIS/ID | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Edit Profil** | Link Kartu NFC | ✅ | ✅ | ❌ | ✅ (via app) | ❌ |
| **Siswa List** | Tombol Adjust Saldo | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Siswa List** | Nilai Saldo | ✅ | ✅ | ✅ (hanya via tap) | ✅ (sendiri) | ✅ (sendiri) |
