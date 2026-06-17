# 📱 Spesifikasi Desain UI/UX — Role: Orang Tua (Mobile App)

Dokumen ini mendefinisikan antarmuka pengguna (UI/UX) untuk **Aplikasi Mobile Orang Tua Siswa** dengan gaya **Minimalis Modern**, berorientasi pada **iOS Layout (Cupertino-style)**, serta terintegrasi langsung dengan fitur pemantauan aktivitas jajan, grafik pengeluaran, filter tanggal/bulan, pembatasan jajan harian, dan top-up saldo online.

---

## 1. Panduan Visual Umum (Branding & Design System)

*   **Tipografi**: Menggunakan **Be Vietnam Pro** (Regular, Medium, SemiBold, Bold) untuk menyelaraskan dengan estetika platform Kantin Digital yang modern dan bersih.
*   **Tema Warna**:
    *   *Primary Teal* (`#006767`): Warna utama navigasi, header, dan tindakan krusial.
    *   *Accent Orange* (`#904D00`): Penanda aksi top-up saldo online dan saldo aktif.
    *   *Success Green* (`#006A35`): Warna penanda transaksi sukses dan status saldo masuk.
    *   *System Background* (`#FBF9F8`): Warna abu-abu sangat hangat untuk latar belakang aplikasi.
    *   *Card Background* (`#FFFFFF`): Putih bersih untuk kontainer/card bento.
*   **Karakteristik Mobile Layout**:
    *   *Bento-Grid Card*: Tata letak kartu fungsional yang terpisah untuk menyajikan informasi ringkas dan cepat dipahami.
    *   *iOS Grab Handle* (`───`): Penarik bagian atas pada bottom sheet modal riwayat detail jajan.
    *   *Cupertino Segmented Control*: Tombol filter berbentuk pil menyatu secara horizontal untuk filter periode waktu (Hari, Minggu, Bulan).
    *   *Cupertino Switch*: Tombol toggle membulat untuk mengaktifkan batas jajan harian atau pembekuan kartu RFID anak.

---

## 2. Struktur Alur Layar (Sitemap Aplikasi)

```
[Splash / Portal NISN] ──> [Dashboard / Beranda (Tab 1)]
                             ├── [Layar Top-up Saldo] ──> [Midtrans Snap Webview]
                             ├── [Tab Analisis & Grafik (Tab 2)] ──> Filter (Hari/Minggu/Bulan/Kustom)
                             ├── [Tab Riwayat Jajan (Tab 3)] ──> Detail Transaksi (Bottom Sheet)
                             └── [Tab Pengaturan Saku & Keamanan (Tab 4)] ──> Set Limit & Bekukan Kartu
```

---

## 3. Spesifikasi Rinci Layar Demi Layar

### Screen 1: Portal Masuk NISN (Landing & Welcome)
Layar awal aplikasi bagi orang tua untuk memasukkan nomor identitas anak.
#### ASCII Mockup
```
+------------------------------------------+
|                                          |
|                 [🛜 + 💳]                 |
|              KANTIN DIGITAL              |
|          Portal Orang Tua Siswa          |
|                                          |
|       Pantau Jajanan & Saldo Anak        |
|        Secara Real-Time & Praktis        |
|                                          |
|    Masukkan NIS / Kode Unik Siswa        |
|    [ 20260012                        ]   |
|    ------------------------------------- |
|                                          |
|    [ CEK SALDO & AKTIVITAS ANAK ] (Teal) |
|                                          |
|    © 2024 Kantin Digital                 |
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Kolom "Masukkan NIS / Kode Unik Siswa"**: Input teks numerik yang secara otomatis menampilkan numpad di ponsel pintar.
*   **Tombol "CEK SALDO"**:
    *   *Aksi*: Melakukan verifikasi NISN ke database Supabase. Jika terdaftar, mengarahkan orang tua ke **Screen 2: Dashboard / Beranda**. Jika gagal, memunculkan teks error merah: *"NIS tidak terdaftar, silakan periksa kembali."*

---

### Screen 2: Dashboard / Beranda (Tab 1: Home)
Halaman depan yang menyajikan informasi profil siswa, sisa saldo saku aktif, dan pintasan cepat.
#### ASCII Mockup
```
+------------------------------------------+
|  Halo, Orang Tua Wali               [🔔]  |
|  Cek aktivitas anak Anda hari ini.       |
|                                          |
|  +------------------------------------+  |
|  |  PROFIL ANAK                       |  |
|  |  Ahmad Subarjo (Kelas 8-B)         |  |
|  |  SMP Terpadu Kota                  |  |
|  +------------------------------------+  |
|                                          |
|  +------------------------------------+  |
|  |  SALDO KANTIN AKTIF                |  |
|  |  Rp 75.000                         |  |
|  +------------------------------------+  |
|                                          |
|         [ ➕ TOP-UP ONLINE ] (Orange)     |
|                                          |
|  BATAS SAKU HARIAN                       |
|  Terpakai: Rp 12.000 / Rp 20.000 (Maks)  |
|  [||||||||||||||░░░░░░░░░] 60% Terpakai  |
|                                          |
|  AKTIVITAS TERAKHIR HARI INI             |
|  - Es Teh Manis         Rp  4.000  12:05 |
|  - Nasi Goreng          Rp 15.000  12:02 |
+------------------------------------------+
|  [Beranda]  [Analisis]  [Riwayat]  [Setting]
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Card Saldo Kantin Aktif**: Ditampilkan menonjol menggunakan font tebal oranye (`#904D00`).
*   **Batas Saku Harian Progress Bar**: Menunjukkan rasio konsumsi jajan anak hari ini terhadap limit harian yang ditentukan orang tua.
*   **Aksi Tombol Top-up**: Membuka **Screen 5: Layar Top-up Saldo**.
*   **Bottom Navigation Bar**: Menyediakan jalan pintas ke empat tab utama aplikasi.

---

### Screen 3: Analisis Grafik Jajan (Tab 2: Analisis)
Menyajikan statistik konsumsi jajanan anak secara visual menggunakan grafik kategori serta tren belanja.
#### ASCII Mockup
```
+------------------------------------------+
|  Analisis & Grafik Jajan                 |
|                                          |
|  [ Hari Ini | Minggu Ini | Bulan Ini | * ]  --> Segmented Control
|                                          |
|  Periode: 1 Juni 2026 - 17 Juni 2026     |
|  Total Belanja : Rp 145.000              |
|  Rata-rata/Hari: Rp 12.500               |
|                                          |
|  KATEGORI JAJAN PALING BANYAK            |
|  1. Makanan  55% [███████████░░░░░]      |
|  2. Minuman  30% [██████░░░░░░░░░░]      |
|  3. Camilan  15% [███░░░░░░░░░░░░░]      |
|                                          |
|  TREN JAJAN MINGGUAN (Rp)                |
|  50k|       █                            |
|  25k|   █   █   █                        |
|  10k| █ █ █ █ █ █ █                      |
|   0 +---------------------               |
|      S S R K J S M (Hari)                |
|                                          |
|  PRODUK TERFAVORIT ANAK                  |
|  - Es Teh Manis (Stan 2)    - 14x Beli   |
|  - Nasi Goreng (Stan 1)     -  8x Beli   |
+------------------------------------------+
|  [Beranda]  [Analisis]  [Riwayat]  [Setting]
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Segmented Control (Filter Waktu)**:
    *   *Hari Ini*: Analisis belanja khusus 24 jam terakhir.
    *   *Minggu Ini*: Analisis belanja berdasarkan hari berjalan (Senin-Minggu).
    *   *Bulan Ini*: Rekapitulasi penuh 1 bulan kalender terakhir.
    *   *Tombol Kustom (*)*: Membuka filter tanggal kustom (Date Range Picker).
*   **Grafik Kategori Jajan**: Diagram batang persentase horizontal yang membagi pengeluaran menjadi Makanan (Teal), Minuman (Orange), dan Camilan (Neutral Grey).
*   **Grafik Tren Jajan (Tren Mingguan)**: Grafik batang vertikal sederhana (Bar Chart) yang menunjukkan pengeluaran harian anak dalam satu minggu agar orang tua tahu hari apa anak paling boros.
*   **Daftar Produk Terfavorit**: Daftar produk yang paling sering dibeli beserta frekuensinya.

---

### Screen 4: Riwayat & Filter Lengkap (Tab 3: Riwayat)
Layar daftar riwayat transaksi terperinci dengan filter pencarian dan tipe aktivitas.
#### ASCII Mockup
```
+------------------------------------------+
|  Riwayat Aktivitas                       |
|  [🔍 Cari transaksi atau stan...       ]  |
|                                          |
|  FILTER TRANSAKSI                        |
|  Tipe   : [ Semua | Belanja | Top-up ]   |
|  Tanggal: [ 01 Jun 2026 - 17 Jun 2026 ]  |
|                                          |
|  HARI INI (17 Jun)                       |
|  ↓ Stan Bu Kantin            - Rp 19.000 |
|  ↑ Top-up Transfer Bank      + Rp 50.000 |
|                                          |
|  KEMARIN (16 Jun)                        |
|  ↓ Stan Minuman Segar        - Rp  4.000 |
|  ↓ Koperasi Buku             - Rp 12.000 |
+------------------------------------------+
|  [Beranda]  [Analisis]  [Riwayat]  [Setting]
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Filter Tanggal Kustom**: Orang tua dapat menekan tombol tanggal untuk memunculkan kalender ganda (Start Date & End Date).
*   **Filter Tipe Segment**: Memisahkan secara cepat antara dana keluar (Belanja) dan dana masuk (Top-up).
*   **Interaksi Item List**: Klik pada baris riwayat akan memicu pop-up Bottom Sheet iOS untuk menampilkan struk belanja detail (**Screen 7**).

---

### Screen 5: Layar Top-up Saldo Online
Formulir pembayaran mandiri untuk mengisi sisa uang saku anak.
#### ASCII Mockup
```
+------------------------------------------+
|  < Kembali                               |
|  Isi Saldo Saku Anak                     |
|                                          |
|  Penerima: Ahmad Subarjo (Kelas 8-B)     |
|                                          |
|  PILIH NOMINAL CEPAT                     |
|  [ Rp 10.000 ]       [ Rp 20.000 ]       |
|  [ Rp 50.000 ]       [ Rp 100.000 ]      |
|  [ Rp 200.000 ]      [ Rp 500.000 ]      |
|                                          |
|  NOMINAL KUSTOM                          |
|  Rp [ 35.000                         ]   |
|  --------------------------------------- |
|                                          |
|  METODE PEMBAYARAN VIA MIDTRANS          |
|  (o) QRIS (Gopay/OVO/ShopeePay)          |
|  ( ) Virtual Account Bank (BCA/Mandiri)  |
|                                          |
|  [ LANJUTKAN PEMBAYARAN ]                |
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Grid Nominal Cepat**: Tata letak grid 2x3 simetris, saat ditekan nominal otomatis masuk ke kolom input.
*   **Tombol "Lanjutkan Pembayaran"**: Membuka integrasi **Midtrans Snap Webview** secara modal/overlay di dalam aplikasi.

---

### Screen 6: Layar Pengaturan Saku (Tab 4: Settings)
Pengaturan batas pengeluaran harian dan keamanan kartu fisik RFID anak secara real-time.
#### ASCII Mockup
```
+------------------------------------------+
|  Batasan Saku & Keamanan                 |
|                                          |
|  KARTU AKTIF ANAK                        |
|  Nama : Ahmad Subarjo                    |
|  UID  : 04:A3:F8:12                      |
|                                          |
|  PENGATURAN LIMIT                        |
|  Batasi Jajan Harian                ( O) | --> Toggle Switch (ON)
|  Batas Maksimal Per Hari                 |
|  Rp [ 20.000                         ]   |
|  -------------------------------------   |
|                                          |
|  KEAMANAN KARTU                          |
|  Bekukan Kartu Sementara            (  ) | --> Toggle Switch (OFF)
|  (Nonaktifkan instan jika kartu hilang)  |
|                                          |
|  NOTIFIKASI WHATSAPP                     |
|  Kirim Notifikasi Jajan Real-time   ( O) | --> Toggle Switch (ON)
+------------------------------------------+
|  [Beranda]  [Analisis]  [Riwayat]  [Setting]
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Toggle "Batasi Jajan Harian"**:
    *   *Aksi*: Jika diaktifkan, memicu validasi limit belanja siswa pada database Supabase (`daily_limit`). Mesin POS kasir akan menolak transaksi jika belanja anak melampaui nominal limit ini.
*   **Toggle "Bekukan Kartu Sementara"**:
    *   *Aksi*: Jika diaktifkan, status kartu RFID berubah nonaktif seketika di database (`is_active = false`), mencegah kartu disalahgunakan jika terjatuh/hilang di lingkungan sekolah.
*   **Toggle "Notifikasi WhatsApp"**: Mengirim pesan notifikasi otomatis ke WA orang tua setiap kali kartu anak ditap di kantin.

---

### Screen 7: Detail Struk Transaksi (Bottom Sheet iOS Style)
Tampilan lembar bukti transaksi jajan terperinci.
#### ASCII Mockup
```
+------------------------------------------+
|                  ───                     |  --> Grab Handle
|             Detail Transaksi             |
|                                          |
|                ( Centang )               |
|             Transaksi Berhasil           |
|                                          |
|  ID Transaksi   : TX-2026061701          |
|  Waktu Tap      : 17 Jun 2026, 12:02     |
|  Lokasi Stan    : Stan Bude Sari         |
|                                          |
|  Rincian Item:                           |
|  - 1x Nasi Goreng             Rp 15.000  |
|  - 1x Es Teh Manis            Rp  4.000  |
|  --------------------------------------  |
|  Total Belanja  : Rp 19.000              |
|                                          |
|  Sisa Saldo Anak: Rp 75.000              |
|                                          |
|          [ UNDUH STRUK PDF ]             |
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **iOS Grab Handle**: Memberikan indikasi visual bahwa sheet dapat digeser ke bawah untuk ditutup.
*   **Tombol "Unduh Struk PDF"**: Mengunduh dan menyimpan struk pembelanjaan digital secara lokal di ponsel.
