# 🗓️ Roadmap Pengembangan — Sistem Kantin Digital

Dokumen ini membagi proses pengembangan Sistem Kantin Digital berbasis Flutter dan Supabase ke dalam tiga fase utama dengan target mingguan (estimasi total waktu pengerjaan: 6-7 minggu).

---

## 9.1 Fase 1: Minimum Viable Product (MVP) — Minggu 1-3
*Fokus: Membangun pondasi sistem, skema database, autentikasi, dan alur transaksi tap inti.*

- [ ] **Setup Awal & Infrastruktur**
  - Inisialisasi repositori Git dan setup project Flutter.
  - Setup environment Supabase (Project, API Key, Database).
  - Integrasi dependensi utama (Riverpod, Supabase Flutter, nfc_manager).
- [ ] **Database & Keamanan**
  - Eksekusi DDL database (12 tabel, termasuk tabel `products` dan `transaction_items`).
  - Setup kebijakan Row Level Security (RLS) di Supabase.
  - Membuat trigger database untuk otomatisasi (misal update `updated_at` & `daily_summaries`).
- [ ] **Modul Autentikasi**
  - Implementasi register & login multi-aktor (Siswa, Petugas Kantin, Admin).
  - Proteksi rute navigasi berdasarkan role pengguna.
- [ ] **Fitur POS & Transaksi Tap (Mobile)**
  - Manajemen Produk: Layar tambah/edit/hapus produk oleh Petugas Kantin.
  - POS Checkout: Layar keranjang belanja (pilih produk makanan/minuman, tambah biaya kustom + catatan wajib).
  - Integrasi Pembaca NFC: Scan kartu siswa (`nfc_manager`) untuk memotong saldo sesuai keranjang belanja.
  - Layar riwayat transaksi sederhana untuk siswa.

---

## 9.2 Fase 2: Fitur Utama & Integrasi Eksternal — Minggu 3-5
*Fokus: Integrasi Payment Gateway (Midtrans), Dashboard Admin Web, dan Notifikasi.*

- [ ] **Integrasi Midtrans (Top-up Online)**
  - Konfigurasi akun Sandbox Midtrans.
  - Membuat Supabase Edge Functions untuk menangani pembuatan token bayar (Snap token) dan menerima HTTP POST Webhook dari Midtrans (notification handler).
  - Layar top-up online di aplikasi mobile siswa dan web publik orang tua.
- [ ] **Dashboard Web Admin (Super Admin & Admin Keuangan)**
  - Tampilan statistik perputaran saldo sekolah.
  - Manajemen CRUD Siswa, Petugas Kantin, dan Admin.
  - Modul input top-up tunai manual oleh Admin Keuangan.
  - Layar monitoring Audit Logs secara real-time untuk Super Admin.
- [ ] **Notifikasi Real-Time**
  - Integrasi Firebase Cloud Messaging (FCM) dengan Supabase.
  - Trigger pengiriman push notification setiap ada transaksi masuk/keluar ke HP siswa.

---

## 9.3 Fase 3: Pemolesan, Laporan, & Peluncuran — Minggu 5-7
*Fokus: Laporan keuangan, optimasi UI/UX, pengujian fungsionalitas penuh, dan deployment.*

- [ ] **Modul Pelaporan & Analytics**
  - Menghasilkan ringkasan laporan harian (`daily_summaries`).
  - Ekspor laporan transaksi (top-up & jajan) ke format PDF atau Excel dari Web Admin.
  - Grafik analisis pengeluaran siswa di aplikasi mobile.
- [ ] **Polish UI/UX & Feedback Haptic**
  - Penerapan micro-interactions dan getaran (haptic feedback) saat pembacaan NFC sukses/gagal di HP kasir.
  - Menyesuaikan visual aplikasi dengan panduan visual (Design Direction) termasuk efek kaca buram dan gradasi.
- [ ] **Pengujian Sistem & Bug Fixing**
  - Pengujian kompatibilitas pembacaan sensor NFC pada berbagai tipe HP Android kasir.
  - Simulasi pengujian transaksi simultan (stress test sederhana).
  - Perbaikan celah keamanan dan bug logika transaksi.
- [ ] **Deployment**
  - Build dan rilis aplikasi Flutter Mobile (.apk) untuk Android.
  - Deploy Flutter Web untuk Admin dan Landing Page Publik ke hosting (seperti Vercel / Netlify / Firebase Hosting).
