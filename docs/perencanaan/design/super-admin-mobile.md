# 📱 Spesifikasi Desain UI/UX — Role: Super Admin (Mobile Master Cockpit)

Dokumen ini mendefinisikan seluruh antarmuka pengguna (UI/UX) untuk **Aplikasi Mobile Master Control Super Admin** secara lengkap dari awal hingga akhir, menggunakan pendekatan tata letak **iOS/Cupertino-style** yang minimalis modern, berorientasi pada visual bento-grid, serta dilengkapi visualisasi grafik analitik multi-dimensi dan monitoring server.

---

## 1. Panduan Visual Umum (Branding & Design System)

*   **Tipografi**: Menggunakan **Be Vietnam Pro** (Regular, Medium, SemiBold, Bold) untuk konsistensi seluruh aplikasi ekosistem Kantin Digital.
*   **Tema Warna**:
    *   *Primary Teal* (`#004D4D`): Warna structural brand, navigasi utama, dan kontrol administratif.
    *   *Accent Orange* (`#904D00`): Penanda area keuangan global dan akumulasi saldo.
    *   *Success Green* (`#006A35`): Indikator status sukses transaksi dan kesehatan server.
    *   *System Background* (`#FBF9F8`): Warna abu-abu hangat minimalis untuk latar belakang aplikasi.
    *   *Card Background* (`#FFFFFF`): Putih bersih untuk container bento-grid.
*   **Karakteristik Mobile Layout**:
    *   *Bento-Grid Architecture*: Tata letak modular kartu dengan sudut membulat lebar (`24px`) untuk pengelompokan metrik dan grafik yang padat informasi namun mudah dibaca.
    *   *Biometric Authentication*: Integrasi Face ID / Touch ID untuk membuka akses kontrol master demi keamanan finansial global.
    *   *iOS Grab Handle*: Penarik visual pada dialog modal bottom sheet detail log audit.

---

## 2. Struktur Alur Layar (Sitemap Aplikasi)

```
[Login Biometrik / PIN] ──> [Dashboard Master (Tab 1)]
                             ├── [Manajemen Pengguna (Tab 2)] ──> Filter Peran, Detail & Audit Aktivitas, Ubah Password, Status
                             ├── [Explorer Audit Log (Tab 3)] ──> Live Timeline (Bottom Sheet)
                             └── [Broadcast & Setelan (Tab 4)] ──> Notifikasi Push & Mode Pemeliharaan
```

---

## 3. Spesifikasi Rinci Layar Demi Layar

### Screen 1: Login Biometrik & Master PIN (Secure Entry)
Layar awal khusus Super Admin untuk masuk ke Master Control dengan lapisan keamanan ganda.

#### ASCII Mockup
```
+------------------------------------------+
|                                          |
|                 [🛜 + 🛡️]                 |
|              KANTIN DIGITAL              |
|           Master Control Panel           |
|                                          |
|        Lapisan Keamanan Super Admin      |
|                                          |
|               [ Face ID ]                |
|             Pindai Wajah Anda            |
|                                          |
|       - Atau Masukkan PIN Master -       |
|                [ * * * * ]               |
|                                          |
|            [ 1 ]  [ 2 ]  [ 3 ]           |
|            [ 4 ]  [ 5 ]  [ 6 ]           |
|            [ 7 ]  [ 8 ]  [ 9 ]           |
|                   [ 0 ]                  |
|                                          |
|     © 2026 Kantin Digital Security       |
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Tombol Face ID (Biometrik)**:
    *   *Aksi*: Memicu API biometrik perangkat bawaan (iOS/Android). Jika pemindaian berhasil, langsung mengarahkan pengguna ke **Screen 2: Dashboard Master**.
*   **Numpad PIN 6-Digit**:
    *   *Aksi*: Input kode PIN keamanan utama super admin jika sensor biometrik gagal atau tidak tersedia.

---

### Screen 2: Dashboard Master Cockpit (Tab 1: Home)
Pusat kendali real-time untuk memantau perputaran saldo keuangan di seluruh sekolah dan kesehatan server.

#### ASCII Mockup
```
+------------------------------------------+
| Halo, Super Admin                    [🔔] |
| Master Control Dashboard                 |
|                                          |
| +--------------------------------------+ |
| |  TOTAL METRIK GLOBAL                 | |
| |  Sekolah Terdaftar: 5 Sekolah        | |
| |  Saldo Global     : Rp 102.500.000   | |
| |  Volume Hari Ini  : Rp 12.450.000   | |
| +--------------------------------------+ |
|                                          |
| TREN VOLUME TRANSAKSI (30 Hari Terakhir) |
| 50M|         /\                          |
| 25M|    /\  /  \  /\                     |
| 10M|  _/  \/    \/  \                    |
|  0 +------------------- (Tanggal)        |
|                                          |
| KONTRIBUSI VOL. TRANSAKSI PER SEKOLAH    |
| (O) SMP Terpadu (45%)  (O) SMA Negeri 3  |
| (O) SMK Terpadu (25%)  (O) Sekolah Lain  |
|                                          |
| STATUS KESEHATAN SISTEM                  |
| - Latensi API: 42ms  (Normal)            |
| - Kapasitas DB: 12% Terpakai             |
| - Tingkat Sukses Transaksi: [99.8%] [■]  |
|                                          |
+------------------------------------------+
| [Home]     [User]     [Audit]   [Setting]|
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Grafik Area Volume Transaksi (Tren 30 Hari)**:
    *   *Jenis*: **Area Chart dengan Gradasi Teal**.
    *   *Fungsi*: Membantu Super Admin memantau kestabilan lalu lintas keuangan. Menekan area grafik akan memicu tooltip nominal transaksi pada tanggal tersebut.
*   **Grafik Donat Kontribusi per Sekolah**:
    *   *Jenis*: **Donut Chart**.
    *   *Fungsi*: Menampilkan persentase kontribusi volume transaksi dari masing-masing sekolah.
*   **Widget Status Kesehatan Sistem**:
    *   *Elemen*: Indikator status bulat (Hijau/Kuning/Merah) untuk parameter latensi, database storage, dan tingkat kesuksesan transaksi.

---

### Screen 3: Manajemen & Detail Pengguna (Tab 2: User)
Mengatur profil, kredensial password, dan audit aktivitas mendalam untuk seluruh role pengguna (Siswa, Orang Tua, Kasir/Petugas Kantin, dan Petugas Keuangan). Semua role menampilkan informasi identifikasi (Username, NISN untuk Siswa, Email) dan dapat diatur password-nya oleh Super Admin.

#### ASCII Mockup (Daftar Pengguna)
```
+------------------------------------------+
| Kelola Akun Pengguna                     |
| [🔍 Cari nama, email, NISN, usn...     ] |
|                                          |
| Filter Peran:                            |
| [ Semua ] [ Keuangan ] [ Kantin ] [Siswa]|
| [ Orang Tua ]                            |
|                                          |
| DAFTAR AKUN                              |
| +--------------------------------------+ |
| | Ahmad Subarjo (Siswa - 8-B)            | |
| | NISN: 2026090812 • USN: ahmad_subarjo  | |
| | Status: AKTIF             [ Toggle ON ]| |
| | > [ Detail & Riwayat Belanja ]         | |
| +--------------------------------------+ |
| | Rian (Petugas Kantin - Stan Bakso)     | |
| | USN: rian_bakso • Email: r@k.com       | |
| | Status: AKTIF             [ Toggle ON ]| |
| | > [ Detail & Riwayat Penjualan ]       | |
| +--------------------------------------+ |
| | Budi Hartono (Admin Keuangan)          | |
| | USN: budi_fin • Email: b@f.com         | |
| | Status: DIBLOKIR         [ Toggle OFF]| |
| | > [ Detail & Log Keuangan ]            | |
| +--------------------------------------+ |
| | Salim Subarjo (Orang Tua Ahmad)        | |
| | USN: salim_s • Email: s@o.com          | |
| | Status: AKTIF             [ Toggle ON ]| |
| | > [ Detail & Atur Password ]           | |
| +--------------------------------------+ |
+------------------------------------------+
| [Home]     [User]     [Audit]   [Setting] |
+------------------------------------------+
```

#### ASCII Mockup (Rincian & Riwayat per Peran)
Admin dapat memilih akun untuk membuka detail data lengkap masing-masing peran secara spesifik:

##### A. Rincian & Riwayat Siswa
```
+------------------------------------------+
| Rincian Pengguna (Siswa)                 |
|                                          |
| Nama : Ahmad Subarjo                     |
| NISN : 2026090812                        |
| USN  : ahmad_subarjo                     |
| Kelas: 8-B                               |
| Email: ahmad.subarjo@student.sch.id      |
| Saldo: Rp 45.000 (Kartu: AKTIF)          |
|                                          |
| [ UBAH KATA SANDI (PASSWORD) ]           |
|                                          |
| RIWAYAT BELANJA & TOP-UP SISWA           |
| - 17 Jun, 12:30 | Belanja Nasi Goreng    |
|   Total: Rp 12.000 (Stan Kantin Utama)   |
| - 17 Jun, 09:15 | Belanja Es Teh         |
|   Total: Rp 3.000 (Stan Minuman Segar)   |
| - 16 Jun, 08:00 | Top-Up Saldo Koperasi  |
|   Total: +Rp 50.000                      |
|                                          |
+------------------------------------------+
| [ Kembali ke Daftar ]                    |
+------------------------------------------+
```

##### B. Rincian & Riwayat Petugas Kantin
```
+------------------------------------------+
| Rincian Pengguna (Petugas Kantin)        |
|                                          |
| Nama : Rian                              |
| Stan : Stan Bakso & Mie Ayam             |
| USN  : rian_bakso                        |
| Email: rian.canteen@canteen.com          |
| Pendapatan Hari Ini: Rp 750.000          |
|                                          |
| [ UBAH KATA SANDI (PASSWORD) ]           |
|                                          |
| RIWAYAT TRANSAKSI PENJUALAN STAN         |
| - 17 Jun, 12:45 | Penjualan Bakso Urat   |
|   Total: +Rp 15.000 (Siswa: Budi Hartono)|
| - 17 Jun, 12:20 | Penjualan Es Jeruk     |
|   Total: +Rp 5.000 (Siswa: Ahmad)        |
|                                          |
| PRODUK YANG DIKELOLA (2)                 |
| 1. Bakso Biasa (Rp 12.000)               |
| 2. Mie Ayam (Rp 10.000)                  |
|                                          |
+------------------------------------------+
| [ Kembali ke Daftar ]                    |
+------------------------------------------+
```

##### C. Rincian & Riwayat Petugas Keuangan
```
+------------------------------------------+
| Rincian Pengguna (Keuangan)              |
|                                          |
| Nama : Budi Hartono                      |
| USN  : budi_fin                          |
| Email: budi.finance@finance.com          |
| Hak  : Admin Keuangan Utama              |
|                                          |
| [ UBAH KATA SANDI (PASSWORD) ]           |
|                                          |
| LOG AKTIVITAS KEUANGAN TERAKHIR          |
| - 17 Jun, 10:15 | Pencatatan Top-Up      |
|   Murid: Ahmad (Rp 100.000)              |
| - 16 Jun, 15:30 | Rekonsiliasi Kasir     |
|   Stan: Stan Bakso (Rp 1.200.000)        |
|                                          |
+------------------------------------------+
| [ Kembali ke Daftar ]                    |
+------------------------------------------+
```

##### D. Rincian Orang Tua
```
+------------------------------------------+
| Rincian Pengguna (Orang Tua)             |
|                                          |
| Nama : Salim Subarjo                     |
| USN  : salim_s                           |
| Email: salim.subarjo@gmail.com           |
| Anak : Ahmad Subarjo (NISN: 2026090812)  |
|                                          |
| [ UBAH KATA SANDI (PASSWORD) ]           |
|                                          |
| * Catatan Keamanan: Untuk akun orang     |
|   tua, rincian hanya menyertakan info    |
|   profil umum & tombol ganti sandi.      |
|                                          |
+------------------------------------------+
| [ Kembali ke Daftar ]                    |
+------------------------------------------+
```

#### Elemen & Aksi Interaksi
*   **Filter Peran Pil Horisontal**: Segment filter bergaya iOS untuk memilah daftar user secara cepat.
*   **Toggle Status (Cupertino Switch)**:
    *   *Aksi*: Merubah status `is_active` pengguna di tabel `profiles`. Jika dimatikan (`OFF`), mematikan hak akses otentikasi Supabase pengguna secara instan.
*   **Tombol [ UBAH KATA SANDI (PASSWORD) ]**:
    *   *Aksi*: Membuka modal pop-up Cupertino Text Field untuk menginput password baru. Super Admin dapat menyetel ulang password user secara paksa.
*   **Tautan Rincian & Riwayat (Siswa, Kantin, Keuangan)**:
    *   *Aksi*: Membuka layar sub-detail peran yang memuat riwayat transaksi mutasi lengkap (read-only untuk mempermudah pengecekan dan investigasi data).

---

### Screen 4: Explorer Audit Log (Tab 3: Audit)
Halaman pengawasan real-time yang tidak dapat diubah (read-only) untuk melacak perubahan data manual.

#### ASCII Mockup
```
+------------------------------------------+
| Timeline Audit Log Global                |
| Filter Sekolah: [ Semua Sekolah      [v] ]|
| Filter Aksi   : [ Semua Aksi         [v] ]|
|                                          |
| HARI INI (17 Jun 2026)                   |
| ---------------------------------------- |
| [🚨 KOREKSI SALDO] - 12:10:05 WIB        |
| Pelaksana: Budi (Keuangan SMP Terpadu)   |
| Keterangan: Koreksi saldo salah tap      |
| [ Detail Log Perubahan ] (Link)          |
|                                          |
| [💳 PENDAFTARAN KARTU] - 10:45:00 WIB    |
| Pelaksana: Rian (Kasir SMA Negeri 3)     |
| Keterangan: Registrasi kartu RFID baru   |
| [ Detail Log Perubahan ] (Link)          |
|                                          |
+------------------------------------------+
| [Home]     [User]     [Audit]   [Setting] |
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Tombol "Detail Log Perubahan"**:
    *   *Aksi*: Membuka dialog iOS Bottom Sheet yang menampilkan metadata JSON data sebelum (`old_value`) dan sesudah (`new_value`) aksi, lengkap dengan pencatatan IP Address dan User Agent demi alasan forensik keamanan keuangan digital.

---

### Screen 5: Broadcast & Setelan (Tab 4: Setting)
Pemberitahuan darurat push notification secara global dan penyetelan backend.

#### ASCII Mockup
```
+------------------------------------------+
| Broadcast & Setelan Global               |
|                                          |
| BROADCAST ANNOUNCEMENT                   |
| Target Peran: [ Semua Pengguna       [v] ]|
| Isi Pesan:                               |
| [ Pemeliharaan server dijadwalkan pada ] |
| [ pukul 23.00 WIB malam ini.           ] |
| [ KIRIM NOTIFIKASI PUSH ] (Teal Button)  |
|                                          |
| INTEGRASI PAYMENT (MIDTRANS API)         |
| Mode: [ Sandbox ]   Server: [ Active ]   |
| Client Key: [ Client-Key-Prod-09823... ] |
|                                          |
| PEMELIHARAAN SISTEM                      |
| Mode Pemeliharaan Global    [ Toggle OFF ]|
| (Kunci akses semua aplikasi mitra)       |
|                                          |
| [ SIMPAN SETELAN GLOBAL ] (Orange)       |
+------------------------------------------+
| [Home]     [User]     [Audit]   [Setting] |
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Tombol "KIRIM NOTIFIKASI PUSH"**:
    *   *Aksi*: Mengirim payload notifikasi push Firebase Cloud Messaging (FCM) secara massal ke segmen peran pengguna terpilih.
*   **Toggle "Mode Pemeliharaan Global"**:
    *   *Aksi*: Jika diaktifkan, database config Supabase akan merubah bendera `maintenance_mode` menjadi `true`. Ini langsung mengarahkan semua aplikasi murid dan petugas kantin ke halaman "Server Maintenance" dan memblokir request transaksi API masuk.
*   **Tombol "SIMPAN SETELAN GLOBAL"**: Menyimpan enkripsi konfigurasi sistem API payment gateway Midtrans ke tabel konfigurasi database.
