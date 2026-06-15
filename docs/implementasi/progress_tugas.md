# Progress Lembar Kerja Tugas: Kantin Digital POS (Mobile App)

Dokumen ini memantau status penyelesaian setiap fitur pada proyek Kantin Digital POS agar agen berikutnya tahu status persis pengerjaan.

---

## 📊 Status Ringkas Progres
*   **Total Phase**: 8 Phase
*   **Selesai**: Phase 1, Phase 2, & Phase 3 (37.5% Selesai)
*   **Belum Mulai**: Phase 4 s/d Phase 8

---

## 📝 Detail Lembar Kerja Tugas

### [x] Phase 1: Database Setup & Supabase Migrations
*   [x] Membuat file migrasi SQL `supabase/migrations/20260615000000_init.sql`.
*   [x] Mendefinisikan tabel: `profiles`, `students`, `canteen_operators`, `products`, `transactions`, `transaction_items`, `notifications`.
*   [x] Menulis stored procedure `process_purchase` (SQL RPC) untuk transaksi potong saldo secara ACID.
*   [x] Menulis stored procedure `process_refund` (SQL RPC) untuk refund transaksi di bawah 10 menit.
*   [x] Mengaktifkan RLS (Row Level Security) dan membuat kebijakan keamanan (Policies) untuk tiap tabel.
*   [x] Menyiapkan trigger otomatis untuk sinkronisasi `profiles` saat user melakukan registrasi di auth.

### [x] Phase 2: Core Setup & Visual Branding (Design System)
*   [x] Inisialisasi dependensi di `pubspec.yaml` (`supabase_flutter`, `flutter_riverpod`, `go_router`, `nfc_manager`, `google_fonts`).
*   [x] Mengunduh dependensi (`flutter pub get`).
*   [x] Konfigurasi token warna iOS di `lib/core/constants/app_colors.dart`.
*   [x] Konfigurasi pelokalan istilah Indonesia di `lib/core/constants/app_strings.dart`.
*   [x] Inisialisasi tema global Material-App dengan font Inter di `lib/core/theme/app_theme.dart`.
*   [x] Setup GoRouter dengan 12 rute layar di `lib/core/router/app_router.dart`.
*   [x] Mengintegrasikan Supabase, Riverpod, Router, dan Tema di file masuk utama `lib/main.dart`.
*   [x] Melakukan audit kode (`flutter analyze`) dan memastikan **bebas dari error/warnings (No issues found!)**.

### [x] Phase 3: Aktor Autentikasi (Screen 1)
*   [x] Membuat folder dan struktur `lib/features/auth/`.
*   [x] Mendesain halaman Login Kasir minimalis.
*   [x] Integrasi session check dan autentikasi login via Supabase Auth.

### [ ] Phase 4: POS Dashboard & Detail Keranjang (Screen 2 & 3)
*   [ ] Membuat katalog POS dengan grid menu & segmented control kategori.
*   [ ] Implementasi state management (Riverpod) untuk keranjang belanja kasir.
*   [ ] Mendesain layar Detail Keranjang & dialog kustom biaya tambahan manual.

### [ ] Phase 5: Integrasi NFC & Transaksi Pembayaran (Screen 4)
*   [ ] Menghubungkan sensor `nfc_manager` untuk memindai kartu RFID/NFC.
*   [ ] Implementasi trigger pemrosesan transaksi belanja dengan RPC `process_purchase`.
*   [ ] Mendesain modal bottom sheet NFC dengan iOS Grab Handle.

### [ ] Phase 6: Cek Kartu Siswa (Screen 5)
*   [ ] Membuat modul scan kartu tanpa transaksi.
*   [ ] Mendesain layar Hasil Verifikasi Kartu sesuai mockup gambar (Nama, Kelas, Status badge, Saldo besar teal).

### [ ] Phase 7: Kelola Jajanan CRUD (Screen 6 & 7)
*   [ ] Membuat daftar kelola jajanan stan (Cupertino switch toggle stok).
*   [ ] Mendesain form input tambah/edit jajanan (borderless style iOS).

### [ ] Phase 8: Rekap Penjualan & Refund (Screen 8)
*   [ ] Menampilkan rekap harian stan & list aktivitas penjualan.
*   [ ] Implementasi logic hitung mundur 10 menit untuk refund transaksi.
*   [ ] Integrasi tombol refund dengan RPC `process_refund`.
