# 🌐 Spesifikasi Desain UI/UX — Role: Orang Tua (Web Publik Tanpa Login)

Dokumen ini mendefinisikan seluruh antarmuka pengguna (UI/UX) untuk **Portal Web Publik Orang Tua** secara lengkap dari awal hingga akhir, termasuk portal pencarian siswa, tabel rekap jajan harian, alur pembayaran online instan, dan proses download struk pembayaran digital.

---

## 1. Panduan Visual Umum (Branding & Web Layout)
*   **Tema Warna**: Primary Teal (`#0E8A8A`), Accent Orange (`#F2994A`), Latar Belakang (`#F8F9FA`).
*   **Font**: Poppins (Regular, Medium, SemiBold, Bold).
*   **Tata Letak**: Portal halaman tunggal (single-page app) yang sangat responsif, optimal baik diakses melalui browser HP (mobile web) maupun komputer desktop/tablet.

---

## 2. Struktur Alur Halaman (Sitemap Web Publik)
```
[Portal Masuk NIS] ──> [Dashboard Pantau Anak]
                        ├── [Layar Pilih Nominal Top-up] ──> [Pop-up Midtrans Snap]
                        └── [Cetak / Unduh E-Receipt Bukti Bayar]
```

---

## 3. Spesifikasi Rinci Halaman Demi Halaman

### Screen 1: Portal Masuk NIS (Landing Page)
Halaman awal saat orang tua mengakses alamat web `kantin.sekolah.id`. Sederhana, fokus pada pencarian siswa.
#### ASCII Mockup
```
+-------------------------------------------------------------+
|                                                             |
|                       KANTIN DIGITAL                        |
|                    Portal Orang Tua Siswa                   |
|                                                             |
|           Cek Saldo & Top-up Online Uang Saku Anak          |
|                                                             |
|           Masukkan NIS / Kode Unik Siswa                    |
|           [ 20260012                             ]          |
|                                                             |
|           [ CEK SALDO & AKTIVITAS ANAK ] (Teal)             |
|                                                             |
+-------------------------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Kolom "Masukkan NIS / Kode Unik Siswa"**: Kolom input numerik untuk memasukkan nomor induk siswa anak.
*   **Tombol "CEK SALDO & AKTIVITAS ANAK"**:
    *   *Aksi*: Klik tombol -> Query database Supabase untuk mencari data NIS di tabel `students`.
        *   *Jika Ditemukan*: Mengarahkan ke **Screen 2: Dashboard Pantau Anak**.
        *   *Jika Tidak*: Menampilkan pesan kesalahan di bawah kolom: *"NIS Tidak Terdaftar. Silakan hubungi tata usaha sekolah."* (teks merah).

---

### Screen 2: Dashboard Pantau Anak
Menampilkan sisa saldo anak teraktual dan riwayat jajanan anak secara transparan.
#### ASCII Mockup
```
+-------------------------------------------------------------+
|  < Ganti Kode Siswa                                         |
|                                                             |
|  PROFIL SISWA                                               |
|  Nama Lengkap : Ahmad Subarjo                               |
|  Sekolah      : SMP Terpadu Kota                            |
|  Kelas        : 8-B                                         |
|                                                             |
|  SALDO AKTIF SAAT INI                                       |
|  +-------------------------------------------------------+  |
|  | Rp 75.000                                             |  |
|  +-------------------------------------------------------+  |
|                                                             |
|  [ TOP-UP SALDO ONLINE ] (Orange)                           |
|                                                             |
|  5 AKTIVITAS JAJAN TERAKHIR ANAK                            |
|  - 12 Jun (12:05) : Nasi Goreng, Es Teh         - Rp 19.000  |
|  - 12 Jun (12:02) : Porsi Extra Nasi (Kustom)   - Rp  3.000  |
|  - 11 Jun (10:15) : Bakso Tusuk, Teh Gelas      - Rp  8.500  |
|  - 10 Jun (08:30) : Top-up Midtrans Sukses      + Rp 50.000  |
|  - 09 Jun (12:12) : Roti Coklat, Air Mineral    - Rp  6.000  |
+-------------------------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Tombol "< Ganti Kode Siswa"**: Mengembalikan ke Screen 1 untuk mencari NIS lain.
*   **Informasi Profil & Saldo**: Data diambil secara dinamis dari database.
*   **Daftar "5 Aktivitas Jajan Terakhir Anak"**:
    *   Mengambil 5 baris data transaksi teraktual untuk `student_id` tersebut.
    *   Menampilkan detail rincian produk jajan (`transaction_items`) agar orang tua tahu persis apa saja makanan yang dibeli anak mereka di kantin sekolah.
*   **Tombol "TOP-UP SALDO ONLINE"**:
    *   *Aksi*: Mengarahkan orang tua ke **Screen 3: Layar Pilih Nominal Top-up**.

---

### Screen 3: Layar Pilih Nominal Top-up
Halaman untuk menentukan nominal transfer saldo dan mengisi identitas pembayar.
#### ASCII Mockup
```
+-------------------------------------------------------------+
|  < Kembali Pantau Anak                                      |
|  Formulir Top-up Saldo Online                               |
|  Siswa Penerima: Ahmad Subarjo (Kelas 8-B)                  |
|                                                             |
|  Pilih Nominal:                                             |
|  ( ) Rp 20.000    ( ) Rp 50.000    (o) Rp 100.000           |
|  Atau Kustom  : Rp [                                ]       |
|                                                             |
|  Data Pengirim (Orang Tua):                                 |
|  Nama Pengirim : [ Budi Subarjo                      ]      |
|  Nomor WA/HP   : [ 08123456789                       ]      |
|                                                             |
|  [ BAYAR SEKARANG VIA MIDTRANS ] (Teal)                     |
+-------------------------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Pilihan Nominal**: Radio button nominal instan atau input nominal manual.
*   **Nama Pengirim & Nomor WA**: Digunakan untuk identitas rekap pengirim dana di database dan pengiriman notifikasi/bukti struk sukses ke nomor WhatsApp orang tua.
*   **Tombol "BAYAR SEKARANG VIA MIDTRANS"**:
    *   *Aksi*:
        1. Sistem mengirim data top-up ke backend.
        2. Backend Supabase memanggil API Midtrans Snap untuk membuat transaksi dengan status `pending` di tabel `payment_requests`.
        3. Membuka **Screen 4: Pop-up Midtrans Snap** secara langsung di layar.

---

### Screen 4: Pop-up Midtrans Snap (Modal Interface)
Layar pembayaran multi-metode bawaan dari Midtrans.
#### ASCII Mockup
```
+-------------------------------------------------------------+
|                                                             |
|  +-------------------------------------------------------+  |
|  |  MIDTRANS SNAP CHECKOUT                               |  |
|  |  Total Tagihan: Rp 100.000                            |  |
|  |                                                       |  |
|  |  Pilih Metode Pembayaran:                             |  |
|  |  1. QRIS (Gopay, OVO, ShopeePay, Dana)                |  |
|  |  2. Virtual Account Bank (BCA, Mandiri, BNI, BRI)     |  |
|  |  3. Alfamart / Indomaret                               |  |
|  |                                                       |  |
|  |  [ LANJUTKAN PEMBAYARAN ]                             |  |
|  +-------------------------------------------------------+  |
|                                                             |
+-------------------------------------------------------------+
```
#### Alur Transaksi
*   Orang tua menyelesaikan pembayaran menggunakan metode yang dipilih di browser.
*   Setelah bayar, Midtrans mengirimkan HTTP Webhook (notification handler) ke Supabase backend.
*   Backend memproses pembaruan saldo siswa di database dan merubah status transaksi `payment_requests` ke `paid`.
*   Aplikasi mendeteksi status sukses di web browser orang tua dan mengarahkan ke **Screen 5: E-Receipt Bukti Bayar**.

---

### Screen 5: E-Receipt Bukti Bayar
Halaman konfirmasi sukses dan tanda terima pembayaran online digital.
#### ASCII Mockup
```
+-------------------------------------------------------------+
|                                                             |
|                 PEMBAYARAN ONLINE BERHASIL                  |
|                      (Centang Hijau)                        |
|                                                             |
|  Tanda Terima Digital                                       |
|  No. Order Midtrans : PR-9081203980                         |
|  Tanggal Bayar      : 12 Jun 2026 14:30                     |
|  Nama Pengirim      : Budi Subarjo                          |
|  Siswa Penerima     : Ahmad Subarjo                         |
|  Nominal Top-up     : Rp 100.000                            |
|  Status Transaksi   : SUKSES / LUNAS                        |
|                                                             |
|  Saldo Baru Ahmad   : Rp 175.000                            |
|                                                             |
|  [ DOWNLOAD BUKTI PEMBAYARAN (PDF) ]                        |
|  [ KEMBALI KE HALAMAN UTAMA ]                               |
+-------------------------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Tombol "DOWNLOAD BUKTI PEMBAYARAN (PDF)"**:
    *   *Aksi*: Membuat file PDF receipt resmi dari Supabase backend untuk diunduh orang tua sebagai tanda terima sah.
*   **Tombol "KEMBALI KE HALAMAN UTAMA"**:
    *   *Aksi*: Mengembalikan orang tua ke **Screen 1: Portal Masuk NIS** untuk memulai pencarian baru.
