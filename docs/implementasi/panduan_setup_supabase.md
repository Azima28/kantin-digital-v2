# Panduan Langkah Demi Langkah Setup Supabase

Ikuti panduan berikut untuk menyiapkan database dan autentikasi Supabase Anda agar terhubung dengan aplikasi **Kantin Digital POS**.

---

## 🛠️ Langkah 1: Buat Proyek di Supabase
1.  Buka browser dan masuk ke [supabase.com](https://supabase.com/).
2.  Masuk (*Sign In*) menggunakan akun GitHub Anda.
3.  Di halaman dashboard, klik tombol **New Project**.
4.  Pilih Organisasi Anda, lalu isi formulir proyek:
    *   **Name**: `Kantin Digital` (atau nama lain bebas).
    *   **Database Password**: Buat password yang kuat (simpan password ini).
    *   **Region**: Pilih wilayah terdekat (disarankan **Singapore** untuk kecepatan akses terbaik).
5.  Klik **Create new project** dan tunggu beberapa menit hingga proses penyusunan server database selesai.

---

## 💾 Langkah 2: Jalankan Migrasi SQL
1.  Buka file migrasi SQL lokal proyek di [20260615000000_init.sql](file:///C:/Work/Project%20PKL/sistem%20kantin%20digital/supabase/migrations/20260615000000_init.sql).
2.  **Salin seluruh kode SQL** di dalamnya (`Ctrl + A` lalu `Ctrl + C`).
3.  Kembali ke browser Supabase Dashboard proyek Anda.
4.  Klik menu **SQL Editor** pada sidebar kiri (ikon lembar kertas dengan teks SQL).
5.  Klik **New query** (atau tombol `+`), lalu **tempelkan (*paste*)** seluruh kode SQL yang telah disalin.
6.  Klik tombol **Run** di pojok kanan bawah (atau tekan tombol pintas `Ctrl + Enter` / `Cmd + Enter`).
7.  Pastikan muncul notifikasi hijau berisi teks **"Success. No rows returned"**. Seluruh tabel, trigger, kebijakan keamanan (RLS), dan stored procedure kini telah aktif di database online Anda.

---

## 🔒 Langkah 3: Nonaktifkan Verifikasi Email (Untuk Pengembangan)
Secara default, Supabase mewajibkan verifikasi tautan email saat mendaftarkan akun baru. Untuk memudahkan proses uji coba lokal:
1.  Buka menu **Authentication** di sidebar kiri.
2.  Pilih menu tab **Providers** di bagian atas, lalu klik **Email**.
3.  Matikan toggle **Confirm email** (menjadi tidak aktif).
4.  Klik **Save** di pojok bawah.

---

## 🗝️ Langkah 4: Hubungkan Aplikasi Flutter dengan Supabase
1.  Buka menu **Project Settings** (ikon roda gigi ⚙️ di pojok kiri bawah dashboard Supabase).
2.  Pilih tab **API** pada submenu pengaturan.
3.  Salin parameter berikut:
    *   **Project URL**: (contoh: `https://xxxx.supabase.co`)
    *   **anon public Key** (publishable key): (kunci string panjang)
4.  Buka file proyek Flutter di [main.dart](file:///C:/Work/Project%20PKL/sistem%20kantin%20digital/lib/main.dart#L12-L15) dan ganti url placeholder dengan kunci riil Anda:
    ```dart
    await Supabase.initialize(
      url: 'MASUKKAN_URL_PROYEK_ANDA_DISINI',
      publishableKey: 'MASUKKAN_ANON_PUBLIC_KEY_ANDA_DISINI',
    );
    ```
    *Atau Anda dapat menjalankannya langsung via CLI terminal:*
    ```bash
    flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co --dart-define=SUPABASE_ANON_KEY=kunci_anon_anda
    ```

---

## 👥 Langkah 5: Cara Membuat Akun Uji Coba Kasir (Petugas Kantin)
Karena sistem RLS memblokir akses login kasir kecuali jika role pengguna diatur khusus sebagai `'petugas_kantin'`, lakukan langkah berikut untuk membuat akun uji coba pertama kali:

1.  Masuk ke menu **Authentication** ➔ **Users** di dashboard Supabase.
2.  Klik tombol **Add user** di pojok kanan atas, lalu pilih **Create user**.
3.  Masukkan Email kasir (contoh: `budesari.stan@sekolah.sch.id`) dan Kata Sandi baru. Klik **Save**.
4.  Secara otomatis, trigger database kita akan mendaftarkan profil pengguna tersebut ke tabel `public.profiles` dengan role default `'student'`.
5.  Untuk mengubah role-nya menjadi kasir petugas kantin, masuk ke menu **SQL Editor**, buat query baru, dan jalankan perintah update berikut:
    ```sql
    -- 1. Mengubah role menjadi petugas_kantin agar bisa login kasir
    UPDATE public.profiles
    SET role = 'petugas_kantin', full_name = 'Bude Sari'
    WHERE email = 'budesari.stan@sekolah.sch.id';

    -- 2. Mengubah nama stan kantin kasir terkait
    UPDATE public.canteen_operators
    SET canteen_name = 'Warung Bude Sari'
    WHERE id = (SELECT id FROM public.profiles WHERE email = 'budesari.stan@sekolah.sch.id');
    ```
6.  Akun kasir **`budesari.stan@sekolah.sch.id`** kini siap digunakan untuk masuk ke aplikasi mobile POS Kantin Digital!
