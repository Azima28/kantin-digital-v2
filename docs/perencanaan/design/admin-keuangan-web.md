# 🌐 Spesifikasi Desain UI/UX — Role: Admin Keuangan (Web Dashboard)

Dokumen ini mendefinisikan seluruh antarmuka pengguna (UI/UX) untuk **Dashboard Web Admin Keuangan** secara lengkap dari awal hingga akhir, termasuk struktur halaman, komponen tabel, form input, alur data, audit log, dan integrasi backend.

---

## 1. Panduan Visual Umum (Branding & Desktop Layout)
*   **Tema Warna**: Primary Teal (`#0E8A8A`), Accent Orange (`#F2994A`), Latar Belakang (`#F8F9FA`).
*   **Font**: Poppins (Regular, Medium, SemiBold, Bold).
*   **Tata Letak**: Sidebar navigasi di sisi kiri (lebar tetap `240px`), area konten utama di kanan (fleksibel/responsif), panel data menggunakan border-radius `8px` untuk platform desktop.

---

## 2. Struktur Alur Halaman (Sitemap Web)
```
[Web Login] ──> [Dashboard Ringkasan]
                ├── [Manajemen Data Siswa] ──> [Modal Registrasi Kartu]
                ├── [Modul Top-Up Tunai] ──> [Verifikasi & Tulis Audit Log]
                ├── [Modul Koreksi Saldo] ──> [Input Alasan Wajib & Audit Log]
                └── [Laporan Keuangan] ──> [Export Excel / PDF]
```

---

## 3. Spesifikasi Rinci Halaman Demi Halaman

### Screen 1: Web Login Portal
Form masuk di web browser (URL: `admin.kantin.sekolah.id`).
#### ASCII Mockup
```
+-------------------------------------------------------------+
|                                                             |
|                       KANTIN DIGITAL                        |
|                     Portal Admin Sekolah                    |
|                                                             |
|                  Email                                      |
|                  [ tatausaha@sekolah.sch.id            ]    |
|                                                             |
|                  Kata Sandi                                 |
|                  [ **********                          ]    |
|                                                             |
|                  [ MASUK KE PORTAL ] (Teal)                 |
|                                                             |
+-------------------------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Kolom Email & Password**: Input untuk kredensial admin keuangan.
*   **Tombol "MASUK KE PORTAL"**:
    *   *Aksi*: Melakukan autentikasi Supabase. Mengecek relasi penugasan di tabel `admin_assignments` untuk mengunci akses admin hanya pada sekolah asal mereka. Jika sukses, mengarahkan ke **Screen 2: Dashboard Ringkasan**.

---

### Screen 2: Dashboard Ringkasan
Layar utama pasca login, menampilkan rangkuman keuangan sekolah berjalan.
#### ASCII Mockup
```
+-----------------------------------------------------------------------------------+
| [Logo] Kantin Digital   | Beranda | Siswa | Top-up | Koreksi | Laporan  | [Akun]  | --> Top Nav
+-----------------------------------------------------------------------------------+
|                                                                                   |
|  Selamat Bekerja, Admin Keuangan Sekolah (TU SMP Terpadu)                          |
|                                                                                   |
|  METRIK KEUANGAN SEKOLAH                                                          |
|  +----------------------+  +----------------------+  +-------------------------+  |
|  | Total Saldo Beredar  |  | Top-up Tunai Hari Ini|  | Top-up Midtrans VA/QRIS |  |
|  | Rp 14.520.000        |  | Rp 1.250.000         |  | Rp 2.300.000            |  |
|  +----------------------+  +----------------------+  +-------------------------+  |
|                                                                                   |
|  PEMBERITAHUAN AUDIT TERBARU                                                      |
|  - 12:10 : Top-up manual Rp 50.000 untuk NIS 20260012 sukses                      |
|  - 10:45 : Koreksi saldo (-Rp 10.000) untuk NIS 20260099. Alasan: Salah input jajan|
|                                                                                   |
+-----------------------------------------------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Navigasi Header**: Menu navigasi horizontal untuk mengakses semua modul.
*   **Metrik Total Saldo Beredar**: Menampilkan penjumlahan seluruh kolom `balance` dari tabel `students` yang terikat pada `school_id` sekolah tersebut.
*   **Top-up Tunai & VA**: Menampilkan akumulasi transaksi sukses per jenis metode pada hari ini (cash vs online gateway).
*   **Panel Pemberitahuan Audit**: Live feed aktivitas keuangan teraktual yang dilakukan oleh admin keuangan sendiri, ditarik dari tabel `audit_logs` untuk menjaga transparansi kerja.

---

### Screen 3: Manajemen Data Siswa & Registrasi Kartu
Tabel master data siswa untuk mengedit profil, melihat saldo, dan menghubungkan kartu RFID baru.
#### ASCII Mockup
```
+-----------------------------------------------------------------------------------+
| Data Siswa & Kartu                                                                |
| Filter: Kelas [ Semua [v] ]  [ Cari Nama / NIS...                      ]          |
|                                                                                   |
| +-------------------------------------------------------------------------------+ |
| | NIS      | Nama Lengkap    | Kelas | Saldo      | Status Kartu | Aksi         | |
| +-------------------------------------------------------------------------------+ |
| | 20260012 | Ahmad Subarjo   | 8-B   | Rp 75.000  | TERHUBUNG    | [Link Kartu] | |
| | 20260013 | Rian Hidayat    | 9-A   | Rp 12.000  | BELUM LINK   | [Link Kartu] | |
| +-------------------------------------------------------------------------------+ |
|                                                                                   |
+-----------------------------------------------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Filter Kelas & Cari Nama**: Memfilter data baris tabel secara real-time.
*   **Tombol "Link Kartu"**:
    *   *Aksi*: Klik tombol ini membuka modal popup **Registrasi Kartu**:
```
+--------------------------------------------------------+
|  REGISTRASI KARTU RFID/NFC BARU                        |
|  Siswa: Rian Hidayat (NIS: 20260013)                   |
|                                                        |
|  Tempelkan Kartu pada USB RFID Reader...               |
|  Nomor UID Kartu: [ 04:F8:A1:22                     ]  | --> Auto-fill via reader
|                                                        |
|  [ HUBUNGKAN KARTU ] (Teal)     [ Batal ]              |
+--------------------------------------------------------+
```
        *   *Alur*: Begitu kartu di-tap ke USB Reader yang tercolok ke komputer admin, kolom UID otomatis terisi (keyboard emulator). Klik "Hubungkan Kartu" -> Database Supabase mengeksekusi `update students set card_uid = '...' where id = '...'`. Status kartu siswa berubah menjadi TERHUBUNG di tabel utama.

---

### Screen 4: Modul Top-Up Tunai
Halaman input saldo bagi siswa yang menyerahkan uang tunai di koperasi/TU sekolah.
#### ASCII Mockup
```
+-----------------------------------------------------------------------------------+
| FORMULIR TOP-UP TUNAI (KASIR KOPERASI)                                            |
|                                                                                   |
| Cari Siswa                                                                        |
| NIS / Kode Siswa: [ 20260012            ] [ CARI ]                                |
|                                                                                   |
| Profil Siswa Terdeteksi:                                                          |
| - Nama Lengkap : Ahmad Subarjo                                                    |
| - Kelas        : 8-B                                                              |
| - Saldo Saat Ini: Rp 75.000                                                       |
|                                                                                   |
| Uang Tunai Diterima:                                                              |
| Nominal Top-Up : Rp [ 50000       ]                                               |
|                                                                                   |
| [ PROSES & CETAK BUKTI BAYAR ] (Orange)                                           |
+-----------------------------------------------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Cari Siswa (NIS/Kode)**:
    *   *Aksi*: Ketik NIS -> Klik "CARI" -> Query database Supabase untuk menarik data profil. Profil siswa harus ditampilkan terlebih dahulu demi menghindari kesalahan salah input uang ke rekening orang lain.
*   **Tombol "PROSES & CETAK BUKTI BAYAR"**:
    *   *Aksi*:
        1. Menjalankan transaksi DB untuk menambah saldo.
        2. Menyimpan entri ke tabel `transactions` dengan tipe `topup` dan metode `cash`.
        3. Secara otomatis menyisipkan data transaksi ke tabel `audit_logs` untuk diaudit Super Admin.
        4. Mengunduh struk bukti pembayaran tunai berformat PDF/cetak thermal.

---

### Screen 5: Modul Koreksi Saldo (Adjustment)
Modul krusial untuk menambah/mengurangi saldo siswa secara manual jika terjadi kesalahan input kasir.
#### ASCII Mockup
```
+-----------------------------------------------------------------------------------+
| KOREKSI / ADJUSTMENT SALDO SISWA                                                  |
|                                                                                   |
| Input NIS Siswa: [ 20260099            ] [ CARI ]                                 |
| Nama Siswa     : Siti Aminah (Kelas 7-A)                                          |
| Saldo Terkini  : Rp 15.000                                                        |
|                                                                                   |
| Jenis Koreksi  : (o) Kurangi Saldo    ( ) Tambah Saldo                            |
| Nominal Koreksi: Rp [ 10000       ]                                               |
|                                                                                   |
| Alasan Koreksi (Wajib diisi):                                                     |
| [ Salah input nominal belanja jajan di stan bude sari                             ] |
|                                                                                   |
| [ KUNCI & PROSES KOREKSI SALDO ] (Merah)                                          |
+-----------------------------------------------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Jenis Koreksi & Nominal**: Memilih tipe penyesuaian saldo.
*   **Alasan Koreksi (Wajib)**: Kolom teks bebas. Tombol proses akan terkunci (disabled) jika kolom alasan ini kosong.
*   **Tombol "KUNCI & PROSES KOREKSI SALDO"**:
    *   *Aksi*: Klik tombol -> Muncul modal konfirmasi keamanan: *"Aksi ini akan dicatat dalam Audit Log Dinas. Lanjutkan?"* -> Jika Ya, DB Supabase melakukan penyesuaian saldo, mencatat transaksi bertipe `adjustment`, dan menyisipkan entri audit log lengkap: `old_value` saldo siswa lama, `new_value` saldo siswa baru, dan string `reason` alasan koreksi.

---

### Screen 6: Laporan Keuangan & Export
Halaman rekapitulasi data keuangan per periode dan stan jajan.
#### ASCII Mockup
```
+-----------------------------------------------------------------------------------+
| Laporan Transaksi Kantin                                                          |
| Rentang Waktu: [ 01/06/2026 ] s.d [ 12/06/2026 ]                                  |
| Filter Stan  : [ Semua Stan Kantin    [v] ]                                       |
|                                                                                   |
| Ringkasan Penjualan Stan:                                                         |
| 1. Warung Bude Sari     : Rp 2.450.000 (350 Transaksi)                            |
| 2. Koperasi Minuman     : Rp 1.120.000 (180 Transaksi)                            |
|                                                                                   |
| [ EXPORT KE EXCEL (.XLSX) ]        [ EXPORT KE DOKUMEN PDF ]                      |
+-----------------------------------------------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Rentang Waktu & Filter Stan**: Kriteria sortir data laporan.
*   **Tombol Export**:
    *   *Aksi*: Mengueri database agregat `daily_summaries` dan `transactions` lalu membuat berkas Excel (`.xlsx`) atau PDF laporan penjualan untuk diserahkan kepada kepala sekolah atau pembagian uang tunai hasil jajan digital ke bude-bude kantin.
