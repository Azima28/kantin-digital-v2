# 📱 Spesifikasi Desain UI/UX — Role: Siswa (Mobile App)

Dokumen ini mendefinisikan antarmuka pengguna (UI/UX) untuk **Aplikasi Siswa (Mobile)** dengan mengusung gaya **Minimalis Modern**, berorientasi **iOS Layout (Cupertino-style)**, dan menggunakan pendekatan bahasa/konteks yang **sangat familiar bagi pengguna di Indonesia (Indonesian Friendly)**.

---

## 1. Panduan Visual Umum (Branding & Design System)

*   **Tipografi**: Menggunakan **SF Pro Text** / **Inter** (font sans-serif khas iOS yang membulat, bersih, dan modern).
*   **Tema Warna**:
    *   *Primary Teal* (`#0E8A8A`): Sebagai representasi warna kantin digital yang bersih dan modern.
    *   *System Background* (`#F2F2F7`): Warna latar belakang abu-abu sangat muda khas sistem iOS.
    *   *Card Background* (`#FFFFFF`): Putih bersih untuk membedakan kontainer data dengan latar belakang.
    *   *Accent Orange* (`#FF9500`): Warna oranye khas iOS untuk penanda top-up atau status penting yang menarik perhatian secara ramah.
    *   *System Red* (`#FF3B30`): Warna merah tegas untuk aksi berbahaya (seperti bekukan kartu/keluar akun).
*   **Karakteristik iOS (Cupertino Layout)**:
    *   *Large Navigation Title*: Judul halaman berukuran besar di sebelah kiri saat awal, yang mengecil ke tengah saat halaman di-scroll ke bawah.
    *   *Flat Minimalist Card*: Tidak menggunakan bayangan tebal. Desain mengandalkan border tipis (`border: 0.5px solid #E5E5EA`) dengan sudut melengkung halus (`borderRadius: 12` hingga `16`).
    *   *iOS Grab Handle* (`───`): Setiap komponen penarik/bottom sheet memiliki strip pegangan khas iOS di bagian atas modal.
    *   *Cupertino Segmented Control*: Tombol filter berbentuk pil yang menyatu secara horizontal.
    *   *Cupertino Switch*: Tombol toggle berbentuk oval membulat untuk pengaturan aktif/nonaktif.
*   **Lokalisasi Indonesia (Friendly Copywriting)**:
    *   Menghindari jargon bahasa Inggris yang kaku. Menggunakan sapaan ramah ("Halo, Ahmad!"), kata-kata operasional yang mudah dipahami ("Isi Saldo", "Riwayat Jajan", "Bekukan Kartu", "Ubah Password", "Keluar Akun").

---

## 2. Struktur Alur Layar (Sitemap)

```
[Splash Screen / Selamat Datang] ──> [Login Screen / Masuk] ──> [Dashboard / Beranda]
                                                               ├── [Layar Isi Saldo (Top-Up)] ──> [Midtrans Snap Webview]
                                                               ├── [Layar Riwayat Jajan] ──> [Detail Transaksi (Modal Bottom Sheet)]
                                                               ├── [Layar Manajemen Kartu]
                                                               ├── [Layar Profil Akun] ──> [Modal Ubah Password]
                                                               └── [Layar Kotak Masuk Notifikasi]
```

---

## 3. Spesifikasi Rinci Layar Demi Layar

### Screen 1: Splash & Welcome Screen
Tampilan pertama kali siswa membuka aplikasi yang menyambut pengguna secara minimalis.
#### ASCII Mockup
```
+------------------------------------------+
|                                          |
|                                          |
|                 [🛜 + 🍽️]               |
|              Kantin Digital              |
|                                          |
|           Mulai Jajan Praktis            |
|          Tanpa Uang Tunai Lagi           |
|                                          |
|                                          |
|                                          |
|            [ Mulai Sekarang ]            |
|                                          |
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Ikon & Nama App**: Ilustrasi minimalis piring makan digabung dengan sinyal nirkabel (NFC/NFC wave). Judul "Kantin Digital" menggunakan font *SF Pro Bold* 26px warna Teal (`#0E8A8A`).
*   **Sub-title**: "Mulai Jajan Praktis, Tanpa Uang Tunai Lagi" (Bahasa Indonesia santai, ramah).
*   **Tombol "Mulai Sekarang"**:
    *   *Desain*: Tombol solid Teal lebar penuh (flat), sudut membulat `borderRadius: 14`, tanpa bayangan.
    *   *Aksi*: Klik tombol langsung memicu transisi geser horizontal ke **Screen 2: Login Screen**.

---

### Screen 2: Login Screen (Masuk Akun)
Form masuk yang minimalis menggunakan NIS/Email siswa.
#### ASCII Mockup
```
+------------------------------------------+
|  < Kembali                               |
|                                          |
|  Yuk, Masuk!                             |
|  Silakan masuk ke akun kantin sekolahmu. |
|                                          |
|  Nomor Induk Siswa (NIS) / Email         |
|  [ ahmad.subarjo@sekolah.sch.id      ]   |
|  --------------------------------------- |
|  Kata Sandi                              |
|  [ ••••••••••••••                 ] [👁️]  |
|  --------------------------------------- |
|                                          |
|  [ MASUK ]                               |
|                                          |
|  Lupa sandi? Hubungi Koperasi Sekolah    |
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Tombol "< Kembali"**: Navigasi kembali ke Splash Screen.
*   **Gaya Form Entry**: Desain minimalis tanpa kotak kolom (borderless input fields), hanya garis tipis abu-abu (`#E5E5EA`) sebagai pembatas bawah layaknya form input iOS klasik.
*   **Aksi Tombol "MASUK"**:
    *   *Aksi*: Mengirim data input ke API Supabase. Jika berhasil, masuk ke Dashboard. Jika gagal, memicu notifikasi toast merah di bagian atas layar bertuliskan "NIS atau sandi salah, silakan cek kembali".

---

### Screen 3: Dashboard / Beranda
Layar utama yang ramah dan menonjolkan nominal sisa uang saku digital anak.
#### ASCII Mockup
```
+------------------------------------------+
|  Halo, Ahmad!                       [🔔]  |
|  Kelas 8-B • SMP Terpadu                 |
|                                          |
|  +------------------------------------+  |
|  |  SALDO SAKU                        |  |
|  |  Rp 75.000                         |  |
|  |  --------------------------------  |  |
|  |  Status Kartu: Aktif (✓)           |  |
|  +------------------------------------+  |
|                                          |
|    [ ➕ Isi Saldo ]     [ 🔒 Bekukan ]   |
|                                          |
|  Jajan Hari Ini                          |
|  - Es Teh Manis         Rp 4.000   12:05 |
|  - Nasi Goreng Komplit  Rp 15.000  12:02 |
|                                          |
|  [ Lihat Semua Riwayat ]                 |
+------------------------------------------+
|  [Beranda]    [Riwayat]    [Kartu]    [Akun] 
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Ikon Notifikasi `[🔔]`**: Ikon bel bersih di sudut kanan atas. Dilengkapi badge merah minimalis jika ada pesan/notifikasi masuk yang belum dibaca. Mengarah ke **Screen 9**.
*   **Card Saldo Saku**:
    *   *Desain*: Flat card putih dengan border sangat tipis teal, font nominal uang saku tebal dan besar (SF Pro Bold 28px).
*   **Tombol Pintasan Cepat**:
    *   **Isi Saldo**: Mengarahkan ke **Screen 4 (Top-Up)**.
    *   **Bekukan**: Membuka dialog konfirmasi minimalis untuk menghentikan akses kartu sementara jika hilang.
*   **Daftar "Jajan Hari Ini"**: List ringkas transaksi terakhir pada hari tersebut.
*   **Tombol "Lihat Semua Riwayat"**: Mengarahkan pengguna langsung ke tab Riwayat.

---

### Screen 4: Layar Isi Saldo (Top-Up Online)
Alur pengisian saldo mandiri secara digital yang sederhana dan cepat.
#### ASCII Mockup
```
+------------------------------------------+
|  < Kembali                               |
|  Isi Saldo                               |
|                                          |
|  PILIH NOMINAL CEPAT                     |
|  [ Rp 10.000 ]       [ Rp 20.000 ]       |
|  [ Rp 50.000 ]       [ Rp 100.000 ]      |
|                                          |
|  NOMINAL KUSTOM                          |
|  Rp [ 35.000                         ]   |
|  --------------------------------------- |
|                                          |
|  Metode: QRIS / Virtual Account (Instan)  |
|                                          |
|  [ LANJUTKAN PEMBAYARAN ]                |
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Pilih Nominal Cepat**: Grid 2x2. Kotak nominal yang dipilih akan berubah latar belakangnya menjadi Teal muda lembut dengan teks Teal tua tanpa bayangan tebal.
*   **Tombol "Lanjutkan Pembayaran"**: Memanggil integrasi Midtrans Snap API via Supabase Edge Function dan memunculkan *webview* snap secara modal.

---

### Screen 5: Layar Riwayat Jajan (History)
List aktivitas pengeluaran dan pemasukan saldo dengan format linear iOS.
#### ASCII Mockup
```
+------------------------------------------+
|  Riwayat Jajan                           |
|  [🔍 Cari nama stan jajan...          ]  |
|                                          |
|  [    Semua    |    Jajan    |   Top-Up  ]  | --> Segmented Ctrl
|                                          |
|  HARI INI (12 Jun)                       |
|  ↓ Stan Bude Sari            - Rp 12.000 |  --> Item list belanja
|  ↑ Top-up QRIS Midtrans      + Rp 50.000 |  --> Item list isi saldo
|                                          |
|  KEMARIN (11 Jun)                        |
|  ↓ Koperasi Sekolah          - Rp  8.500 |
+------------------------------------------+
|  [Beranda]    [Riwayat]    [Kartu]    [Akun] 
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Cupertino Segmented Control Filter**:
    *   *Desain*: Kontrol tersegmentasi berbentuk kapsul menyatu khas iOS. Tombol aktif berlatar belakang putih dengan pembungkus luar abu-abu muda (`#E5E5EA`).
*   **Item Riwayat**:
    *   Top-up ditandai tanda panah ke atas hijau (`↑`) dengan format teks berwarna hijau muda (`#34C759`).
    *   Jajan/Belanja ditandai tanda panah ke bawah hitam (`↓`) dengan format teks hitam gelap (`#1A1A1A`).
    *   Mengklik baris daftar akan membuka detail transaksi berupa modal iOS bottom sheet (**Screen 6**).

---

### Screen 6: Detail Transaksi Modal (Bottom Sheet iOS Style)
Modal slip pembayaran digital minimalis dari arah bawah layar dengan handle tarik.
#### ASCII Mockup
```
+------------------------------------------+
|                  ───                     |  --> iOS Grab Handle
|             Detail Transaksi             |
|                                          |
|                ( Centang )               |
|            Pembayaran Sukses             |
|                                          |
|  ID Transaksi    : TX-908129038          |
|  Waktu Tap       : 12 Jun 2026, 12:02    |
|  Lokasi Belanja  : Stan Bude Sari         |
|                                          |
|  Rincian Pembelian:                      |
|  - 1x Nasi Goreng             Rp 15.000  |
|  - 1x Es Teh Manis            Rp  4.000  |
|  - 1x Ekstra Telur (Kustom)   Rp  3.000  |
|  --------------------------------------  |
|  Total Potong Saldo: Rp 22.000           |
|                                          |
|            [ Simpan Struk PDF ]          |
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **iOS Grab Handle**: Garis strip horizontal abu-abu kecil di atas layar untuk menandakan sheet dapat ditarik ke bawah (slide down to dismiss).
*   **Simpan Struk PDF**: Mengunduh tanda bukti digital yang ramah cetak.

---

### Screen 7: Layar Manajemen Kartu
Kontrol penuh keamanan kartu fisik RFID siswa secara mandiri.
#### ASCII Mockup
```
+------------------------------------------+
|  Kartu Kantin                            |
|                                          |
|     +------------------------------+     |
|     |  Ahmad Subarjo               |     |  --> Visual Kartu Flat
|     |  Status Kartu: AKTIF         |     |
|     |  UID: 04:A3:F8:12            |     |
|     +------------------------------+     |
|                                          |
|  KEAMANAN KARTU                          |
|  Bekukan Sementara                  ( O) |  --> Cupertino Switch (ON)
|  Nonaktifkan sementara jika kartu hilang |
|                                          |
|  [ Hubungkan Kartu Baru via NFC ]        |
+------------------------------------------+
|  [Beranda]    [Riwayat]    [Kartu]    [Akun] 
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Cupertino Switch**:
    *   *Aksi*: Geser toggle untuk mematikan kartu seketika. Sistem akan meminta pin keamanan lalu mengupdate database Supabase (`is_active = false`) agar kartu tersebut tidak bisa di-tap kasir.
*   **Hubungkan Kartu Baru via NFC**: Menggunakan sensor pembaca NFC internal smartphone siswa untuk mendaftarkan kartu RFID baru secara mandiri.

---

### Screen 8: Layar Profil Akun
Menu akun terstruktur rapi dengan layout list-grouping khas Apple settings.
#### ASCII Mockup
```
+------------------------------------------+
|  Pengaturan Akun                         |
|                                          |
|  [ Profil Ringkas: Ahmad Subarjo ]       |
|  NIS: 20260012 • Kelas 8-B               |
|                                          |
|  KONTAK ORANG TUA                        |
|  Email : budi.subarjo@gmail.com          |
|  No. HP: 08123456789                     |
|                                          |
|  KEAMANAN & AKSES                        |
|  Ubah Sandi Akun                     [>] |
|  Keluar dari Akun (Merah)            [>] |
+------------------------------------------+
|  [Beranda]    [Riwayat]    [Kartu]    [Akun] 
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Indikator [>]**: Ikon panah chevron khas daftar iOS untuk memandu navigasi lanjutan.
*   **Keluar dari Akun**: Menggunakan warna merah tegas (`#FF3B30`) untuk menonjolkan aksi yang mereset status autentikasi.

---

### Screen 9: Layar Kotak Masuk Notifikasi
Tempat menyimpan riwayat pesan transaksi real-time yang bersih.
#### ASCII Mockup
```
+------------------------------------------+
|  < Beranda                               |
|  Kotak Masuk                             |
|                                          |
|  Hari Ini                                |
|  (✓) Jajan Berhasil                 12:05|
|      Nominal Rp 19.000 di Stan Bude Sari |
|                                          |
|  (+) Top-Up Saldo Sukses            10:15|
|      Nominal Rp 50.000 via QRIS          |
|                                          |
|  Kemarin                                 |
|  (i) Keamanan Akun                  08:30|
|      Kartu RFID Anda berhasil diaktifkan |
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Status Ikon**: Menggunakan penanda minimalis: checkmark `(✓)` warna hijau teal untuk jajan sukses, plus `(+)` warna orange untuk pengisian saldo, dan info `(i)` untuk berita sistem.
*   Menggunakan pembaruan data real-time melalui langganan Supabase Realtime Channels.
