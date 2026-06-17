# 📱 Spesifikasi Desain UI/UX — Role: Super Admin (Mobile Master Cockpit)

Dokumen ini mendefinisikan seluruh antarmuka pengguna (UI/UX) untuk **Aplikasi Mobile Master Control Super Admin** secara lengkap dari awal hingga akhir, menggunakan pendekatan tata letak **iOS/Cupertino-style** yang minimalis modern, berorientasi pada visual bento-grid, serta dilengkapi visualisasi grafik analitik dan monitoring.

---

## 1. Panduan Visual Umum (Branding & Design System)

*   **Tipografi**: Menggunakan font **Be Vietnam Pro** untuk konsistensi seluruh ekosistem Kantin Digital.
    *   `display`: 34px Bold, LineHeight 41px, LetterSpacing -0.02em (Total metrik utama)
    *   `headline-lg`: 24px SemiBold, LineHeight 30px, LetterSpacing -0.01em (Nama halaman/seksi besar)
    *   `headline-md`: 20px SemiBold, LineHeight 25px (Judul kartu bento, nama sub-halaman)
    *   `body-lg`: 17px Regular, LineHeight 22px (Deskripsi, teks utama profil)
    *   `body-md`: 15px Regular, LineHeight 20px (Teks sekunder, data detail)
    *   `label-md`: 13px Medium, LineHeight 18px, LetterSpacing 0.01em (Teks tombol, label input)
    *   `label-sm`: 11px SemiBold, LineHeight 13px, LetterSpacing 0.05em (Badge status uppercase, kategori)

*   **Tema Warna**:
    *   *Primary Teal* (`#003434`): Warna structural brand, navigasi utama, dan kontrol administratif (Command Layer).
    *   *Accent Orange* (`#904D00`): Penanda saldo keuangan global dan akumulasi nominal saldo utama (Value Layer).
    *   *Success Green* (`#006A35`): Indikator status sukses transaksi dan kesehatan server optimal.
    *   *System Background* (`#FBF9F8`): Warna abu-abu hangat minimalis untuk latar belakang aplikasi (Level 0).
    *   *Card Background* (`#FFFFFF`): Putih bersih untuk kontainer bento-grid dengan shadow `0px 4px 20px rgba(0, 0, 0, 0.04)` (Level 1).

*   **Karakteristik Mobile Layout**:
    *   *Bento-Grid Architecture*: Tata letak modular kartu dengan sudut membulat lebar (`24px` / `rounded-xl` pada iOS) untuk pengelompokan metrik dan grafik.
    *   *Buttons & Inputs*: Radius sudut membulat `12px` (rounded-md) untuk kesan fungsional.
    *   *Biometric Authentication*: Integrasi Face ID / Touch ID untuk membuka akses kontrol master demi keamanan finansial global.
    *   *iOS Grab Handle*: Penarik visual pada dialog modal bottom sheet detail log audit.
    *   *Interactive Feedback*: Tombol menyusut secara visual (scale 0.98) saat ditekan.

---

## 2. Struktur Alur Layar (Sitemap Aplikasi)

```
[Login Biometrik / PIN] ──> [Dashboard Master (Tab 1)]
                             ├── [Manajemen Pengguna (Tab 2)] ──> Filter Peran, Detail & Audit Aktivitas, Ubah Password, Status
                             ├── [Explorer Audit Log (Tab 3)] ──> Timeline Global, JSON Diff (Bottom Sheet)
                             └── [Broadcast & Setelan (Tab 4)] ──> Notifikasi Push, Integrasi API, Mode Pemeliharaan
```

---

## 3. Spesifikasi Rinci Layar Demi Layar

### Screen 1: Login Biometrik & Master PIN (Secure Entry)
Layar awal khusus Super Admin untuk masuk ke Master Control dengan lapisan keamanan ganda.

#### ASCII Mockup
```
+------------------------------------------+
|                                          |
|                [ admin ]                 |
|             KANTIN DIGITAL               |
|             Master Control               |
|                                          |
|                                          |
|                 [ face ]                 |
|                                          |
|                                          |
|            ENTER MASTER PIN              |
|          [ o  o  o  o  o  o ]            |
|                                          |
|            [ 1 ]  [ 2 ]  [ 3 ]           |
|            [ 4 ]  [ 5 ]  [ 6 ]           |
|            [ 7 ]  [ 8 ]  [ 9 ]           |
|                   [ 0 ]  [ < ]           |
|                                          |
|       © 2026 Kantin Digital Security.    |
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Logo Panel Keamanan**: Ikon `admin_panel_settings` di dalam kontainer bayangan tebal.
*   **Tombol Face ID (Biometrik)**:
    *   *Aksi*: Menampilkan prompt Face ID bawaan sistem. Jika sukses, langsung mengarahkan ke dashboard.
*   **PIN Code Dot Indicator**:
    *   *Visual*: Menampilkan 6 indikator bulat. Titik terisi (`filled`) saat PIN dimasukkan menggunakan numpad.
*   **Numpad Grid**:
    *   *Aksi*: Klik tombol 0-9 untuk mengisi PIN. Klik tombol `backspace` (`<`) untuk menghapus digit terakhir.

---

### Screen 2: Dashboard Master Cockpit (Tab 1: Home)
Pusat kendali real-time untuk memantau saldo keuangan di seluruh sekolah dan kesehatan server.

#### ASCII Mockup
```
+------------------------------------------+
| SA Kantin Digital                    [🔔] |
|                                          |
| Halo, Super Admin                        |
| Real-time command center overview.       |
|                                          |
| +--------------------------------------+ |
| | Global Metrics                       | |
| | [ SCHOOL COUNT ]    [ DAILY VOLUME ] | |
| | 1,248               42.5K            | |
| |                                      | |
| |          GLOBAL BALANCE              | |
| |          Rp 102.500.000              | |
| +--------------------------------------+ |
|                                          |
| +--------------------------------------+ |
| | Transaction Trend           [ 30 Days ]| |
| |     /\                               | |
| |    /  \    /\                        | |
| | __/    \  /  \                       | |
| |         \/    \/\                    | |
| +--------------------------------------+ |
|                                          |
| +-------------------+  +---------------+ |
| | Contribution/Sch  |  | System Health | |
| |      ( O )        |  | (•) Optimal   | |
| |                   |  | API: 42ms     | |
| | (•) Sch A (•) Sch |  | DB : 12%      | |
| +-------------------+  +---------------+ |
+------------------------------------------+
| [Home]     [Users]     [Audit]  [Settings] |
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Greeting Header**: Menampilkan nama akun dan foto profil sirkular (SA).
*   **Kartu Metrik Global**:
    *   Menampilkan data `School Count` (1,248) dan `Daily Volume` (42.5K).
    *   Menampilkan `Global Balance` (Rp 102.500.000) dengan ukuran teks `display` dan warna *Accent Orange* (`#904D00`).
*   **Transaction Trend Card**:
    *   Grafik tren berbasis area teal gradasi (`chart-area-teal`) untuk riwayat volume transaksi 30 hari terakhir.
*   **Contribution per School**:
    *   Grafik donat mini yang membagi kontribusi transaksi dari sekolah terdaftar.
*   **System Health Card**:
    *   Menampilkan status "Optimal" (hijau) beserta rincian: `API Latency` (42ms), `DB Capacity` (12%), dan `Success Rate` (99.8%).

---

### Screen 3: Manajemen Pengguna (Tab 2: Users)
Pusat pencarian, penyaringan peran, dan aktivasi akun pengguna.

#### ASCII Mockup
```
+------------------------------------------+
| Kelola Akun Pengguna                     |
| [🔍 Cari nama, email, NISN, usn...     ] |
|                                          |
| [ Semua ] [ Keuangan ] [ Kantin ] [Siswa]|
|                                          |
| +--------------------------------------+ |
| | [Img] Ahmad Subarjo          (Siswa) | |
| | NISN: 0041234567 • USN: ahmad_sb     | |
| | Status: AKTIF             [ Toggle ON ]| |
| | > [ Detail & Riwayat Belanja ]         | |
| +--------------------------------------+ |
| | [Img] Rian                 (Kantin)  | |
| | USN: RIAN882 • Stan: Bakso & Mie     | |
| | Status: AKTIF             [ Toggle ON ]| |
| | > [ Detail & Riwayat Penjualan ]       | |
| +--------------------------------------+ |
| | [Img] Budi Hartono        (Keuangan) | |
| | USN: ID-2093-TU • Staf Tata Usaha    | |
| | Status: AKTIF             [ Toggle ON ]| |
| | > [ Detail & Log Keuangan ]            | |
| +--------------------------------------+ |
| | [Img] Salim Subarjo       (Orang Tua)| |
| | USN: salim_s • Wali Ahmad Subarjo    | |
| | Status: AKTIF             [ Toggle ON ]| |
| | > [ Detail & Hubungan Anak ]           | |
| +--------------------------------------+ |
+------------------------------------------+
| [Home]     [Users]     [Audit]  [Settings] |
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Search Bar**: Memungkinkan pencarian teks bebas (real-time query) untuk nama, email, username, atau NISN.
*   **Segmented Control Filter**: Menyaring daftar pengguna berdasarkan Peran (`Semua`, `Keuangan`, `Kantin`, `Siswa`, `Orang Tua`).
*   **List Item Akun**:
    *   Foto avatar profil bulat.
    *   Label teks ringkas (Nama, Username, Role, Parameter unik seperti Stan atau NISN).
    *   **Status Toggle (Cupertino Switch)**:
        *   *Aksi*: Mengaktifkan / menonaktifkan akun langsung di database. Pengguna nonaktif tidak bisa login/transaksi.
    *   **Pintasan Detail (`>`)**: Mengalihkan ke detail sub-page khusus peran tersebut.

---

### Screen 4: Detail Pengguna — Peran Siswa (Sub-page)
Layar audit profil siswa, saldo RFID, dan riwayat jajannya.

#### ASCII Mockup
```
+------------------------------------------+
| < Detail Siswa                           |
|                                          |
| +--------------------------------------+ |
| | [Img] Ahmad Subarjo                  | |
| |       Kelas 11 IPA 2 • NISN: 00412347| |
| +--------------------------------------+ |
|                                          |
| +--------------------------------------+ |
| | Status Kartu         [ Active (Pill) ] | |
| | UID RFID                 A1 B2 C3 D4 | |
| | Saldo                Rp 45.000       | |
| | Batas Harian         Rp 50.000       | |
| +--------------------------------------+ |
|                                          |
|  [ 🔑 Ubah Kata Sandi ]                  |
|  [ ❄️ Bekukan Kartu RFID ]                |
|                                          |
| Riwayat Transaksi          [ Lihat Semua ]|
| +--------------------------------------+ |
| | [🍔] Nasi Goreng           -Rp 15.000| |
| |      Kantin Ibu Tini • Hari ini, 12:30| |
| +--------------------------------------+ |
| | [🍹] Es Teh Manis           -Rp 5.000| |
| |      Kantin Minuman • Hari ini, 12:35| |
| +--------------------------------------+ |
| | [💳] Top-up Saldo          +Rp 50.000| |
| |      Tata Usaha • Kemarin, 08:00     | |
| +--------------------------------------+ |
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Header Profil**: Tombol kembali Cupertino `<` dan judul "Detail Siswa". Foto profil bulat, Nama lengkap, Kelas, dan NISN.
*   **Info Card Bento**:
    *   Badge status hijau (`Active`).
    *   UID RFID fisik (dalam bentuk hexadecimal monospace).
    *   Saldo dompet saku dalam format nominal besar (Primary Teal).
    *   Batas limit jajan harian siswa.
*   **Tombol Ubah Kata Sandi**:
    *   *Aksi*: Menampilkan modal dialog input teks password baru.
*   **Tombol Bekukan Kartu RFID**:
    *   *Aksi*: Menandai `is_active` menjadi `false` pada tabel `students` dengan background oranye/merah.
*   **Riwayat Transaksi**:
    *   Daftar item belanja dengan detail nama produk, nama stan, waktu transaksi, dan harga.

---

### Screen 5: Detail Pengguna — Peran Petugas Kantin (Sub-page)
Layar detail performa penjualan stan kantin, menu aktif, dan penjualan terbaru.

#### ASCII Mockup
```
+------------------------------------------+
| < Rian                                   |
|                                          |
| +--------------------------------------+ |
| | [Img] Rian                           | |
| |       Bakso & Mie • USN: RIAN882     | |
| +--------------------------------------+ |
|                                          |
|  [ 🔑 Ubah Kata Sandi ]                  |
|                                          |
| +-------------------+  +---------------+ |
| | Daily Sales       |  | Monthly Sales | |
| | Rp 750.000        |  | Rp 18.250.000 | |
| | +12% from yesterday  |  On track     | |
| +-------------------+  +---------------+ |
|                                          |
| Product Catalog              [Read-Only] |
| +--------------------------------------+ |
| | Bakso Urat        Rp 15.000 [ Avail ]| |
| | Mie Ayam Spesial  Rp 12.000 [ Avail ]| |
| | Es Teh Manis      Rp 3.000  [ Soldout]| |
| +--------------------------------------+ |
|                                          |
| Recent Sales               [ Lihat Semua ]|
| +--------------------------------------+ |
| | Bakso Urat, Es Teh          Rp 18.000| |
| | NISN: 0041234567 • 10:42 AM          | |
| +--------------------------------------+ |
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Header Profil**: Tombol kembali `<` dan judul "Rian". Nama lengkap, stan, dan username kasir.
*   **Performance Bento**:
    *   Bento kiri: `Daily Sales` (nominal saldo omset + trend persentase hijau).
    *   Bento kanan: `Monthly Sales` (total bulanan + status).
*   **Product Catalog**:
    *   Daftar menu jajan read-only dengan indikator ketersediaan produk (`Available` / `Sold Out`).
*   **Recent Sales**:
    *   Laporan struk penjualan terbaru stan, menampilkan gabungan produk, NISN pembeli, waktu, dan total harga belanja.

---

### Screen 6: Detail Pengguna — Peran Petugas Keuangan (Sub-page)
Layar penugasan staf Tata Usaha dan monitoring riwayat pengisian saldo (top-up) manual.

#### ASCII Mockup
```
+------------------------------------------+
| < Profile Pegawai                        |
|                                          |
| +--------------------------------------+ |
| | [Img] Budi Hartono                   | |
| |       Staf Tata Usaha • ID-2093-TU   | |
| +--------------------------------------+ |
|                                          |
|  [ 🔑 Ubah Kata Sandi ]                  |
|                                          |
| +-------------------+  +---------------+ |
| | Unit Tugas        |  | Tingkat Akses | |
| | SMP Terpadu       |  | Officer L1    | |
| | Kampus Utama      |  | Top-up | Tarik| |
| +-------------------+  +---------------+ |
|                                          |
| Aktivitas Transaksi        [ Lihat Semua ]|
| +--------------------------------------+ |
| | Top-up Tunai Siswa        +Rp 50.000 | |
| | Anita Rahman (10293) • 10:42 AM      | |
| +--------------------------------------+ |
| | Penarikan Saldo           -Rp 150.000| |
| | Guru: Bpk. Joko Widodo • Kemarin     | |
| +--------------------------------------+ |
| | Koreksi Transaksi         [Dibatalkan] | |
| | Salah input nominal • 12 Okt         | |
| +--------------------------------------+ |
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Header Profil**: Tombol kembali `<` dan nama "Budi Hartono".
*   **Bento Ops**:
    *   Bento kiri: `Unit Tugas` (sekolah penugasan petugas, misal SMP Terpadu).
    *   Bento kanan: `Tingkat Akses` (level administratif L1/L2/L3 beserta chip fitur aktif seperti Top-up atau Tarik Dana).
*   **Aktivitas Transaksi**:
    *   Timeline log operasi keuangan yang dilakukan oleh petugas bersangkutan (Top-up, Tarik tunai, Koreksi saldo).

---

### Screen 7: Detail Pengguna — Peran Orang Tua (Sub-page)
Layar detail wali murid dan pintasan peninjauan aktivitas jajan anak terikat.

#### ASCII Mockup
```
+------------------------------------------+
| < Profil Orang Tua                       |
|                                          |
| +--------------------------------------+ |
| | [Img] Salim Subarjo                  | |
| |       Orang Tua Wali                 | |
| |       salim.subarjo@example.com      | |
| |       +62 812 3456 7890              | |
| +--------------------------------------+ |
|                                          |
| Data Anak                                |
| +--------------------------------------+ |
| | [Img] Ahmad Subarjo                  | |
| |       Kelas 10A • SMA N 1 Jakarta    | |
| +--------------------------------------+ |
|                                          |
|  [ 👉 LIHAT DETAIL AKUN SISWA ]          |
|                                          |
| Pengaturan Keamanan                      |
| +--------------------------------------+ |
| | [🔑] Ubah Kata Sandi               > | |
| | [⚙️] Sesi Aktif                    > | |
| +--------------------------------------+ |
|                                          |
|  [ Nonaktifkan Akun Orang Tua (Red) ]    |
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Header Profil**: Detail kontak (email, nomor telepon) dan nama "Salim Subarjo".
*   **Data Anak**:
    *   Menampilkan profil anak yang terhubung dengan akun orang tua tersebut (Nama, Kelas, Sekolah).
*   **Tombol 👉 LIHAT DETAIL AKUN SISWA**:
    *   *Aksi*: Melakukan navigasi cepat langsung ke **Screen 4: Detail Pengguna - Peran Siswa** untuk meninjau riwayat jajan secara rinci.
*   **Danger Zone**: Tombol "Nonaktifkan Akun Orang Tua" dengan border merah solid.

---

### Screen 8: Explorer Audit Log (Tab 3: Audit)
Halaman timeline read-only real-time untuk audit investigasi semua aktivitas platform.

#### ASCII Mockup
```
+------------------------------------------+
| Audit Log Explorer                       |
| Real-time system monitoring.             |
|                                          |
| Filter Sekolah: [ All Schools        [v] ]|
| Filter Aksi   : [ All Actions        [v] ]|
|                                          |
| HARI INI                                 |
| -[!] KOREKSI SALDO               Just now|
|  Budi Santoso adjusted balance for       |
|  Student ID 109283 (Rp 50k -> Rp 150k)   |
|  [ Detail Log Perubahan -> ]             |
|                                          |
| -[+] PENDAFTARAN KARTU        10 mins ago|
|  Siti Aminah registered new NFC card     |
|  UID: A4B9C2D8 | Student: Rina (10A)     |
|  [ Detail Log Perubahan -> ]             |
|                                          |
| -[*] PENGATURAN SISTEM        1 hour ago |
|  Super Admin updated fee parameter       |
|  (Fee changed from 2% to 2.5%)           |
|  [ Detail Log Perubahan -> ]             |
+------------------------------------------+
| [Home]     [Users]     [Audit]  [Settings] |
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Dropdown Filters**:
    *   Penyaringan log audit berdasarkan sekolah terdaftar.
    *   Penyaringan log audit berdasarkan kategori aksi (`Koreksi Saldo`, `Registrasi Kartu`, `Pengaturan`).
*   **Timeline Item**:
    *   Badge kategori berwarna (Merah untuk Koreksi, Hijau untuk Pendaftaran, Abu-abu untuk Sistem).
    *   Waktu relatif (`Just now`, `10 mins ago`).
    *   Deskripsi singkat perubahan.
*   **Link Detail Log Perubahan**:
    *   *Aksi*: Membuka modal bottom sheet iOS (dengan grab handle) berisi metadata perubahan JSON (`old_value` dan `new_value`), IP address pelaku, dan User Agent.

---

### Screen 9: Broadcast & Setelan (Tab 4: Settings)
Pemberitahuan notifikasi push global dan konfigurasi parameter payment gateway.

#### ASCII Mockup
```
+------------------------------------------+
| Settings                                 |
| Global platform controls.                |
|                                          |
| +--------------------------------------+ |
| | [📢] Push Broadcast                  | |
| | Target: [ All Users                [v] ]|
| | Message:                               | |
| | [ Server maintenance scheduled at..  ] | |
| | [ KIRIM NOTIFIKASI PUSH ]            | |
| +--------------------------------------+ |
|                                          |
| +-------------------+  +---------------+ |
| | [⚙️] Payment API   |  | [🛠️] System    | |
| | Midtrans [Active] |  | Access        | |
| | Env: [Sandbox   ] |  | Pemeliharaan  | |
| | Key: [**********] |  | [ Toggle ON ] | |
| +-------------------+  +---------------+ |
|                                          |
|                [ SIMPAN SETELAN GLOBAL ] |
+------------------------------------------+
| [Home]     [Users]     [Audit]  [Settings] |
+------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Push Broadcast**:
    *   Dropdown pilihan target (`All Users`, `Merchants`, `Students`, `Staff`).
    *   Textarea pesan pengumuman FCM.
    *   Tombol kirim notifikasi push instan (Primary Teal).
*   **Payment API Card (Midtrans)**:
    *   Status indikator aktif.
    *   Pill switcher Mode (`Sandbox` / `Production`).
    *   Key mask dengan tombol salin (`content_copy`) dan intip (`visibility`).
*   **System Access Card**:
    *   iOS Switch untuk `Mode Pemeliharaan Global` (jika ON, mematikan seluruh akses login & transaksi platform bagi non-admin).
*   **SIMPAN SETELAN GLOBAL**: Tombol oranye aksen untuk menyimpan perubahan konfigurasi secara permanen ke database settings.
