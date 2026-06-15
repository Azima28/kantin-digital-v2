# 🌐 Spesifikasi Desain UI/UX — Role: Super Admin (Web Master Dashboard)

Dokumen ini mendefinisikan seluruh antarmuka pengguna (UI/UX) untuk **Dashboard Web Master Super Admin** secara lengkap dari awal hingga akhir, termasuk struktur halaman, modul audit log global, grafik statistik, konfigurasi sistem, dan integrasi backend.

---

## 1. Panduan Visual Umum (Branding & Global Layout)
*   **Tema Warna**: Primary Teal (`#0E8A8A`), Accent Orange (`#F2994A`), Latar Belakang (`#F8F9FA`).
*   **Font**: Poppins (Regular, Medium, SemiBold, Bold).
*   **Tata Letak**: Sidebar navigasi di sisi kiri (lebar tetap `260px`), header profil di kanan atas, area konten utama di kanan bawah. Panel menggunakan border-radius `8px` untuk platform desktop.

---

## 2. Struktur Alur Halaman (Sitemap Web)
```
[Web Login Master] ──> [Global Dashboard Statistics]
                       ├── [CRUD Manajemen Sekolah]
                       ├── [CRUD Manajemen Pengguna & Role]
                       ├── [Audit Log Real-Time Explorer]
                       └── [Konfigurasi Sistem Global]
```

---

## 3. Spesifikasi Rinci Halaman Demi Halaman

### Screen 1: Master Web Login Portal
Pintu masuk khusus untuk administrator utama sistem di URL: `admin.kantin.sekolah.id` (menggunakan rute verifikasi role = `super_admin`).
#### ASCII Mockup
```
+-------------------------------------------------------------+
|                                                             |
|                       KANTIN DIGITAL                        |
|                    Master Portal Super Admin                |
|                                                             |
|                  Master Email                               |
|                  [ superadmin@kantindigital.com        ]    |
|                                                             |
|                  Kata Sandi                                 |
|                  [ **********                          ]    |
|                                                             |
|                  [ LOGIN SUPER ADMIN ] (Teal)               |
|                                                             |
+-------------------------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Kolom Email & Password**: Input untuk kredensial Master Admin.
*   **Tombol "LOGIN SUPER ADMIN"**:
    *   *Aksi*: Autentikasi Supabase. Memvalidasi apakah status role pengguna adalah `super_admin`. Jika sukses, diarahkan ke **Screen 2: Global Dashboard Statistics**.

---

### Screen 2: Global Dashboard Statistics
Dashboard pusat monitoring perputaran data keuangan digital dari seluruh sekolah yang tergabung dalam sistem.
#### ASCII Mockup
```
+-----------------------------------------------------------------------------------+
| [Logo] Master Admin     | Beranda | Sekolah | User | Audit Log | Setelan | [Profil]   | --> Top Nav
+-----------------------------------------------------------------------------------+
|                                                                                   |
|  Selamat Datang di Master Control Panel, Super Admin                              |
|                                                                                   |
|  STATISTIK SISTEM GLOBAL                                                          |
|  +-----------------------+  +---------------------+  +-------------------------+  |
|  | Total Sekolah Terdaftar|  | Total Saldo Global  |  | Total Volume Transaksi  |  |
|  | 5 Sekolah             |  | Rp 102.500.000      |  | Rp 420.750.000          |  |
|  +-----------------------+  +---------------------+  +-------------------------+  |
|                                                                                   |
|  GRAFIK AKTIVITAS MINGGUAN (Chart)                                                |
|  [ ■ Sen ■ Sel ■ Rab ■ Kam ■ Jum ]  --> Bar chart visual volume harian            |
|                                                                                   |
+-----------------------------------------------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Navigasi Header**: Menu navigasi horizontal khusus Master Admin.
*   **Kartu Metrik Global**:
    *   *Total Sekolah*: Menghitung jumlah baris data pada tabel `schools`.
    *   *Total Saldo Global*: Penjumlahan kolom `balance` siswa di seluruh sekolah terdaftar.
    *   *Total Volume Transaksi*: Penjumlahan seluruh nilai mutasi sukses yang tercatat di database.
*   **Grafik Bar Chart**: Grafik visual kinerja mingguan volume jajan digital siswa (interaksi hover pada grafik menampilkan tooltip nominal harian).

---

### Screen 3: CRUD Manajemen Sekolah
Halaman konfigurasi untuk mendaftarkan, memperbarui, dan menonaktifkan sekolah mitra kantin digital.
#### ASCII Mockup
```
+-----------------------------------------------------------------------------------+
| Kelola Sekolah Mitra                                                              |
| [ + MITRAKAN SEKOLAH BARU ]                                                       |
|                                                                                   |
| +-------------------------------------------------------------------------------+ |
| | Logo  | Nama Sekolah        | Alamat              | Siswa Aktif | Aksi        | |
| +-------------------------------------------------------------------------------+ |
| | [Img] | SMP Terpadu Kota    | Jl. Merdeka No. 12  | 850 Siswa   | [Edit] [Del]| |
| | [Img] | SMA Negeri 3        | Jl. Pemuda No. 45   | 1.200 Siswa | [Edit] [Del]| |
| +-------------------------------------------------------------------------------+ |
|                                                                                   |
+-----------------------------------------------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Tombol "+ MITRAKAN SEKOLAH BARU"**:
    *   *Aksi*: Membuka dialog form input data sekolah (Nama, Alamat, Upload File Logo Sekolah, Nomor Telepon, setoran Koperasi default). Menyimpan data baru ke tabel `schools`.
*   **Tombol "Edit" & "Del"**:
    *   *Aksi*: Memperbarui data alamat/kontak sekolah atau menghapus data sekolah (jika dihapus, status sekolah berubah menjadi `is_active = false` / soft delete agar histori transaksi tidak rusak).

---

### Screen 4: CRUD Manajemen Pengguna & Role
Mengelola akun operator admin sekolah, petugas kantin, dan akun siswa.
#### ASCII Mockup
```
+-----------------------------------------------------------------------------------+
| Kelola Akun & Role Pengguna                                                      |
| Cari User: [ Ahmad                                ]  Filter Role: [ Siswa    [v] ]|
|                                                                                   |
| +-------------------------------------------------------------------------------+ |
| | Nama Lengkap    | Email / Username              | Sekolah      | Status | Aksi| |
| +-------------------------------------------------------------------------------+ |
| | Ahmad Subarjo   | ahmad.subarjo@sekolah.sch.id  | SMP Terpadu  | AKTIF  | [x] | | --> [x] Toggle
| | Budi Hartono    | budi@smkterpadu.sch.id        | SMK Terpadu  | BLOKIR | [ ] | |
| +-------------------------------------------------------------------------------+ |
|                                                                                   |
+-----------------------------------------------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Cari User & Filter Role**: Fitur pencarian terpadu yang memfilter baris database `users` berdasarkan input teks dan enum `role`.
*   **Toggle Status (Switch ON/OFF)**:
    *   *Aksi*: Mengubah status aktif user secara instan.
        *   *Jika diklik OFF*: Menghapus hak akses login pengguna tersebut di Supabase Auth dan merubah kolom `is_active` menjadi `false` di database (secara instan melarang login/jajan di kantin).

---

### Screen 5: Audit Log Real-Time Explorer (Pencegahan Korupsi)
Layar kronologi aktivitas manual admin keuangan untuk pengawasan keamanan data saldo.
#### ASCII Mockup
```
+-----------------------------------------------------------------------------------+
| TIMELINE AUDIT LOG SISTEM GLOBAL (Real-Time)                                      |
| Filter Sekolah: [ Semua Sekolah [v] ]    Filter Aksi: [ Koreksi Saldo         [v] ]|
|                                                                                   |
| +-------------------------------------------------------------------------------+ |
| | Waktu    | Sekolah     | Admin / Pelaksana | Aksi       | Detail Koreksi      | |
| +-------------------------------------------------------------------------------+ |
| | 12:10:05 | SMP Terpadu | Budi (Keuangan)   | Deduct     | Siswa: Siti (7-A)   | |
| |          |             |                   |            | Nilai: Rp 10.000    | |
| |          |             |                   |            | Ket  : Salah jajan  | |
| +-------------------------------------------------------------------------------+ |
| | 10:45:00 | SMA Negeri 3| Riska (Keuangan)  | Topup Cash | Siswa: Rian (9-C)   | |
| |          |             |                   |            | Nilai: Rp 50.000    | |
| +-------------------------------------------------------------------------------+ |
+-----------------------------------------------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Tabel Kronologi (Log Timeline)**:
    *   Data ditarik secara real-time dari tabel `audit_logs` menggunakan channel subscription Supabase.
    *   Menampilkan data detail sebelum dan sesudah perubahan (`old_value` vs `new_value` yang disimpan dalam format JSONB).
    *   Menampilkan IP Address pelaksana aksi dan perangkat yang digunakan (User Agent) untuk pelacakan forensik digital jika terjadi anomali kas keuangan.
*   *Keamanan*: Halaman ini tidak memiliki tombol edit, hapus, atau manipulasi data apa pun. Bersifat 100% *read-only*.

---

### Screen 6: Konfigurasi Sistem Global
Pengaturan backend utama, token, dan API.
#### ASCII Mockup
```
+-----------------------------------------------------------------------------------+
| Setelan Sistem Global                                                             |
|                                                                                   |
| Integrasi Payment Gateway (Midtrans Sandbox / Production)                         |
| Client Key: [ Client-Key-Prod-098230982038902809                                ] |
| Server Key: [ Server-Key-Prod-789012389028309823                                ] |
|                                                                                   |
| Pengaturan FCM Push Notification (Firebase Service Account JSON)                  |
| [ { "type": "service_account", "project_id": "kantin-digital-39", ... }       ]   |
|                                                                                   |
| Mode Pemeliharaan Sistem (Maintenance Mode)                         [ Toggle OFF ]|
|                                                                                   |
| [ SIMPAN SETELAN GLOBAL ] (Teal)                                                  |
+-----------------------------------------------------------------------------------+
```
#### Elemen & Aksi Interaksi
*   **Kolom API Midtrans & FCM Key**: Input sensitif untuk menghubungkan payment gateway dan push notification.
*   **Toggle Maintenance Mode**:
    *   *Aksi*: Jika diaktifkan (ON), seluruh aplikasi mobile siswa dan petugas kantin akan memunculkan layar penutupan sistem sementara (Server Under Maintenance) dan memblokir request API baru dari luar.
*   **Tombol "SIMPAN SETELAN GLOBAL"**: Menyimpan enkripsi konfigurasi sistem ke tabel konfigurasi database.
