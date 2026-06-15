# 📱 Spesifikasi Desain UI/UX — Role: Petugas Kantin (Mobile POS App)

Dokumen ini mendefinisikan antarmuka pengguna (UI/UX) untuk **Aplikasi Petugas Kantin / Kasir (Mobile POS)** dengan konsep **Minimalis Modern**, berorientasi **iOS Layout (Cupertino-style)**, dan disesuaikan secara khusus agar **sangat mudah dipahami oleh orang Indonesia (Indonesian Friendly)**.

---

## 1. Panduan Visual Umum (Branding & Design System)

*   **Tipografi**: Menggunakan **SF Pro Text** / **Inter** (font sans-serif khas iOS yang membulat, bersih, dan modern).
*   **Tema Warna**:
    *   *Primary Teal* (`#0E8A8A`): Warna utama kasir yang melambangkan kebersihan dan profesionalitas digital.
    *   *System Background* (`#F2F2F7`): Warna latar belakang abu-abu sangat muda khas sistem iOS.
    *   *Card Background* (`#FFFFFF`): Putih bersih untuk membedakan kontainer katalog dan daftar barang belanja.
    *   *Accent Orange* (`#FF9500`): Warna oranye khas iOS untuk penanda keranjang belanja, peringatan saldo kurang, atau aksi top-up.
    *   *System Red* (`#FF3B30`): Warna merah tegas untuk pembatalan transaksi (refund) atau status error.
*   **Karakteristik iOS (Cupertino Layout)**:
    *   *Large Navigation Title*: Judul halaman besar di sebelah kiri ("Kasir POS", "Riwayat Jualan") yang bergeser ke tengah saat di-scroll.
    *   *Flat Minimalist Elements*: Tanpa bayangan tebal (elevation 0). Komponen menggunakan pembatas garis tipis (`border: 0.5px solid #E5E5EA`) dengan radius melengkung halus (`borderRadius: 12` hingga `16`).
    *   *iOS Grab Handle* (`───`): Strip tipis pemandu penarikan di bagian atas untuk semua bottom sheet modal.
    *   *Cupertino Segmented Control*: Tab filter kategori menu berbentuk pil menyatu secara horizontal.
*   **Lokalisasi Indonesia (Friendly Copywriting)**:
    *   Menggunakan istilah lokal kasir indonesia: "Kasir", "Jajanan", "Keranjang Belanja", "Porsi Ekstra", "Tap Kartu Siswa", "Cek Kartu", "Kelola Menu", "Batal Transaksi / Refund".

---

## 2. Struktur Alur Layar (Sitemap)

```
[Login Screen / Masuk] ──> [POS Cashier Dashboard (Kasir)] ──> [Detail Keranjang] ──> [NFC Payment Modal]
                           ├── [Layar Cek Kartu Siswa] (Akses via Bottom Nav "Cek Kartu")
                           ├── [Katalog Menu CRUD] ──> [Form Tambah / Edit Produk]
                           └── [Riwayat Penjualan Stan] ──> [Refund Transaction]
```

---

## 3. Spesifikasi Rinci Layar Demi Layar

### Screen 1: Login Screen (Masuk Operator Kasir)
Form login khusus untuk akun pemilik stan kantin sekolah.
#### ASCII Mockup
```
+------------------------------------------+
|  Kantin Digital Kasir                    |
|                                          |
|  Yuk, Masuk Kasir!                       |
|  Silakan masuk ke akun stan kantin Anda. |
|                                          |
|  Email Akun Stan                         |
|  [ budesari.stan@sekolah.sch.id      ]   |
|  --------------------------------------- |
|  Kata Sandi                              |
|  [ ••••••••••••••                 ] [👁️]  |
|  --------------------------------------- |
|                                          |
|  [ MASUK KASIR ]                         |
|                                          |
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Gaya Form**: Desain minimalis flat borderless klasik iOS.
*   **Tombol "MASUK KASIR"**: Memicu autentikasi Supabase. Jika role user bukan `petugas_kantin`, otomatis dibatalkan dengan pemberitahuan "Akses ditolak, ini bukan akun petugas".

---

### Screen 2: POS Cashier Dashboard (Katalog & Keranjang)
Tampilan katalog jajanan stan untuk memasukkan barang ke keranjang kasir.
#### ASCII Mockup
```
+------------------------------------------+
|  WARUNG BUDE SARI                        |
|  Pendapatan Hari Ini: Rp 320.000         |
|                                          |
|  [    Semua    |   Makanan   |  Minuman  ]  | --> Segmented Ctrl
|                                          |
|  +------------------+  +-----------------+  |
|  | Nasi Goreng      |  | Mie Ayam        |  |  --> Grid Menu Flat
|  | Rp 15.000    [+] |  | Rp 12.000    [+] |  |
|  +------------------+  +-----------------+  |
|  | Es Teh Manis     |  | Air Mineral     |  |
|  | Rp 4.000     [+] |  | Rp 3.000     [+] |  |
|  +------------------+  +-----------------+  |
|                                          |
|  [ Keranjang: 2 Jajanan - Rp 19.000  [>] ]  --> Floating Cart Bar
+------------------------------------------+
| [Kasir]  [Cek Kartu]  [Menu]  [Riwayat]   |  --> Bottom Navigation Bar
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Cupertino Segmented Control**: Untuk menyortir menu (Semua, Makanan, Minuman) dengan indikator aktif berlatar putih.
*   **Grid Menu Flat**: Kartu produk minimalis berlatar putih dengan border sangat tipis abu-abu (`#E5E5EA`). Tombol `[+]` berukuran pas untuk jempol kasir.
*   **Floating Cart Bar**: Bar oranye minimalis melayang di atas navigasi bar untuk mengantar kasir ke **Screen 3 (Detail Keranjang)**.
*   **Bottom Navigation Bar (iOS Standard)**:
    *   *Kasir*: Layar POS Dashboard aktif saat ini.
    *   *Cek Kartu*: Menuju **Screen 5 (Layar Cek Kartu Siswa)**.
    *   *Menu*: Menuju **Screen 6 (Katalog Menu CRUD)**.
    *   *Riwayat*: Menuju **Screen 8 (Riwayat Penjualan Stan)**.

---

### Screen 3: Detail Keranjang & Tambah Biaya Manual
Layar review item belanjaan kasir sebelum tap kartu pembayaran.
#### ASCII Mockup
```
+------------------------------------------+
|  < Kasir                                 |
|  Keranjang Belanja                       |
|                                          |
|  Daftar Belanja:                         |
|  - 1x Nasi Goreng Komplit    Rp 15.000   |
|    [-]  1  [+]  [Hapus]                  |
|  - 1x Es Teh Manis           Rp  4.000   |
|    [-]  1  [+]  [Hapus]                  |
|                                          |
|  [ ➕ Tambah Biaya Ekstra (Nasi/Sambal) ] |  --> Tambah Biaya Manual
|                                          |
|  Total Belanja: Rp 19.000                |
|                                          |
|  [ PROSES TAP KARTU SISWA ]              |  --> Tombol Orange
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Tambah Biaya Ekstra**: Membuka modal pop-up minimalis untuk memasukkan nominal kustom (misal: tambahan porsi ekstra nasi) dengan catatan wajib yang mudah dipahami.
*   **PROSES TAP KARTU SISWA**: Membuka modal tap kartu pembayaran (**Screen 4**).

---

### Screen 4: NFC Payment Modal (Pemindaian & Pemotongan Saldo)
Layar bottom sheet pemindaian kartu RFID/NFC dan verifikasi transaksi.
#### ASCII Mockup
```
+------------------------------------------+
|                  ───                     |  --> iOS Grab Handle
|  Total Pembayaran: Rp 22.000             |
|                                          |
|  +------------------------------------+  |
|  |           SIAP MEMINDAI            |  |  --> Area Deteksi NFC
|  |                                    |  |
|  |      Tempelkan Kartu Siswa...      |  |
|  |               (( 🛜 ))             |  |
|  +------------------------------------+  |
|                                          |
|  Status: Menunggu Tap Kartu...           |
+------------------------------------------+
```
#### Alur & Transaksi Layar
*   **Fase A: Menunggu Tap**: Sensor NFC aktif mendeteksi kartu.
*   **Fase B: Konfirmasi Potong Saldo (Saldo Cukup)**:
```
+------------------------------------------+
|                  ───                     |
|  Konfirmasi Transaksi                    |
|                                          |
|  Siswa  : Ahmad Subarjo (Kelas 8-B)      |
|  Saldo  : Rp 75.000                      |
|  Bayar  : Rp 22.000                      |
|  Sisa   : Rp 53.000                      |
|                                          |
|  [ KONFIRMASI BAYAR ] (Teal)             |
+------------------------------------------+
```
*   **Fase C: Saldo Tidak Cukup (Ditolak)**:
```
+------------------------------------------+
|                  ───                     |
|  Transaksi Ditolak                       |
|  (Saldo Tidak Cukup)                     |
|                                          |
|  Siswa  : Siti Aminah (Kelas 7-A)        |
|  Saldo  : Rp 15.000                      |
|  Bayar  : Rp 22.000                      |
|  Kurang : -Rp 7.000 (Teks Merah)         |
|                                          |
|  [ SALDO TIDAK CUKUP ] (Disabled Grey)   |
+------------------------------------------+
```

---

### Screen 5: Layar Cek Kartu Siswa (Cek Saldo & Status)
Layar minimalis khusus untuk mengecek sisa saldo dan status keaktifan kartu siswa tanpa transaksi.

#### A. Fase Pindai (Scan NFC)
##### ASCII Mockup
```
+------------------------------------------+
|  Kantin Digital Kasir                 ⚙️  |
|                                          |
|  +------------------------------------+  |
|  |            SIAP MEMINDAI            |  |  --> Area Deteksi NFC
|  |                                    |  |
|  |      Tempelkan Kartu Siswa...      |  |
|  |               (( 🛜 ))             |  |
|  +------------------------------------+  |
|                                          |
|  Status: Menunggu Kartu Siswa...         |
+------------------------------------------+
| [Kasir]  [Cek Kartu]  [Menu]  [Riwayat]   |
+------------------------------------------+
```

#### B. Fase Hasil Verifikasi (Tampilan Minimalis Sesuai Gambar)
##### ASCII Mockup
```
+------------------------------------------+
|  (Chef) Kantin Digital Kasir          ⚙️  |
|                                          |
|                   _ _                    |
|                 /     \                  |
|                |   ✔   |                 |
|                 \ _ _ /                  |
|                                          |
|  +------------------------------------+  |
|  |        Pengecekan Berhasil         |  |
|  |    Kartu pelajar terverifikasi     |  |
|  |                                    |  |
|  |  Nama Siswa       Ahmad Subarjo    |  |
|  |  ------------------------------    |  |
|  |  Kelas                      8-B    |  |
|  |  ------------------------------    |  |
|  |  Status Kartu           [ AKTIF ]  |  |
|  |                                    |  |
|  |           Saldo Tersedia           |  |
|  |             Rp 75.000              |  |
|  +------------------------------------+  |
|                                          |
|  [ ← KEMBALI KE SCAN ]                   |
+------------------------------------------+
```
##### Elemen & Aksi Interaksi
*   **Header App Bar**: Teks "Kantin Digital Kasir" dengan ilustrasi koki di sebelah kiri dan tombol pengaturan `⚙️` di sebelah kanan.
*   **Ikon Status Sukses**: Lingkaran hijau tua berisi tanda centang (`✔`) sebagai indikator visual utama bahwa verifikasi NFC berhasil.
*   **Card Kontainer Utama**: Berwarna latar belakang putih (`#FFFFFF`) dengan efek bayangan halus (elevation 0) dan sudut melengkung 16px dengan border tipis `#E5E5EA`.
    *   **Judul Card**: Teks "Pengecekan Berhasil" (SF Pro Bold 18px).
    *   **Sub-judul Card**: Teks "Kartu pelajar terverifikasi" (SF Pro Regular 12px, warna abu-abu `#828282`).
    *   **Tabel Data Siswa**:
        *   Baris 1: Label "Nama Siswa" (warna abu-abu) dengan nilai "Ahmad Subarjo" (SF Pro Bold 14px, warna `#1A1A1A`).
        *   Baris 2: Label "Kelas" dengan nilai "8-B" (SF Pro Bold 14px).
        *   Baris 3: Label "Status Kartu" dengan nilai badge/chip oval berwarna Teal muda bertuliskan "AKTIF" (teks putih, background `#0E8A8A`).
    *   **Teks "Saldo Tersedia"**: Diposisikan di tengah, ukuran 11px, warna abu-abu.
    *   **Nominal Saldo**: Teks "Rp 75.000" berukuran besar (SF Pro Bold 24px), berwarna hijau teal tua (`#0E8A8A`) untuk kemudahan keterbacaan.
*   **Tombol "← KEMBALI KE SCAN"**: Tombol lebar penuh (full-width) di bagian bawah layar berwarna Teal solid (`#0E8A8A`) dengan teks putih dan ikon panah kiri, yang mengembalikan aplikasi ke fase memindai kartu (Fase A).

---

### Screen 6: Katalog Menu CRUD (Kelola Jajanan)
Halaman minimalis bagi pemilik stan untuk mengatur ketersediaan jajanan.
#### ASCII Mockup
```
+------------------------------------------+
|  Kelola Jajanan                          |
|                                          |
|  [ ➕ TAMBAH PRODUK BARU ]               |  --> Tombol Tambah Menu
|                                          |
|  Jajanan Aktif:                          |
|  1. Nasi Goreng Komplit     Rp 15.000    |
|     Status Stok: Tersedia  ( O) Toggle   |  --> Cupertino Switch
|     [ Edit Harga ]                       |
|                                          |
|  2. Es Teh Manis            Rp  4.000    |
|     Status Stok: Tersedia  ( O) Toggle   |
|     [ Edit Harga ]                       |
+------------------------------------------+
| [Kasir]  [Cek Kartu]  [Menu]  [Riwayat]   |
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Cupertino Switch "Status Stok"**: Mengatur ketersediaan menu. Jika dimatikan (OFF), menu tersebut otomatis disembunyikan dari POS Cashier Dashboard agar tidak salah checkout.

---

### Screen 7: Form Tambah / Edit Jajanan
Formulir minimalis pengisian jajanan baru.
#### ASCII Mockup
```
+------------------------------------------+
|  < Kelola Jajanan                        |
|  Tambah / Edit Jajanan                   |
|                                          |
|  Nama Jajanan                            |
|  [ Mie Goreng Spesial                ]   |
|  --------------------------------------- |
|  Harga Jajanan                           |
|  Rp [ 10.000                         ]   |
|  --------------------------------------- |
|  Kategori                                |
|  [ Makanan / Dropdown                [v] ]   |
|                                          |
|  Foto Jajanan (Opsional)                 |
|  [ + Pilih Gambar Dari Galeri ]          |
|                                          |
|  [ SIMPAN JAJANAN ]                      |
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Form Input**: Desain minimalis tanpa box kotak penuh, menggunakan garis bawah tipis khas formulir input Apple.

---

### Screen 8: Riwayat Penjualan & Shift Summary
Rekap transaksi masuk dan pembatalan penjualan harian.
#### ASCII Mockup
```
+------------------------------------------+
|  Rekap Penjualan Hari Ini                |
|  Total Pendapatan : Rp 320.000           |
|  Total Penjualan  : 22 Transaksi         |
|                                          |
|  Aktivitas Penjualan:                    |
|  - Ahmad (8-B) - Rp 22.000  (12:02)      |
|    Rincian: Nasi Goreng, Es Teh          |
|    [ BATALKAN TRANSAKSI / REFUND ]       |  --> Tombol Refund Merah
|                                          |
|  - Siti (7-A)  - Rp  8.500  (11:58)      |
|    Rincian: Bakso Tusuk, Teh Gelas       |
+------------------------------------------+
| [Kasir]  [Cek Kartu]  [Menu]  [Riwayat]   |
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **BATALKAN TRANSAKSI / REFUND**:
    *   *Keamanan*: Hanya aktif maksimal **10 menit** sejak transaksi dilakukan. Jika diklik, saldo siswa akan dikembalikan secara transaksional di database Supabase, dan data status transaksi diubah menjadi `cancelled`.
