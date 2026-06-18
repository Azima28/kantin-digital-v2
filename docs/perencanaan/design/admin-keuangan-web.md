# 📱 Spesifikasi Desain UI/UX — Role: Admin Keuangan (Mobile App)

Dokumen ini mendefinisikan **seluruh** antarmuka pengguna (UI/UX) untuk **Aplikasi Mobile Admin Keuangan / Tata Usaha Sekolah** secara lengkap dan detail, mencakup setiap screen, state, komponen, alur data, dan interaksi pengguna dari awal hingga akhir.

---

## 1. Panduan Visual Umum (Branding & Design System)

*   **Tipografi**: `Be Vietnam Pro` (Google Fonts) — bersih, profesional, mudah dibaca.
*   **Tema Warna**:
    *   *Primary Teal* (`#003434`): Warna utama brand untuk header, tombol aksi, highlight data.
    *   *Accent Orange* (`#904D00`): Aksen untuk indikator top-up, peringatan, atau nominal positif.
    *   *Success Green* (`#006A35`): Indikator transaksi berhasil, saldo aman, status aktif.
    *   *Danger Red* (`#BA1A1A`): Indikator koreksi, saldo kurang, akun diblokir, refund.
    *   *Background* (`#FBF9F8`): Latar belakang layar utama, cream terang.
    *   *Card White* (`#FFFFFF`): Latar kartu konten, bersih dan mudah dibaca.
    *   *Border* (`#E4E2E1`): Garis pemisah tipis antar elemen.
    *   *Text Gray* (`#6F7978`): Teks label sekunder, placeholder, timestamp.
*   **Karakteristik Layout Mobile**:
    *   *Bento Card Radius*: `24px` untuk semua kartu konten utama.
    *   *Input Field Radius*: `12px` untuk semua input form.
    *   *Safe Area*: Semua konten menghormati safe area iOS/Android (notch & home indicator).
    *   *Padding Horizontal*: `20px` standar untuk semua konten layar.
    *   *Bottom Navigation Bar*: 4 tab — Beranda, Siswa, Transaksi, Laporan.
    *   *App Bar*: Teks judul besar (Bold 20px) di kiri, ikon aksi di kanan.
*   **Komponen Reusable**:
    *   *Bento Card*: Container putih, radius 24px, shadow tipis (0px 4px 20px rgba(0,0,0,4%)).
    *   *Status Badge*: Pill oval kecil berwarna sesuai status (hijau = aktif, merah = blokir, oranye = pending).
    *   *Snackbar Floating*: Notifikasi bawah layar dengan radius 12px, icon, dan teks.
    *   *iOS Grab Handle*: Strip abu-abu `36x5px` di puncak setiap bottom sheet.
    *   *Cupertino Dialog*: Dialog konfirmasi bergaya iOS untuk semua aksi destruktif.

---

## 2. Struktur Alur Layar (Sitemap Mobile)

```
[Login Screen]
     │
     └──► [Dashboard Beranda]
              │
              ├──► [Manajemen Siswa]
              │         ├──► [Detail Siswa]
              │         │         ├──► [Registrasi / Ganti Kartu NFC]
              │         │         └──► [Riwayat Transaksi Siswa]
              │         └──► [Cari Siswa]
              │
              ├──► [Modul Transaksi]
              │         ├──► [Top-Up Tunai]
              │         │         ├──► [Cari Siswa → Konfirmasi Top-Up]
              │         │         └──► [Struk Sukses]
              │         ├──► [Koreksi Saldo]
              │         │         ├──► [Cari Siswa → Form Koreksi]
              │         │         ├──► [Konfirmasi Koreksi (Dialog Keamanan)]
              │         │         └──► [Struk Koreksi Sukses]
              │         └──► [Riwayat Transaksi Admin]
              │                   └──► [Detail Transaksi]
              │
              ├──► [Laporan Keuangan]
              │         ├──► [Ringkasan Periode]
              │         ├──► [Detail per Stan Kantin]
              │         ├──► [Grafik Tren Transaksi]
              │         └──► [Export & Kirim Laporan]
              │
              ├──► [Audit Log (Riwayat Aktivitas Saya)]
              │         └──► [Detail Log Perubahan]
              │
              └──► [Profil & Pengaturan Akun]
                        ├──► [Edit Profil]
                        ├──► [Ubah Kata Sandi]
                        └──► [Logout]
```

---

## 3. Spesifikasi Rinci Layar Demi Layar

---

### Screen 1: Login Screen

Form masuk khusus untuk akun Admin Keuangan / Tata Usaha sekolah.

#### ASCII Mockup
```
+------------------------------------------+
|                                          |
|           [Logo Kantin Digital]          |
|                                          |
|  Yuk, Masuk!                             |
|  Kelola keuangan kantin sekolah dengan   |
|  mudah, transparan, dan aman.            |
|                                          |
|  Username / Email                        |
|  [ tatausaha@smp-terpadu.sch.id      ]   |
|  ----------------------------------------|
|  Kata Sandi                              |
|  [ ••••••••••••••              ] [👁️]    |
|  ----------------------------------------|
|                                          |
|  [ MASUK ]  ← Tombol Teal penuh          |
|                                          |
|  Lupa kata sandi? Hubungi Super Admin    |
|                                          |
+------------------------------------------+
```

#### Elemen & Aksi Interaksi
*   **Input Email/Username**: Mendukung login menggunakan `email`, `username`, atau `NISN admin`.
*   **Input Kata Sandi**: Field obscured dengan toggle ikon mata.
*   **Tombol "MASUK"**:
    *   *Aksi*: Query tabel `profiles` untuk memvalidasi kredensial dan role `petugas_keuangan`. Jika role bukan `petugas_keuangan`, tampilkan Snackbar merah: *"Akses ditolak. Akun ini bukan akun admin keuangan."*
    *   Jika berhasil, navigasi ke **Screen 2: Dashboard Beranda**.
*   **State Loading**: Tombol berubah menjadi `CupertinoActivityIndicator` warna putih.

---

### Screen 2: Dashboard Beranda

Layar utama setelah login, menampilkan ringkasan keuangan sekolah hari ini.

#### ASCII Mockup
```
+------------------------------------------+
|  Selamat Pagi,                           |
|  Budi Hartono 👋                          |
|  Admin Keuangan · SMP Terpadu            |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │  💰 Total Saldo Beredar          │    |
|  │  Rp 14.520.000                   │    |
|  │  ▲ +Rp 1.250.000 hari ini        │    |
|  └──────────────────────────────────┘    |
|                                          |
|  ┌──────────────┐  ┌──────────────────┐  |
|  │ 💵 Top-Up    │  │ 📊 Koreksi Hari  │  |
|  │ Tunai Hari   │  │ Ini              │  |
|  │ Rp 1.250.000 │  │ 3 Transaksi      │  |
|  │ 18 Transaksi │  │ -Rp 35.000 net   │  |
|  └──────────────┘  └──────────────────┘  |
|                                          |
|  Aksi Cepat                              |
|  ┌─────────┐ ┌─────────┐ ┌──────────┐   |
|  │ [💵]    │ │ [⚖️]    │ │ [📋]     │   |
|  │ Top-Up  │ │ Koreksi │ │ Laporan  │   |
|  └─────────┘ └─────────┘ └──────────┘   |
|                                          |
|  Aktivitas Terbaru                       |
|  ┌──────────────────────────────────┐    |
|  │ ● Top-Up Rp 50.000 · Ahmad  12:10│   |
|  │ ● Koreksi -Rp 10.000 · Siti 10:45│   |
|  │ ● Top-Up Rp 100.000 · Rian  09:20│   |
|  │            Lihat Semua →         │    |
|  └──────────────────────────────────┘    |
|                                          |
+------------------------------------------+
| [🏠 Beranda] [👤 Siswa] [💸 Transaksi] [📊] |
+------------------------------------------+
```

#### Elemen & Aksi Interaksi
*   **Header Salam**: Menampilkan nama lengkap dan sekolah penugasan dari tabel `profiles` dan `finance_officers`.
*   **Kartu Total Saldo Beredar**: Query `SUM(balance)` dari tabel `students` yang `school_id` sesuai. Perubahan harian ditampilkan sebagai delta (+/-).
*   **Kartu Top-Up & Koreksi**: Menampilkan agregat hari ini (filter `DATE(created_at) = TODAY`).
*   **Tombol Aksi Cepat**:
    *   *Top-Up* → Navigasi ke **Screen 6: Form Top-Up Tunai**.
    *   *Koreksi* → Navigasi ke **Screen 9: Form Koreksi Saldo**.
    *   *Laporan* → Navigasi ke **Screen 13: Laporan Keuangan**.
*   **Feed Aktivitas Terbaru**: 3 entri terbaru dari `audit_logs` milik admin ini. Tap "Lihat Semua" → **Screen 12: Audit Log**.

---

### Screen 3: Manajemen Siswa (Daftar)

Daftar master data semua siswa di sekolah penugasan admin keuangan.

#### ASCII Mockup
```
+------------------------------------------+
|  < Kembali   Manajemen Siswa       [🔍]  |
|                                          |
|  [ 🔍 Cari nama, NIS, atau kelas...  ]   |
|                                          |
|  Filter: [Semua Kelas ▼]  [Status ▼]    |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │  👤  Ahmad Subarjo               │    |
|  │      NIS: 20260012 · Kelas 8-B   │    |
|  │      Saldo: Rp 75.000            │    |
|  │      Kartu: ● TERHUBUNG    [>]   │    |
|  └──────────────────────────────────┘    |
|  ┌──────────────────────────────────┐    |
|  │  👤  Rian Hidayat                │    |
|  │      NIS: 20260013 · Kelas 9-A   │    |
|  │      Saldo: Rp 12.000            │    |
|  │      Kartu: ○ BELUM TERHUBUNG [>]│    |
|  └──────────────────────────────────┘    |
|  ┌──────────────────────────────────┐    |
|  │  👤  Siti Aminah                 │    |
|  │      NIS: 20260099 · Kelas 7-A   │    |
|  │      Saldo: Rp 3.000             │    |
|  │      Kartu: ● TERHUBUNG    [>]   │    |
|  └──────────────────────────────────┘    |
|                                          |
|  Menampilkan 120 siswa                   |
+------------------------------------------+
| [🏠 Beranda] [👤 Siswa] [💸 Transaksi] [📊] |
+------------------------------------------+
```

#### Elemen & Aksi Interaksi
*   **Search Bar**: Mencari real-time berdasarkan `full_name`, `nisn`, atau `class`.
*   **Filter Kelas**: Dropdown yang memuat daftar kelas unik dari database.
*   **Filter Status**: Dropdown `Semua / Aktif / Diblokir / Saldo Rendah (<Rp 5.000)`.
*   **Kartu Siswa**:
    *   Indikator status kartu: Titik hijau (terhubung) / abu-abu (belum terhubung).
    *   Saldo merah jika < Rp 5.000.
    *   Tap kartu → **Screen 4: Detail Siswa**.

---

### Screen 4: Detail Siswa

Halaman detail lengkap profil siswa termasuk saldo, informasi kartu, dan riwayat transaksi.

#### ASCII Mockup
```
+------------------------------------------+
|  < Kembali       Profil Siswa            |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │         👤 (Avatar Inisial)      │    |
|  │         Ahmad Subarjo            │    |
|  │         [ AKTIF ]                │    |
|  │                                  │    |
|  │  📧 ahmad@sekolah.sch.id         │    |
|  │  🏫 Kelas 8-B · SMP Terpadu     │    |
|  │  🪪 NIS: 20260012                │    |
|  └──────────────────────────────────┘    |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │  💳 Informasi Saldo & Kartu      │    |
|  │  ─────────────────────────────   │    |
|  │  Saldo Aktif       Rp 75.000     │    |
|  │  Status Kartu      ● TERHUBUNG   │    |
|  │  UID Kartu         04:F8:A1:22   │    |
|  │  Terakhir Tap      17 Jun 12:05  │    |
|  └──────────────────────────────────┘    |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │  ⚡ Aksi Admin                   │    |
|  │  ─────────────────────────────   │    |
|  │  💵 Top-Up Saldo              >  │    |
|  │  ⚖️  Koreksi Saldo             >  │    |
|  │  📶 Registrasi / Ganti Kartu  >  │    |
|  └──────────────────────────────────┘    |
|                                          |
|  Riwayat Transaksi (30 hari terakhir)    |
|  ┌──────────────────────────────────┐    |
|  │ + Rp 50.000  Top-Up Tunai  12:10 │    |
|  │ - Rp 22.000  Belanja      11:45  │    |
|  │ + Rp 100.000 Top-Up VA     09:00 │    |
|  │           Lihat Semua →          │    |
|  └──────────────────────────────────┘    |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │  🚫 Blokir / Aktifkan Akun    >  │    |
|  └──────────────────────────────────┘    |
+------------------------------------------+
```

#### Elemen & Aksi Interaksi
*   **Header Profil**: Nama, status badge, email, kelas, NIS.
*   **Kartu Saldo & Kartu**: UID kartu NFC, kapan terakhir digunakan.
*   **Aksi Admin**:
    *   *Top-Up Saldo* → Buka **Screen 6** dengan siswa sudah pre-filled.
    *   *Koreksi Saldo* → Buka **Screen 9** dengan siswa sudah pre-filled.
    *   *Registrasi Kartu* → Buka **Screen 5**.
*   **Riwayat Transaksi**: Preview 3 transaksi terakhir. Tap "Lihat Semua" → **Screen 11**.
*   **Blokir Akun**: Tombol merah. Jika di-tap, muncul Cupertino Dialog konfirmasi. Jika dikonfirmasi, update `is_active = false` di tabel `profiles`.

---

### Screen 5: Registrasi / Ganti Kartu NFC

Layar untuk menautkan atau mengganti kartu RFID/NFC siswa.

#### ASCII Mockup
```
+------------------------------------------+
|  < Kembali    Registrasi Kartu NFC       |
|                                          |
|  Siswa: Ahmad Subarjo (NIS: 20260012)    |
|  Kelas: 8-B · SMP Terpadu               |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │          📶 SIAP MEMINDAI        │    |
|  │                                  │    |
|  │    Tempelkan Kartu Siswa ke      │    |
|  │    sensor NFC perangkat ini      │    |
|  │                                  │    |
|  │         (( 🛜 ))                  │    |
|  │                                  │    |
|  │    Atau masukkan UID manual:     │    |
|  └──────────────────────────────────┘    |
|                                          |
|  UID Kartu (Manual Fallback)             |
|  [ 04:F8:A1:22                      ]    |
|  ─────────────────────────────────────── |
|  ℹ️  UID lama: 04:F8:A1:22 (aktif)       |
|                                          |
|  [ HUBUNGKAN KARTU ] (Teal penuh)        |
|                                          |
|  [ Hapus Tautan Kartu ] (Merah Outline)  |
+------------------------------------------+
```

#### Elemen & Aksi Interaksi
*   **Area NFC Tap**: Memindai kartu secara aktif. Setelah kartu terdeteksi, UID otomatis terisi di field manual.
*   **Input UID Manual**: Fallback jika NFC tidak tersedia. Admin bisa mengetik UID dari stiker kartu.
*   **Info UID Lama**: Menampilkan kartu yang sedang terhubung (jika ada) sebagai referensi.
*   **Tombol "Hubungkan Kartu"**:
    *   *Aksi*: Validasi UID tidak duplikat. `UPDATE students SET card_uid = '...' WHERE id = '...'`. Catat di `audit_logs` dengan `action_type = 'REGISTRASI_KARTU'`.
    *   Snackbar hijau: *"Kartu berhasil ditautkan ke Ahmad Subarjo!"*
*   **Hapus Tautan Kartu**: Muncul dialog konfirmasi. Jika ya, set `card_uid = NULL`.

---

### Screen 5B: State Berhasil Registrasi Kartu

```
+------------------------------------------+
|  < Kembali    Registrasi Kartu NFC       |
|                                          |
|         ┌───────────────────┐            |
|         │                   │            |
|         │        ✔          │  ← Hijau   |
|         │  Kartu Terhubung! │            |
|         │                   │            |
|         └───────────────────┘            |
|                                          |
|  Kartu NFC berhasil ditautkan ke:        |
|                                          |
|  Nama    : Ahmad Subarjo                 |
|  Kelas   : 8-B                           |
|  UID     : 04:F8:A1:22                   |
|  Waktu   : 17 Jun 2026, 13:25            |
|                                          |
|  [ KEMBALI KE PROFIL SISWA ]             |
+------------------------------------------+
```

---

### Screen 6: Form Top-Up Tunai (Step 1 — Cari Siswa)

Langkah pertama top-up: mencari siswa penerima saldo.

#### ASCII Mockup
```
+------------------------------------------+
|  < Kembali         Top-Up Tunai          |
|                                          |
|  LANGKAH 1 DARI 3 — Cari Siswa          |
|  ●────────────────────────               |
|                                          |
|  Masukkan NIS atau Nama Siswa:           |
|  [ 20260012                         ]    |
|  ─────────────────────────────────────── |
|                                          |
|  [ 🔍 CARI SISWA ]                       |
|                                          |
|  ─── atau pilih dari daftar ───          |
|                                          |
|  Siswa Terakhir Ditop-Up:                |
|  ┌──────────────────────────────────┐    |
|  │ Ahmad Subarjo · 8-B · Rp 75.000  │    |
|  │ Rian Hidayat  · 9-A · Rp 12.000  │    |
|  └──────────────────────────────────┘    |
+------------------------------------------+
```

---

### Screen 7: Form Top-Up Tunai (Step 2 — Input Nominal)

Langkah kedua: konfirmasi profil siswa dan input nominal top-up.

#### ASCII Mockup
```
+------------------------------------------+
|  < Kembali         Top-Up Tunai          |
|                                          |
|  LANGKAH 2 DARI 3 — Konfirmasi & Nominal |
|  ●●──────────────────────────            |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │  ✔ Siswa Ditemukan               │    |
|  │  ─────────────────────────────   │    |
|  │  Nama    Ahmad Subarjo           │    |
|  │  NIS     20260012                │    |
|  │  Kelas   8-B · SMP Terpadu       │    |
|  │  Saldo   Rp 75.000               │    |
|  └──────────────────────────────────┘    |
|                                          |
|  Nominal Top-Up (Uang Tunai Diterima)    |
|  Rp [ 50000                         ]    |
|  ─────────────────────────────────────── |
|                                          |
|  Pilih Cepat:                            |
|  [Rp 20.000] [Rp 50.000] [Rp 100.000]   |
|  [Rp 150.000] [Rp 200.000] [Rp 500.000] |
|                                          |
|  Saldo Baru (Preview): Rp 125.000        |
|                                          |
|  [ LANJUT → KONFIRMASI ]                 |
+------------------------------------------+
```

#### Elemen & Aksi Interaksi
*   **Pilih Cepat**: Chip nominal umum agar input lebih cepat. Tap → nominal terisi otomatis.
*   **Preview Saldo Baru**: Real-time kalkulasi `saldo_lama + nominal_input`.
*   **Validasi**: Nominal harus > 0 dan kelipatan Rp 1.000. Tombol disabled jika invalid.

---

### Screen 8: Konfirmasi Top-Up & Struk Digital

Langkah ketiga: konfirmasi akhir sebelum transaksi diproses.

#### ASCII Mockup — Step 3: Konfirmasi
```
+------------------------------------------+
|  < Kembali         Top-Up Tunai          |
|                                          |
|  LANGKAH 3 DARI 3 — Konfirmasi          |
|  ●●●─────────────────────────────        |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │  📋 RINGKASAN TOP-UP TUNAI       │    |
|  │  ─────────────────────────────   │    |
|  │  Nama Siswa    Ahmad Subarjo     │    |
|  │  NIS           20260012          │    |
|  │  Kelas         8-B               │    |
|  │  Saldo Lama    Rp 75.000         │    |
|  │  Nominal Top-Up  +Rp 50.000      │    |
|  │  ─────────────────────────────   │    |
|  │  Saldo Baru    Rp 125.000  ✔     │    |
|  │  Metode        Tunai (Cash)      │    |
|  │  Admin         Budi Hartono      │    |
|  │  Waktu         17 Jun 13:25      │    |
|  └──────────────────────────────────┘    |
|                                          |
|  [ ✔ PROSES TOP-UP ] (Orange penuh)      |
|                                          |
|  Aksi ini akan dicatat dalam audit log   |
+------------------------------------------+
```

#### ASCII Mockup — State Berhasil
```
+------------------------------------------+
|                                          |
|         ┌───────────────────┐            |
|         │                   │            |
|         │   💰 Rp 50.000    │  ← Hijau   |
|         │   Top-Up Berhasil!│            |
|         │                   │            |
|         └───────────────────┘            |
|                                          |
|  Saldo Ahmad Subarjo berhasil ditambah.  |
|                                          |
|  Saldo Baru: Rp 125.000                  |
|  Waktu     : 17 Jun 2026, 13:25:07       |
|  Kode Ref  : TXN-20260617-0024           |
|                                          |
|  [ 🖨️ CETAK STRUK / BAGIKAN ]            |
|  [ ← KEMBALI KE BERANDA ]               |
+------------------------------------------+
```

#### Alur Backend
1. `INSERT INTO transactions (student_id, type, amount, method, admin_id) VALUES (...)`.
2. `UPDATE students SET balance = balance + nominal WHERE id = student_id`.
3. `INSERT INTO audit_logs (actor_name, action_type, old_value, new_value, description)`.
4. Tampilkan struk digital (kode referensi unik + timestamp).

---

### Screen 9: Form Koreksi Saldo (Step 1 — Cari Siswa)

Modul penting untuk mengoreksi saldo akibat kesalahan kasir atau input.

#### ASCII Mockup
```
+------------------------------------------+
|  < Kembali       Koreksi Saldo           |
|                                          |
|  ⚠️  Modul Koreksi Terbatas              |
|  Setiap koreksi wajib beralasan dan      |
|  akan dicatat permanen di audit log.     |
|                                          |
|  LANGKAH 1 DARI 3 — Cari Siswa          |
|  ●────────────────────────               |
|                                          |
|  NIS atau Nama Siswa:                    |
|  [ 20260099                         ]    |
|  ─────────────────────────────────────── |
|                                          |
|  [ 🔍 CARI SISWA ]                       |
+------------------------------------------+
```

---

### Screen 10: Form Koreksi Saldo (Step 2 — Detail Koreksi)

#### ASCII Mockup
```
+------------------------------------------+
|  < Kembali       Koreksi Saldo           |
|                                          |
|  LANGKAH 2 DARI 3 — Detail Koreksi      |
|  ●●──────────────────────────            |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │  Siswa   : Siti Aminah           │    |
|  │  Kelas   : 7-A · SMP Terpadu     │    |
|  │  Saldo Terkini: Rp 15.000        │    |
|  └──────────────────────────────────┘    |
|                                          |
|  Jenis Koreksi                           |
|  [● Kurangi Saldo] [○ Tambah Saldo]      |
|                                          |
|  Nominal Koreksi                         |
|  Rp [ 10000                         ]    |
|  ─────────────────────────────────────── |
|                                          |
|  Saldo Setelah Koreksi: Rp 5.000         |
|                                          |
|  Alasan Koreksi (Wajib)                  |
|  ┌──────────────────────────────────┐    |
|  │ Salah input nominal belanja      │    |
|  │ jajan di stan Bude Sari tgl      │    |
|  │ 17 Juni 2026...                  │    |
|  └──────────────────────────────────┘    |
|  Minimal 10 karakter.                    |
|                                          |
|  [ LANJUT → KONFIRMASI ]                 |
|   (Disabled jika alasan kosong)          |
+------------------------------------------+
```

#### Elemen & Aksi Interaksi
*   **Radio Jenis Koreksi**: Toggle antara Kurangi / Tambah saldo.
*   **Preview Saldo**: Real-time update. Jika kurangi dan nominal > saldo, tampilkan peringatan merah.
*   **Alasan Koreksi**: Wajib diisi (minimal 10 karakter). Tombol lanjut disabled jika kosong.
*   **Validasi Saldo Minus**: Koreksi pengurangan tidak boleh melebihi saldo terkini.

---

### Screen 11: Konfirmasi Koreksi (Dialog Keamanan)

#### ASCII Mockup — Dialog Konfirmasi
```
+------------------------------------------+
|                                          |
|  ┌──────────────────────────────────┐    |
|  │  ⚠️  KONFIRMASI KOREKSI SALDO    │    |
|  │                                  │    |
|  │  Aksi ini bersifat permanen dan  │    |
|  │  akan tercatat dalam Audit Log   │    |
|  │  yang dapat diperiksa oleh       │    |
|  │  Super Admin kapan saja.         │    |
|  │                                  │    |
|  │  Siswa : Siti Aminah (7-A)       │    |
|  │  Jenis : Kurangi Saldo           │    |
|  │  Nominal: -Rp 10.000             │    |
|  │  Saldo baru: Rp 5.000            │    |
|  │  Alasan: Salah input nominal...  │    |
|  │                                  │    |
|  │  [ Batal ]   [ ✔ PROSES ]        │    |
|  └──────────────────────────────────┘    |
+------------------------------------------+
```

#### ASCII Mockup — State Sukses
```
+------------------------------------------+
|                                          |
|         ┌───────────────────┐            |
|         │   ✔ KOREKSI       │            |
|         │   BERHASIL        │            |
|         └───────────────────┘            |
|                                          |
|  Saldo Siti Aminah berhasil dikoreksi.   |
|                                          |
|  Saldo Lama    : Rp 15.000               |
|  Koreksi       : -Rp 10.000              |
|  Saldo Baru    : Rp 5.000                |
|  Dicatat oleh  : Budi Hartono            |
|  Waktu         : 17 Jun 2026, 13:40      |
|  Kode Koreksi  : ADJ-20260617-0003       |
|                                          |
|  [ ← KEMBALI KE BERANDA ]               |
+------------------------------------------+
```

---

### Screen 12: Riwayat Transaksi Admin

Daftar seluruh transaksi top-up dan koreksi yang dilakukan oleh admin keuangan ini.

#### ASCII Mockup
```
+------------------------------------------+
|  < Kembali    Riwayat Transaksi    [📅]  |
|                                          |
|  Filter: [Semua ▼]  [17 Jun 2026 ▼]     |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │ ↑ TOP-UP   Ahmad Subarjo   13:25 │    |
|  │   +Rp 50.000 · Tunai            │    |
|  │   Ref: TXN-20260617-0024         │    |
|  └──────────────────────────────────┘    |
|  ┌──────────────────────────────────┐    |
|  │ ⚖️ KOREKSI  Siti Aminah    13:40 │    |
|  │   -Rp 10.000 · Kurangi Saldo    │    |
|  │   Ref: ADJ-20260617-0003         │    |
|  └──────────────────────────────────┘    |
|  ┌──────────────────────────────────┐    |
|  │ ↑ TOP-UP   Rian Hidayat    12:05 │    |
|  │   +Rp 100.000 · Tunai           │    |
|  │   Ref: TXN-20260617-0023         │    |
|  └──────────────────────────────────┘    |
|                                          |
|  Total hari ini: +Rp 150.000 (Top-Up)   |
|                  -Rp 10.000 (Koreksi)   |
+------------------------------------------+
| [🏠 Beranda] [👤 Siswa] [💸 Transaksi] [📊] |
+------------------------------------------+
```

#### Elemen & Aksi Interaksi
*   **Filter Jenis**: Semua / Top-Up / Koreksi / Registrasi Kartu.
*   **Filter Tanggal**: Date picker iOS style untuk memilih rentang tanggal.
*   **Tap Kartu Transaksi** → **Screen 12B: Detail Transaksi**.
*   **Ringkasan Footer**: Akumulasi per jenis untuk tanggal yang dipilih.

---

### Screen 12B: Detail Transaksi

#### ASCII Mockup
```
+------------------------------------------+
|  < Kembali       Detail Transaksi        |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │  💰 TOP-UP TUNAI                 │    |
|  │  TXN-20260617-0024               │    |
|  │                                  │    |
|  │  Nominal        +Rp 50.000       │    |
|  │  Siswa          Ahmad Subarjo    │    |
|  │  NIS            20260012         │    |
|  │  Kelas          8-B              │    |
|  │  Saldo Sebelum  Rp 75.000        │    |
|  │  Saldo Sesudah  Rp 125.000       │    |
|  │  Metode         Tunai (Cash)     │    |
|  │  Admin          Budi Hartono     │    |
|  │  Waktu          17 Jun, 13:25:07 │    |
|  └──────────────────────────────────┘    |
|                                          |
|  [ 🖨️ CETAK ULANG STRUK ]               |
+------------------------------------------+
```

---

### Screen 13: Laporan Keuangan (Ringkasan Periode)

Halaman rekapitulasi keuangan sekolah per periode waktu.

#### ASCII Mockup
```
+------------------------------------------+
|  < Kembali    Laporan Keuangan           |
|                                          |
|  Pilih Periode:                          |
|  [Hari Ini ▼] [01 Jun] – [17 Jun 2026]  |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │  📈 Ringkasan Periode            │    |
|  │  ─────────────────────────────   │    |
|  │  Total Top-Up Tunai  Rp 8.450.000│    |
|  │  Total Top-Up VA     Rp 5.200.000│    |
|  │  Total Koreksi        -Rp 120.000│    |
|  │  ─────────────────────────────   │    |
|  │  Net Saldo Masuk    Rp 13.530.000│    |
|  │  Jumlah Transaksi      287       │    |
|  └──────────────────────────────────┘    |
|                                          |
|  Pendapatan per Stan Kantin:             |
|  ┌──────────────────────────────────┐    |
|  │  1. Warung Bude Sari             │    |
|  │     Rp 2.450.000 · 350 Transaksi │    |
|  │  2. Koperasi Minuman             │    |
|  │     Rp 1.120.000 · 180 Transaksi │    |
|  │  3. Stan Bakso Pak Harto         │    |
|  │     Rp 890.000 · 95 Transaksi    │    |
|  │  4. Stan Nasi Goreng             │    |
|  │     Rp 780.000 · 88 Transaksi    │    |
|  └──────────────────────────────────┘    |
|                                          |
|  [📊 Grafik Tren]  [📤 Export Laporan]  |
+------------------------------------------+
| [🏠 Beranda] [👤 Siswa] [💸 Transaksi] [📊] |
+------------------------------------------+
```

#### Elemen & Aksi Interaksi
*   **Pilih Periode**: Preset (Hari Ini / Minggu Ini / Bulan Ini / Custom). Custom membuka date range picker.
*   **Kartu Ringkasan**: Query agregat dari tabel `transactions` dengan filter `school_id` dan rentang tanggal.
*   **List Pendapatan per Stan**: Query `GROUP BY canteen_id` dengan `SUM(total_amount)`.

---

### Screen 14: Grafik Tren Transaksi

#### ASCII Mockup
```
+------------------------------------------+
|  < Kembali    Tren Transaksi             |
|                                          |
|  [Harian ▼]   Jun 1 – Jun 17 2026       |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │  Top-Up Tunai (Rp)               │    |
|  │  800K ┤                    ╭─    │    |
|  │  600K ┤           ╭────────╯     │    |
|  │  400K ┤    ╭──────╯              │    |
|  │  200K ┤────╯                     │    |
|  │    0K └──┬──┬──┬──┬──┬──┬──┬─   │    |
|  │         01 03 05 07 09 11 13 17  │    |
|  └──────────────────────────────────┘    |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │  Koreksi Saldo (Rp)              │    |
|  │   50K ┤  ╮       ╮              │    |
|  │   30K ┤  ╰─╮   ╭─╯              │    |
|  │   10K ┤    ╰───╯                │    |
|  │    0K └──────────────────────   │    |
|  └──────────────────────────────────┘    |
|                                          |
|  Rata-rata Harian:                       |
|  Top-Up : Rp 497.000/hari               |
|  Koreksi: Rp 7.050/hari                 |
+------------------------------------------+
```

---

### Screen 15: Export & Kirim Laporan

#### ASCII Mockup
```
+------------------------------------------+
|  < Kembali       Export Laporan          |
|                                          |
|  Laporan: 01 Jun – 17 Jun 2026           |
|  Sekolah: SMP Terpadu                    |
|                                          |
|  Format Laporan:                         |
|  ┌──────────────────────────────────┐    |
|  │  [● Excel (.xlsx)] [○ PDF]       │    |
|  └──────────────────────────────────┘    |
|                                          |
|  Pilih Data Yang Disertakan:             |
|  ☑ Rekap Top-Up Harian                  |
|  ☑ Rekap Koreksi Saldo                  |
|  ☑ Pendapatan per Stan Kantin           |
|  ☑ Riwayat Audit Log Admin              |
|  ☐ Detail Per-Siswa (Data Sensitif)     |
|                                          |
|  Kirim Ke:                               |
|  [ kepsekolah@smp-terpadu.sch.id    ]    |
|  ─────────────────────────────────────── |
|                                          |
|  [ 📤 GENERATE & KIRIM LAPORAN ]         |
|                                          |
|  [ ⬇️ UNDUH KE PERANGKAT ]              |
+------------------------------------------+
```

#### Elemen & Aksi Interaksi
*   **Format Export**: Toggle Excel / PDF.
*   **Checkbox Data**: Pilih konten laporan yang ingin disertakan.
*   **Input Email**: Pre-filled dengan email kepala sekolah dari `system_settings`.
*   **Generate & Kirim**: Membuat file laporan secara lokal lalu mengirim via email (Supabase Edge Function).
*   **Unduh ke Perangkat**: Simpan ke storage lokal perangkat (share sheet iOS/Android).

---

### Screen 16: Audit Log (Riwayat Aktivitas Saya)

Riwayat seluruh aksi keuangan yang dilakukan oleh admin keuangan ini.

#### ASCII Mockup
```
+------------------------------------------+
|  < Kembali    Audit Log Saya      [📅]   |
|                                          |
|  Semua aktivitas saya tercatat di sini   |
|  untuk transparansi dan akuntabilitas.   |
|                                          |
|  Filter: [Semua Aksi ▼]                  |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │ ● KOREKSI_SALDO        13:40     │    |
|  │   Koreksi saldo Siti Aminah      │    |
|  │   -Rp 10.000 (Salah input...)    │    |
|  │   Detail Perubahan →             │    |
|  └──────────────────────────────────┘    |
|  ┌──────────────────────────────────┐    |
|  │ ↑ TOPUP_TUNAI          13:25     │    |
|  │   Top-Up Ahmad Subarjo           │    |
|  │   +Rp 50.000 · Tunai             │    |
|  │   Detail Perubahan →             │    |
|  └──────────────────────────────────┘    |
|  ┌──────────────────────────────────┐    |
|  │ 📶 REGISTRASI_KARTU    11:00     │    |
|  │   Kartu baru untuk Rian Hidayat  │    |
|  │   UID: A4:B9:C2:D8               │    |
|  │   Detail Perubahan →             │    |
|  └──────────────────────────────────┘    |
+------------------------------------------+
```

---

### Screen 16B: Detail Audit Log (JSON Diff)

#### ASCII Mockup
```
+──────────────────────────────────────────+
|                  ───                     |
|  Detail Log Perubahan                    |
|  KOREKSI SALDO                           |
|                                          |
|  Pelaksana  : Budi Hartono               |
|  Target     : Siti Aminah               |
|  Waktu      : 17 Jun 2026, 13:40:22      |
|  IP         : 192.168.1.15               |
|                                          |
|  Perubahan Data:                         |
|  ┌────────────┐  ┌────────────────────┐  |
|  │  SEBELUM   │  │  SESUDAH           │  |
|  │ {          │  │ {                  │  |
|  │  "balance" │  │  "balance":        │  |
|  │  : 15000   │  │   5000,            │  |
|  │ }          │  │  "reason":         │  |
|  │            │  │  "Salah input..."  │  |
|  │            │  │ }                  │  |
|  │            │  │ }                  │  |
|  └────────────┘  └────────────────────┘  |
|                                          |
|  [ TUTUP ]                               |
+──────────────────────────────────────────+
```

---

### Screen 17: Notifikasi

#### ASCII Mockup
```
+------------------------------------------+
|  < Kembali       Notifikasi              |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │ 🔔 Saldo Rendah Terdeteksi  Baru │    |
|  │   15 siswa memiliki saldo        │    |
|  │   di bawah Rp 5.000.             │    |
|  │   Periksa daftar →               │    |
|  └──────────────────────────────────┘    |
|  ┌──────────────────────────────────┐    |
|  │ ✔ Top-Up Berhasil         13:25  │    |
|  │   Ahmad Subarjo +Rp 50.000       │    |
|  └──────────────────────────────────┘    |
|  ┌──────────────────────────────────┐    |
|  │ ⚠️ Laporan Bulanan Tersedia 09:00 │   |
|  │   Laporan Mei 2026 siap          │    |
|  │   untuk diunduh.                 │    |
|  └──────────────────────────────────┘    |
+------------------------------------------+
```

---

### Screen 18: Profil & Pengaturan Akun

#### ASCII Mockup
```
+------------------------------------------+
|  Profil Saya                             |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │     (Avatar Inisial BH)          │    |
|  │     Budi Hartono                 │    |
|  │     Admin Keuangan               │    |
|  │     SMP Terpadu                  │    |
|  └──────────────────────────────────┘    |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │  Informasi Akun                  │    |
|  │  ─────────────────────────────   │    |
|  │  Email    budi.finance@f.com     │    |
|  │  Username budi_fin               │    |
|  │  Level    L1 (Operator)          │    |
|  │  Sekolah  SMP Terpadu            │    |
|  └──────────────────────────────────┘    |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │  Pengaturan Keamanan             │    |
|  │  ─────────────────────────────   │    |
|  │  🔒 Ubah Kata Sandi           >  │    |
|  │  📱 Sesi Aktif               >  │    |
|  └──────────────────────────────────┘    |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │  🚪 Keluar dari Akun          >  │    |
|  └──────────────────────────────────┘    |
+------------------------------------------+
| [🏠 Beranda] [👤 Siswa] [💸 Transaksi] [📊] |
+------------------------------------------+
```

---

## 4. Navigasi & Routing

| Screen | Route Flutter | Trigger |
|---|---|---|
| Login | `/login` | App start, logout |
| Dashboard Beranda | `/finance` | Post-login |
| Manajemen Siswa | `/finance/students` | Tab "Siswa" |
| Detail Siswa | `/finance/students/:id` | Tap kartu siswa |
| Registrasi Kartu | `/finance/students/:id/card` | Tap "Registrasi Kartu" |
| Top-Up Step 1 | `/finance/topup` | Tombol cepat / Tab |
| Top-Up Step 2 | `/finance/topup/confirm` | Cari siswa sukses |
| Koreksi Step 1 | `/finance/correction` | Tombol cepat |
| Koreksi Step 2 | `/finance/correction/form` | Cari siswa sukses |
| Konfirmasi Koreksi | `/finance/correction/confirm` | Lanjut dari form |
| Riwayat Transaksi | `/finance/history` | Tab "Transaksi" |
| Laporan | `/finance/report` | Tab "Laporan" / tombol |
| Export Laporan | `/finance/report/export` | Tombol export |
| Audit Log | `/finance/audit` | Menu settings |
| Profil | `/finance/profile` | Ikon profil |

---

## 5. Integrasi Database

### Tabel yang Diakses (Read)
| Tabel | Kolom Kunci | Keterangan |
|---|---|---|
| `profiles` | `id, full_name, email, role, is_active` | Data profil siswa & admin |
| `students` | `id, class, balance, card_uid` | Data saldo & kartu siswa |
| `transactions` | `student_id, type, amount, method, created_at` | Riwayat transaksi |
| `audit_logs` | `actor_id, action_type, old_value, new_value` | Log aktivitas admin |
| `finance_officers` | `id, assigned_school, authority_level` | Data penugasan admin |
| `canteen_operators` | `id, canteen_name, balance_earned` | Data stan kantin |

### Tabel yang Dimodifikasi (Write)
| Tabel | Operasi | Trigger |
|---|---|---|
| `students` | `UPDATE balance, card_uid` | Top-Up, Koreksi, Registrasi Kartu |
| `transactions` | `INSERT` | Setiap Top-Up & Koreksi |
| `audit_logs` | `INSERT` | Setiap aksi keuangan (otomatis) |
| `profiles` | `UPDATE is_active` | Blokir / Aktifkan akun siswa |

### RLS Policies (Admin Keuangan)
*   Hanya bisa mengakses data `students` dengan `school_id` yang sama dengan `finance_officers.assigned_school`.
*   Tidak bisa melihat/mengubah data sekolah lain.
*   Tidak bisa melihat audit log admin lain (hanya `WHERE actor_id = auth.uid()`).

---

## 6. State & Error Handling

| Kondisi | Tampilan |
|---|---|
| Loading data | `CupertinoActivityIndicator` di tengah layar |
| Data kosong | Ilustrasi + teks informatif |
| Koneksi offline | Snackbar merah: *"Tidak ada koneksi internet"* |
| Saldo tidak cukup untuk koreksi | Field merah + teks peringatan inline |
| Alasan koreksi kosong | Tombol disabled + hint teks merah |
| Kartu UID sudah digunakan siswa lain | Dialog error + nama pemilik kartu lama |
| Session expired | Redirect ke Login + Snackbar info |

---

## 7. Aksesibilitas & UX Rules

*   **Semua tombol aksi destruktif** (blokir, koreksi, hapus kartu) wajib melalui Cupertino Dialog konfirmasi.
*   **Nominal uang** selalu diformat `Rp X.XXX.XXX` menggunakan `NumberFormat`.
*   **Timestamp** selalu ditampilkan dalam zona waktu lokal perangkat.
*   **Pull-to-refresh** tersedia di semua daftar (siswa, transaksi, audit log).
*   **Infinite scroll / pagination** untuk daftar lebih dari 20 item.
