# 🤖 Panduan Membaca Mandiri untuk Agen AI (Self-Learning Agent Guide)

Selamat datang di proyek **Kantin Digital POS**. Proyek ini adalah aplikasi kasir mobile untuk stan kantin sekolah berbasis Flutter dan Supabase dengan sistem pembayaran tap kartu RFID/NFC.

Gunakan dokumen ini untuk mempelajari struktur, aturan desain, skema database, dan status pengerjaan proyek saat ini secara otomatis (*self-learning*).

---

## 📂 1. Peta Navigasi Dokumentasi (Documentation Navigation)
Sebelum Anda menulis kode atau melakukan modifikasi, bacalah dokumen pendukung berikut di dalam folder `docs/`:
1.  **Overview Proyek**: [01-overview.md](file:///C:/Work/Project%20PKL/sistem%20kantin%20digital/docs/perencanaan/01-overview.md)
2.  **Rencana Tahapan & Branding**: [rencana_tahapan.md](file:///C:/Work/Project%20PKL/sistem%20kantin%20digital/docs/implementasi/rencana_tahapan.md)
3.  **Rincian Database**: [db_schema_details.md](file:///C:/Work/Project%20PKL/sistem%20kantin%20digital/docs/implementasi/db_schema_details.md)
4.  **Log Solusi Perbaikan**: [catatan_perbaikan.md](file:///C:/Work/Project%20PKL/sistem%20kantin%20digital/docs/implementasi/catatan_perbaikan.md)
5.  **Daftar Progres Lembar Kerja**: [progress_tugas.md](file:///C:/Work/Project%20PKL/sistem%20kantin%20digital/docs/implementasi/progress_tugas.md)
6.  **Migrasi SQL Supabase**: [20260615000000_init.sql](file:///C:/Work/Project%20PKL/sistem%20kantin%20digital/supabase/migrations/20260615000000_init.sql)

---

## 🛠️ 2. Aturan Tumpukan Teknologi & Arsitektur
*   **Aplikasi Mobile**: Flutter (SDK ^3.9.2), pola manajemen state menggunakan `flutter_riverpod`, navigasi menggunakan `go_router` deklaratif, serta sensor RFID/NFC diatur melalui plugin `nfc_manager`.
*   **Arsitektur Kode**: Pendekatan **Feature-First** (fitur dipisah per folder di bawah `lib/features/`, contoh: `auth`, `pos`, `jajanan`, `cek_kartu`, `riwayat`). Logika global dan utilitas berada di `lib/core/`.
*   **Database & Backend**: Supabase. Semua inisialisasi awal klien berada di [main.dart](file:///C:/Work/Project%20PKL/sistem%20kantin%20digital/lib/main.dart).

---

## 🎨 3. Aturan Desain Visual (Design Coding Rules)
Patuhi aturan berikut demi menjaga konsistensi antarmuka minimalis khas iOS:
1.  **Jangan gunakan widget `CupertinoPageScaffold` secara langsung** tanpa pembungkus `Material` atau DefaultTextStyle di bawah `MaterialApp`. Hal ini akan menyebabkan error rendering teks berwarna merah dengan garis bawah ganda kuning. Gunakan widget **`Scaffold`** dan **`AppBar`** Material yang sudah kita konfigurasikan dengan desain iOS flat (tanpa bayangan, *centered title*) di [app_theme.dart](file:///C:/Work/Project%20PKL/sistem%20kantin%20digital/lib/core/theme/app_theme.dart).
2.  **Konfigurasi Warna**: Gunakan secara ketat token warna yang didefinisikan pada [app_colors.dart](file:///C:/Work/Project%20PKL/sistem%20kantin%20digital/lib/core/constants/app_colors.dart). Jangan menulis kode warna kustom (*hardcoded color*) baru.
3.  **Teks Lokalisasi**: Seluruh string UI untuk tombol, label, dan notifikasi wajib merujuk pada kelas konstanta [app_strings.dart](file:///C:/Work/Project%20PKL/sistem%20kantin%20digital/lib/core/constants/app_strings.dart).
4.  **Bentuk Kartu**: Kartu katalog jajanan wajib menggunakan radius `16`, `elevation: 0` (flat), dan garis tepi tipis `0.5px` warna `AppColors.borderLight`.

---

## 🔒 4. Aturan Keamanan & Transaksi Database
*   **Double Spend Prevention**: Seluruh transaksi pemotongan saldo belanja **TIDAK BOLEH** dilakukan menggunakan query modifikasi database biasa di sisi Flutter (seperti langsung memanggil `supabase.from('students').update(...)`).
*   **Prosedur RPC**: Anda **wajib** memanggil Stored Procedure PostgreSQL transaksional melalui Supabase RPC:
    *   Untuk checkout belanja: Panggil RPC **`process_purchase`** (otomatis mengunci baris murid, memotong saldo, mencatat transaksi dan item detail, serta meluncurkan notifikasi belanja secara ACID).
    *   Untuk pembatalan jajan/refund: Panggil RPC **`process_refund`** (otomatis mengembalikan saldo dan membatalkan transaksi hanya jika dilakukan dalam batas waktu 10 menit).
*   **Row Level Security (RLS)**: Pastikan RLS aktif. Semua query dari Flutter akan dievaluasi berdasarkan token otorisasi pengguna (`auth.uid()`).

---

## 🎯 5. Status Tugas Selanjutnya (Next Action Items)
Status saat ini telah menyelesaikan **Phase 1** & **Phase 2**. Tugas selanjutnya yang harus Anda kerjakan adalah **Phase 3 (Aktor Autentikasi)**:
1.  Buka folder [lib/features/](file:///C:/Work/Project%20PKL/sistem%20kantin%20digital/lib/features) dan buat direktori `auth/` (berisi subdirectory `screens`, `providers`, `services`).
2.  Desain layar masuk kasir minimalis (iOS-style borderless input fields) sesuai spesifikasi `petugas-kantin-mobile.md` Screen 1.
3.  Hubungkan form masuk dengan autentikasi Supabase `signInWithPassword()`. Validasi role kasir untuk mencegah user non-petugas masuk, kemudian arahkan ke rute `posHome` menggunakan GoRouter.
4.  Setelah selesai, perbarui lembar progres tugas di [progress_tugas.md](file:///C:/Work/Project%20PKL/sistem%20kantin%20digital/docs/implementasi/progress_tugas.md).
