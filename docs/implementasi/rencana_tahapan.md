# Rencana Tahapan Implementasi & Desain UI/UX

Dokumen ini berisi cetak biru arsitektur, sitemap, panduan visual, dan tahapan implementasi untuk proyek **Kantin Digital POS (Mobile App)** agar dapat dibaca, dipahami, dan dilanjutkan oleh agen AI lain atau pengembang.

---

## 🎨 1. Panduan Desain Visual (Design System)
Aplikasi ini dirancang dengan gaya **Minimalis Modern** yang berkiblat pada **iOS Layout (Cupertino-style)** dengan bahasa copywriting yang **sangat familiar bagi orang Indonesia (Indonesian Friendly)**.

*   **Tipografi**: `SF Pro Text` / `Inter` (Font sans-serif khas iOS yang bersih dan membulat).
*   **Warna Utama**:
    *   *Primary Teal* (`#0E8A8A`): Bersih dan profesional.
    *   *System Background* (`#F2F2F7`): Abu-abu sangat muda khas iOS.
    *   *Card Background* (`#FFFFFF`): Putih bersih untuk kontainer data.
    *   *Accent Orange* (`#FF9500`): iOS Orange untuk penanda top-up/keranjang.
    *   *System Red* (`#FF3B30`): iOS Red untuk pembatalan/error/keluar akun.
*   **Karakteristik iOS**:
    *   *Flat Minimalist Elements*: Tanpa bayangan tebal (elevation 0). Menggunakan garis tepi tipis (`border: 0.5px solid #E5E5EA`) dengan radius melengkung (`borderRadius: 12` hingga `16`).
    *   *iOS Grab Handle* (`───`): Strip pemandu di bagian atas untuk bottom sheet modal.
    *   *Cupertino Segmented Control*: Tab filter kategori berbentuk pil horizontal menyatu.
    *   *Cupertino Switch*: Toggle oval membulat untuk stok/freeze kartu.
*   **Istilah Lokal (Copywriting)**:
    *   "Isi Saldo", "Bekukan Kartu", "Riwayat Jajan", "Tambah Biaya Ekstra (Nasi/Sambal)", "Tap Kartu Siswa", "Cek Kartu", "Batal Transaksi / Refund".

---

## 🗺️ 2. Struktur Alur Layar (Sitemap)

```
[Login Screen / Masuk] ──> [POS Cashier Dashboard (Kasir)] ──> [Detail Keranjang] ──> [NFC Payment Modal]
                           ├── [Layar Cek Kartu Siswa] (Akses via Bottom Nav "Cek Kartu")
                           ├── [Katalog Menu CRUD] ──> [Form Tambah / Edit Produk]
                           └── [Riwayat Penjualan Stan] ──> [Refund Transaction]
```

---

## 🚀 3. Tahapan Pengembangan (Phases)

*   **Phase 1: Database Setup & Supabase Migrations** (Telah Selesai)
    *   Menyiapkan migrasi SQL awal, tabel-tabel utama, trigger otomatis, Row Level Security (RLS) policies, dan Stored Procedure transaksional (RPC).
*   **Phase 2: Core Setup & Visual Branding** (Telah Selesai)
    *   Inisialisasi dependensi Flutter (`supabase_flutter`, `go_router`, `flutter_riverpod`, `nfc_manager`, `google_fonts`), setup token warna, lokalisasi teks, tema dasar Material (Scaffold/AppBar flat), dan rute navigasi GoRouter.
*   **Phase 3: Aktor Autentikasi (Screen 1)** (Belum Selesai)
    *   Pengerjaan folder `features/auth/`, pembuatan halaman login kasir, dan integrasi session check Supabase Auth.
*   **Phase 4: POS Dashboard & Detail Keranjang (Screen 2 & 3)** (Belum Selesai)
    *   Pembuatan katalog POS grid, logic State Management keranjang belanja, halaman detail keranjang, dan dialog kustom biaya tambahan manual.
*   **Phase 5: Integrasi NFC & Transaksi Pembayaran (Screen 4)** (Belum Selesai)
    *   Integrasi plugin `nfc_manager` untuk membaca UID kartu, pemanggilan RPC `process_purchase` Supabase, getaran haptic sukses, dan modal status transaksi.
*   **Phase 6: Cek Kartu Siswa (Screen 5)** (Belum Selesai)
    *   Layar scan NFC mandiri dan layar hasil cek saldo/status kartu (Nama, Kelas, Status Aktif badge, Saldo besar teal) sesuai mockup visual.
*   **Phase 7: Kelola Jajanan CRUD (Screen 6 & 7)** (Belum Selesai)
    *   Manajemen menu stan (ketersediaan stok via Cupertino Switch), edit harga, dan form input jajanan baru (borderless input iOS).
*   **Phase 8: Rekap Penjualan & Refund (Screen 8)** (Belum Selesai)
    *   Rekap harian stan, daftar aktivitas penjualan, tombol refund (aktif < 10 menit), dan proses transaksi rollback saldo.
