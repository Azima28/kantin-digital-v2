# 📱 Spesifikasi Desain UI/UX — Role: Admin Keuangan (Mobile App)
> **Versi 2.0** — Edisi Lengkap & Diperluas

Dokumen ini mendefinisikan **seluruh** antarmuka pengguna (UI/UX) untuk **Aplikasi Mobile Admin Keuangan / Tata Usaha Sekolah** secara lengkap dan detail, mencakup setiap screen, state, komponen, alur data, dan interaksi pengguna dari awal hingga akhir.

---

## 0. Filosofi Peran: Admin Keuangan sebagai "Wakil Presiden"

### Posisi dalam Hierarki Sistem

```
┌─────────────────────────────────────────────────────────┐
│                    SUPER ADMIN                          │
│   Akses penuh ke seluruh sistem, semua sekolah,         │
│   konfigurasi global, manajemen Admin Keuangan.         │
└─────────────────────────┬───────────────────────────────┘
                          │  mendelegasikan kendali
                          ▼
┌─────────────────────────────────────────────────────────┐
│               ADMIN KEUANGAN (Tata Usaha)               │
│   ★ "WAKIL PRESIDEN" di level sekolahnya ★              │
│                                                         │
│  ✅ BISA:                                               │
│     • Kelola SISWA (CRUD, saldo, kartu NFC, blokir)     │
│     • Kelola ORANG TUA (CRUD, verifikasi, link siswa)   │
│     • Kelola PETUGAS KANTIN (CRUD, aktivasi, stan)      │
│     • Top-Up saldo siswa (tunai)                        │
│     • Koreksi saldo (dengan alasan wajib)               │
│     • Lihat seluruh transaksi sekolahnya                │
│     • Generate laporan keuangan                         │
│     • Audit log semua aktivitas di sekolahnya           │
│                                                         │
│  ❌ TIDAK BISA:                                         │
│     • Kelola Admin Keuangan lain                        │
│     • Akses data sekolah lain                           │
│     • Ubah konfigurasi sistem global                    │
│     • Hapus permanen data transaksi                     │
│     • Akses panel Super Admin                           │
└─────────────────────────┬───────────────────────────────┘
                          │  mengawasi & mengelola
          ┌───────────────┴────────────────┐
          ▼                                ▼
┌─────────────────┐              ┌─────────────────────┐
│    SISWA        │              │  PETUGAS KANTIN      │
│  + ORANG TUA    │              │  (Kasir / Operator)  │
└─────────────────┘              └─────────────────────┘
```

### Mengapa Desain Ini Paling Baik?

Sistem yang bagus untuk peran "Wakil Presiden" memiliki prinsip **LAMP**:

| Prinsip | Deskripsi |
|---|---|
| **L**imited Scope | Admin Keuangan hanya melihat & mengelola data sekolahnya sendiri (Row-Level Security ketat) |
| **A**ccountability | Setiap aksi (CRUD, top-up, koreksi) tercatat otomatis di `audit_logs` yang hanya bisa dibaca, tidak bisa dihapus |
| **M**anagement Delegation | Super Admin mendelegasikan operasional harian ke Admin Keuangan sehingga Super Admin fokus ke konfigurasi sistem |
| **P**ermission Boundary | Ada batas jelas antara apa yang boleh dan tidak boleh dilakukan. Tidak ada "admin yang bisa segalanya" selain Super Admin |

---

## 1. Panduan Visual Umum (Branding & Design System)

*   **Tipografi**: `Be Vietnam Pro` (Google Fonts) — bersih, profesional, mudah dibaca.
*   **Tema Warna**:
    *   *Primary Teal* (`#003434`): Warna utama brand untuk header, tombol aksi, highlight data.
    *   *Accent Orange* (`#904D00`): Aksen untuk indikator top-up, peringatan, atau nominal positif.
    *   *Success Green* (`#006A35`): Indikator transaksi berhasil, saldo aman, status aktif.
    *   *Danger Red* (`#BA1A1A`): Indikator koreksi, saldo kurang, akun diblokir, refund.
    *   *Warning Amber* (`#7A5000`): Peringatan pending, verifikasi menunggu, konfirmasi.
    *   *Background* (`#FBF9F8`): Latar belakang layar utama, cream terang.
    *   *Card White* (`#FFFFFF`): Latar kartu konten, bersih dan mudah dibaca.
    *   *Border* (`#E4E2E1`): Garis pemisah tipis antar elemen.
    *   *Text Gray* (`#6F7978`): Teks label sekunder, placeholder, timestamp.
*   **Karakteristik Layout Mobile**:
    *   *Bento Card Radius*: `24px` untuk semua kartu konten utama.
    *   *Input Field Radius*: `12px` untuk semua input form.
    *   *Safe Area*: Semua konten menghormati safe area iOS/Android (notch & home indicator).
    *   *Padding Horizontal*: `20px` standar untuk semua konten layar.
    *   *Bottom Navigation Bar*: 5 tab — Beranda, Siswa, Pengguna, Transaksi, Laporan.
    *   *App Bar*: Teks judul besar (Bold 20px) di kiri, ikon aksi di kanan.
*   **Komponen Reusable**:
    *   *Bento Card*: Container putih, radius 24px, shadow tipis (0px 4px 20px rgba(0,0,0,4%)).
    *   *Status Badge*: Pill oval kecil berwarna sesuai status (hijau = aktif, merah = blokir, oranye = pending).
    *   *Snackbar Floating*: Notifikasi bawah layar dengan radius 12px, icon, dan teks.
    *   *iOS Grab Handle*: Strip abu-abu `36x5px` di puncak setiap bottom sheet.
    *   *Cupertino Dialog*: Dialog konfirmasi bergaya iOS untuk semua aksi destruktif.
    *   *Section Header*: Label kategori huruf kapital kecil abu-abu, spasi 1.2px.
    *   *Avatar Inisial*: Circle berisi 2 huruf nama, warna unik deterministik dari hash nama.

---

## 2. Struktur Alur Layar (Sitemap Mobile)

```
[Login Screen]
     │
     └──► [Dashboard Beranda]
               │
               ├──► [Manajemen Siswa]
               │         ├──► [Tambah Siswa Baru]
               │         ├──► [Detail Siswa]
               │         │         ├──► [Edit Profil Siswa]
               │         │         ├──► [Registrasi / Ganti Kartu NFC]
               │         │         ├──► [Riwayat Transaksi Siswa]
               │         │         ├──► [Top-Up Langsung dari Profil]
               │         │         ├──► [Koreksi Langsung dari Profil]
               │         │         └──► [Blokir / Aktifkan Akun]
               │         └──► [Cari Siswa (Global)]
               │
               ├──► [Manajemen Pengguna]
               │         ├──► [Sub-Tab: Orang Tua]
               │         │         ├──► [Tambah Orang Tua]
               │         │         ├──► [Detail Orang Tua]
               │         │         │         ├──► [Edit Profil Ortu]
               │         │         │         ├──► [Link ke Siswa]
               │         │         │         └──► [Blokir / Aktifkan]
               │         │         └──► [Verifikasi Akun Ortu Pending]
               │         │
               │         └──► [Sub-Tab: Petugas Kantin]
               │                   ├──► [Tambah Petugas Baru]
               │                   ├──► [Detail Petugas]
               │                   │         ├──► [Edit Profil Petugas]
               │                   │         ├──► [Assign ke Stan Kantin]
               │                   │         ├──► [Reset Password Petugas]
               │                   │         └──► [Blokir / Aktifkan]
               │                   └──► [Monitor Stan Kantin (Omzet)]
               │
               ├──► [Modul Transaksi]
               │         ├──► [Top-Up Tunai]
               │         │         ├──► [Cari Siswa → Konfirmasi Top-Up]
               │         │         └──► [Struk Sukses]
               │         ├──► [Koreksi Saldo]
               │         │         ├──► [Cari Siswa → Form Koreksi]
               │         │         ├──► [Konfirmasi Koreksi (Dialog Keamanan)]
               │         │         └──► [Struk Koreksi Sukses]
               │         ├──► [Persetujuan Top-Up VA (Otorisasi)]
               │         └──► [Riwayat Transaksi Sekolah]
               │                   └──► [Detail Transaksi]
               │
               ├──► [Laporan Keuangan]
               │         ├──► [Ringkasan Periode]
               │         ├──► [Detail per Stan Kantin]
               │         ├──► [Grafik Tren Transaksi]
               │         └──► [Export & Kirim Laporan]
               │
               ├──► [Audit Log (Semua Aktivitas Sekolah)]
               │         └──► [Detail Log Perubahan]
               │
               ├──► [Notifikasi]
               │
               └──► [Profil & Pengaturan Akun]
                         ├──► [Edit Profil]
                         ├──► [Ubah Kata Sandi]
                         ├──► [Sesi Aktif]
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
|  ┌──────────────────────────────────┐    |
|  │     🏫  Kantin Digital           │    |
|  │     Sistem Manajemen Sekolah     │    |
|  └──────────────────────────────────┘    |
|                                          |
|  Selamat Datang,                         |
|  Admin Keuangan 👋                        |
|  Masuk untuk mengelola sistem kantin     |
|  sekolah Anda.                           |
|                                          |
|  ─────── Masuk Sebagai ──────────        |
|                                          |
|  Username / Email                        |
|  [ budi_fin                         ]    |
|  ─────────────────────────────────────── |
|  Kata Sandi                              |
|  [ ••••••••••••••              ] [👁️]    |
|  ─────────────────────────────────────── |
|                                          |
|  [ MASUK ]  ← Tombol Teal penuh          |
|                                          |
|  Lupa kata sandi? Hubungi Super Admin    |
|                                          |
+------------------------------------------+
```

#### Elemen & Aksi Interaksi
*   **Input Email/Username**: Mendukung login menggunakan `email` atau `username`.
    *   Keyboard: `emailAddress` untuk deteksi otomatis.
    *   Validasi inline: Format email jika ada `@`, atau username minimal 3 karakter.
*   **Input Kata Sandi**: Field obscured dengan toggle ikon mata.
*   **Tombol "MASUK"**:
    *   *Aksi*: Query tabel `profiles` untuk memvalidasi kredensial dan role `petugas_keuangan`.
    *   Jika role bukan `petugas_keuangan`: Snackbar merah *"Akses ditolak. Gunakan akun Admin Keuangan."*
    *   Jika berhasil: Navigasi ke **Screen 2: Dashboard Beranda**.
*   **State Loading**: Tombol berubah menjadi `CupertinoActivityIndicator` warna putih.
*   **Lupa Kata Sandi**: Teks kecil di bawah. Tap → Snackbar info *"Hubungi Super Admin untuk reset password."*

---

### Screen 2: Dashboard Beranda

Layar utama setelah login, menampilkan ringkasan keuangan sekolah hari ini beserta notifikasi penting.

#### ASCII Mockup
```
+------------------------------------------+
|  Selamat Pagi,                           |
|  Budi Hartono 👋                          |
|  Admin Keuangan · SMP Terpadu            |
|                       [🔔3] [👤]          |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │  💰 Total Saldo Beredar Sekolah  │    |
|  │  Rp 14.520.000                   │    |
|  │  ▲ +Rp 1.250.000 dari kemarin    │    |
|  │  120 siswa aktif                 │    |
|  └──────────────────────────────────┘    |
|                                          |
|  ┌────────────────┐  ┌────────────────┐  |
|  │ 💵 Top-Up      │  │ ⚖️ Koreksi     │  |
|  │ Tunai Hari Ini │  │ Hari Ini       │  |
|  │ Rp 1.250.000   │  │ 3 Transaksi    │  |
|  │ 18 Transaksi   │  │ -Rp 35.000 net │  |
|  └────────────────┘  └────────────────┘  |
|                                          |
|  ┌────────────────┐  ┌────────────────┐  |
|  │ 👥 Pengguna    │  │ 📊 Omzet Stan  │  |
|  │ Pending        │  │ Hari Ini       │  |
|  │ 3 ortu baru    │  │ Rp 4.780.000   │  |
|  │ verifikasi ⚠️  │  │ 5 stan aktif   │  |
|  └────────────────┘  └────────────────┘  |
|                                          |
|  Aksi Cepat                              |
|  ┌────────┐ ┌────────┐ ┌─────────────┐  |
|  │ [💵]   │ │ [⚖️]   │ │ [👤+]       │  |
|  │ Top-Up │ │Koreksi │ │ Tambah Siswa│  |
|  └────────┘ └────────┘ └─────────────┘  |
|  ┌────────┐ ┌────────┐ ┌─────────────┐  |
|  │ [📋]   │ │ [🔔]   │ │ [📤]        │  |
|  │Laporan │ │Notifik.│ │ Export      │  |
|  └────────┘ └────────┘ └─────────────┘  |
|                                          |
|  Aktivitas Terbaru                       |
|  ┌──────────────────────────────────┐    |
|  │ ● Top-Up Rp 50.000 · Ahmad  12:10│    |
|  │ ● Koreksi -Rp 10.000 · Siti 10:45│   |
|  │ ● Ortu Baru Daftar · Hasan  09:30│   |
|  │ ● Petugas Login · Warung Sari 08:00│  |
|  │            Lihat Semua →         │    |
|  └──────────────────────────────────┘    |
|                                          |
|  ⚠️ Peringatan Saldo Rendah (15 siswa)  |
|  [ Lihat Daftar Siswa Saldo Rendah ]    |
|                                          |
+------------------------------------------+
| [🏠 Home] [👤 Siswa] [👥 Pengguna] [💸] [📊]|
+------------------------------------------+
```

#### Elemen & Aksi Interaksi
*   **Header Salam**: Waktu sapaan dinamis (Pagi/Siang/Sore) + nama dari `profiles` + sekolah.
*   **Ikon Notifikasi [🔔3]**: Badge angka jumlah notifikasi belum dibaca. Tap → **Screen Notifikasi**.
*   **Kartu Total Saldo**: `SUM(balance)` dari `students` dimana `school_id` sesuai.
*   **Kartu Pengguna Pending**: Jumlah akun orang tua yang belum diverifikasi. Tap → langsung ke tab verifikasi.
*   **Kartu Omzet Stan**: `SUM(amount)` dari `transactions` hari ini, filter `school_id`.
*   **6 Tombol Aksi Cepat**: Grid 3x2 untuk aksi yang paling sering digunakan.
*   **Feed Aktivitas**: 4 entri terbaru dari `audit_logs` sekolah ini. Tap "Lihat Semua" → **Screen Audit Log**.
*   **Banner Peringatan**: Muncul jika ada siswa dengan saldo < Rp 5.000. Tap → Manajemen Siswa dengan filter saldo rendah.

---

### Screen 3: Manajemen Siswa (Daftar)

Daftar master data semua siswa di sekolah penugasan admin keuangan.

#### ASCII Mockup
```
+------------------------------------------+
|  ← Kembali   Manajemen Siswa    [🔍][+]  |
|                                          |
|  [ 🔍 Cari nama, NIS, atau kelas...  ]   |
|                                          |
|  Filter: [Semua Kelas ▼] [Status ▼] [Saldo ▼]|
|                                          |
|  Menampilkan 120 siswa · 3 filter aktif  |
|  ─────────────────────────────────────── |
|  ┌──────────────────────────────────┐    |
|  │  👤  Ahmad Subarjo               │    |
|  │      NIS: 20260012 · Kelas 8-B   │    |
|  │      Saldo: Rp 75.000  ● AKTIF   │    |
|  │      Kartu: ● TERHUBUNG    [>]   │    |
|  └──────────────────────────────────┘    |
|  ┌──────────────────────────────────┐    |
|  │  👤  Rian Hidayat                │    |
|  │      NIS: 20260013 · Kelas 9-A   │    |
|  │      Saldo: Rp 3.500 ⚠️ RENDAH   │    |
|  │      Kartu: ○ BELUM TERHUBUNG [>]│    |
|  └──────────────────────────────────┘    |
|  ┌──────────────────────────────────┐    |
|  │  👤  Siti Aminah                 │    |
|  │      NIS: 20260099 · Kelas 7-A   │    |
|  │      Saldo: Rp 15.000  ● AKTIF   │    |
|  │      ● TERHUBUNG   🔒 DIBLOKIR   │    |
|  └──────────────────────────────────┘    |
|                                          |
|  ← Sebelumnya  Hlm 1 dari 6  Berikutnya →|
+------------------------------------------+
| [🏠 Home] [👤 Siswa] [👥 Pengguna] [💸] [📊]|
+------------------------------------------+
```

#### Elemen & Aksi Interaksi
*   **Search Bar**: Real-time search `full_name`, `nisn`, atau `class`.
*   **Ikon [+]**: Tambah siswa baru → **Screen 3A: Form Tambah Siswa**.
*   **Filter Kelas**: Dropdown berisi daftar kelas unik dari database sekolah ini.
*   **Filter Status**: `Semua / Aktif / Diblokir / Belum Punya Kartu`.
*   **Filter Saldo**: `Semua / Saldo Rendah (<Rp 5.000) / Saldo Nol / Normal`.
*   **Kartu Siswa**:
    *   Saldo merah jika < Rp 5.000, oranye jika < Rp 10.000.
    *   Badge 🔒 merah jika akun diblokir.
    *   Tap kartu → **Screen 4: Detail Siswa**.
*   **Pagination**: 20 item per halaman dengan navigasi sebelumnya/berikutnya.

---

### Screen 3A: Form Tambah Siswa Baru

Form lengkap untuk mendaftarkan siswa baru ke sistem.

#### ASCII Mockup
```
+------------------------------------------+
|  ← Batal   Tambah Siswa Baru   [Simpan]  |
|                                          |
|  INFORMASI PRIBADI                       |
|  ─────────────────────────────────────── |
|  Nama Lengkap *                          |
|  [ Ahmad Subarjo                    ]    |
|                                          |
|  NIS (Nomor Induk Siswa) *               |
|  [ 20260012                         ]    |
|                                          |
|  NISN (Opsional)                         |
|  [ 3026012345678                    ]    |
|                                          |
|  Kelas *                                 |
|  [ 8-B                         ▼    ]    |
|                                          |
|  Tanggal Lahir                           |
|  [ 14 Agustus 2012              ▼    ]   |
|                                          |
|  AKUN SISTEM                             |
|  ─────────────────────────────────────── |
|  Email (Opsional)                        |
|  [ ahmad.20260012@siswa.sch.id      ]    |
|                                          |
|  Password Awal *                         |
|  [ siswa123 (auto-generate)         ]    |
|  [🔄 Generate Ulang]                     |
|                                          |
|  SALDO AWAL                              |
|  ─────────────────────────────────────── |
|  Saldo Awal (Opsional)                   |
|  Rp [ 0                           ]     |
|                                          |
|  ☑ Kirim kredensial ke email siswa       |
|  ☐ Daftarkan kartu NFC sekarang         |
|                                          |
|  [ SIMPAN & DAFTARKAN SISWA ]           |
+------------------------------------------+
```

#### Elemen & Aksi Interaksi
*   **NIS Validasi**: Cek duplikasi `NIS` di tabel `students` sekolah ini secara real-time (debounce 500ms).
*   **Auto-generate Password**: Tombol 🔄 membuat password acak 8 karakter (angka+huruf).
*   **Email Auto-fill**: Saran format `[nis]@siswa.[domain_sekolah]`.
*   **Saldo Awal**: Jika diisi, langsung `INSERT` ke `transactions` dengan `type = 'INITIAL_BALANCE'`.
*   **Checkbox Kartu NFC**: Jika dicentang, setelah simpan langsung lanjut ke **Screen 5: Registrasi Kartu**.
*   **Tombol Simpan**:
    *   `INSERT INTO profiles (full_name, role='student', school_id)`.
    *   `INSERT INTO students (profile_id, nis, nisn, class, balance)`.
    *   `INSERT INTO audit_logs (action = 'TAMBAH_SISWA')`.

---

### Screen 4: Detail Siswa

Halaman detail lengkap profil siswa termasuk saldo, informasi kartu, orang tua, dan riwayat transaksi.

#### ASCII Mockup
```
+------------------------------------------+
|  ← Kembali    Profil Siswa    [✏️ Edit]  |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │    👤 (Avatar Inisial A·S)       │    |
|  │    Ahmad Subarjo                 │    |
|  │    [ AKTIF ]     Kelas 8-B       │    |
|  │    📧 ahmad@siswa.sch.id         │    |
|  │    🪪 NIS: 20260012              │    |
|  │    📅 Lahir: 14 Ags 2012         │    |
|  └──────────────────────────────────┘    |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │  💳 Saldo & Kartu NFC            │    |
|  │  ─────────────────────────────   │    |
|  │  Saldo Aktif       Rp 75.000     │    |
|  │  Status Kartu      ● TERHUBUNG   │    |
|  │  UID Kartu         04:F8:A1:22   │    |
|  │  Terakhir Tap      17 Jun 12:05  │    |
|  └──────────────────────────────────┘    |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │  👨‍👩‍👧 Orang Tua Terhubung          │    |
|  │  ─────────────────────────────   │    |
|  │  Hasan Basri (Ayah) ● Terverif.  │    |
|  │  📞 082112345678      [Lihat >]  │    |
|  │  [+ Hubungkan Ortu Lain]         │    |
|  └──────────────────────────────────┘    |
|                                          |
|  ⚡ Aksi Admin                           |
|  ┌──────────────────────────────────┐    |
|  │  💵 Top-Up Saldo              >  │    |
|  │  ⚖️  Koreksi Saldo             >  │    |
|  │  📶 Registrasi / Ganti Kartu  >  │    |
|  │  👨‍👩‍👧 Kelola Orang Tua          >  │    |
|  └──────────────────────────────────┘    |
|                                          |
|  Riwayat Transaksi (30 hari terakhir)   |
|  ┌──────────────────────────────────┐    |
|  │ + Rp 50.000  Top-Up Tunai  12:10 │    |
|  │ - Rp 22.000  Belanja      11:45  │    |
|  │ + Rp 100.000 Top-Up VA     09:00 │    |
|  │           Lihat Semua →          │    |
|  └──────────────────────────────────┘    |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │  🚫 Blokir Akun Siswa         >  │    |
|  └──────────────────────────────────┘    |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │  🗑️ Hapus Siswa (Nonaktifkan)  >  │    |
|  └──────────────────────────────────┘    |
+------------------------------------------+
```

#### Elemen & Aksi Interaksi
*   **[✏️ Edit]**: App Bar trailing button → **Screen 4A: Edit Profil Siswa**.
*   **Kartu Saldo & Kartu**: UID kartu NFC, kapan terakhir digunakan.
*   **Orang Tua Terhubung**: Daftar ortu yang sudah dilink ke siswa ini. Tap "Lihat >" → detail ortu.
*   **[+ Hubungkan Ortu Lain]**: Bottom sheet pencarian ortu yang terdaftar.
*   **Aksi Admin**:
    *   *Top-Up Saldo* → Buka **Screen 8** dengan siswa pre-filled.
    *   *Koreksi Saldo* → Buka **Screen 10** dengan siswa pre-filled.
    *   *Registrasi Kartu* → **Screen 5**.
*   **Blokir Akun**: Cupertino Dialog konfirmasi. Update `is_active = false` + catat `audit_logs`.
*   **Hapus Siswa**: Hanya menonaktifkan (soft-delete), bukan hapus permanen. Muncul dialog "HAPUS" merah + alasan wajib.

---

### Screen 4A: Edit Profil Siswa

```
+------------------------------------------+
|  ← Batal   Edit Profil Siswa   [Simpan]  |
|                                          |
|  Nama Lengkap                            |
|  [ Ahmad Subarjo                    ]    |
|                                          |
|  Kelas                                   |
|  [ 8-B                         ▼    ]   |
|                                          |
|  Email                                   |
|  [ ahmad@siswa.sch.id               ]    |
|                                          |
|  Nomor HP (Opsional)                     |
|  [ 0812 XXXX XXXX                   ]    |
|                                          |
|  Tanggal Lahir                           |
|  [ 14 Agustus 2012              ▼    ]   |
|                                          |
|  Reset Password Siswa                    |
|  ┌──────────────────────────────────┐    |
|  │  Password Baru (Kosongkan jika   │    |
|  │  tidak ingin mengubah)           │    |
|  │  [ ••••••••••••                ] │    |
|  └──────────────────────────────────┘    |
|                                          |
|  [ SIMPAN PERUBAHAN ]                   |
+------------------------------------------+
```

---

### Screen 5: Registrasi / Ganti Kartu NFC

Layar untuk menautkan atau mengganti kartu RFID/NFC siswa.

#### ASCII Mockup
```
+------------------------------------------+
|  ← Kembali    Registrasi Kartu NFC       |
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
|  │    ┌─────────────────────────┐   │    |
|  │    │  (( 🛜 Animasi Pulse ))  │   │    |
|  │    └─────────────────────────┘   │    |
|  │                                  │    |
|  │    Atau masukkan UID manual:     │    |
|  └──────────────────────────────────┘    |
|                                          |
|  UID Kartu (Input Manual)                |
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
*   **NFC Scan**: Plugin `flutter_nfc_kit`. Saat terbaca, UID otomatis isi field manual + animasi pulse berhenti.
*   **Input Manual**: Fallback jika NFC tidak tersedia. Format XX:XX:XX:XX auto-format.
*   **Info UID Lama**: Referensi kartu aktif yang akan digantikan.
*   **Tombol "Hubungkan Kartu"**:
    *   Validasi: Cek UID tidak digunakan siswa lain (`SELECT * FROM students WHERE card_uid = ?`).
    *   Jika duplikat: Dialog error *"UID ini sudah terhubung ke [Nama Siswa Lain]. Pastikan kartu benar."*
    *   Jika oke: `UPDATE students SET card_uid = '...' WHERE id = '...'`.
    *   Catat `audit_logs` dengan `action_type = 'REGISTRASI_KARTU'`.
    *   Snackbar hijau: *"Kartu berhasil ditautkan!"* + navigasi ke **Screen 5B**.
*   **Hapus Tautan**: Cupertino Dialog konfirmasi. Jika ya, `UPDATE students SET card_uid = NULL`.

---

### Screen 5B: State Berhasil Registrasi Kartu

```
+------------------------------------------+
|  ← Kembali    Registrasi Kartu NFC       |
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
|  [ DAFTARKAN SISWA BERIKUTNYA ]          |
+------------------------------------------+
```

---

### Screen 6: Manajemen Pengguna (Tab View)

Halaman utama manajemen pengguna non-siswa dengan dua sub-tab.

#### ASCII Mockup — Tab: Orang Tua
```
+------------------------------------------+
|  ← Kembali  Manajemen Pengguna    [+]   |
|                                          |
|  [ ORANG TUA ]       [ PETUGAS KANTIN ] |
|  ══════════════       ─────────────────  |
|                                          |
|  [ 🔍 Cari nama atau email...       ]   |
|                                          |
|  ⚠️ PERLU VERIFIKASI (3)                 |
|  ┌──────────────────────────────────┐    |
|  │  👤  Hasan Basri        PENDING  │    |
|  │      082112345678                │    |
|  │      Terdaftar 17 Jun 09:30      │    |
|  │      [ TOLAK ]    [ VERIFIKASI ] │    |
|  └──────────────────────────────────┘    |
|                                          |
|  SEMUA ORANG TUA (45)                    |
|  ┌──────────────────────────────────┐    |
|  │  👤  Dewi Sartika     ● AKTIF    │    |
|  │      dewi@gmail.com              │    |
|  │      Terhubung: Siti Aminah (7A) │    |
|  └──────────────────────────────────┘    |
|  ┌──────────────────────────────────┐    |
|  │  👤  Budi Santoso     ● AKTIF    │    |
|  │      budi.s@yahoo.com            │    |
|  │      Terhubung: 2 anak           │    |
|  └──────────────────────────────────┘    |
+------------------------------------------+
| [🏠 Home] [👤 Siswa] [👥 Pengguna] [💸] [📊]|
+------------------------------------------+
```

#### ASCII Mockup — Tab: Petugas Kantin
```
+------------------------------------------+
|  ← Kembali  Manajemen Pengguna    [+]   |
|                                          |
|  [ ORANG TUA ]       [ PETUGAS KANTIN ] |
|  ─────────────       ══════════════════  |
|                                          |
|  [ 🔍 Cari nama atau username...    ]   |
|                                          |
|  PETUGAS AKTIF (5)                       |
|  ┌──────────────────────────────────┐    |
|  │  👨‍🍳  Warung Bude Sari    ● LOGIN │    |
|  │      Kasir: Sari Dewi            │    |
|  │      Omzet Hari Ini: Rp 780.000  │    |
|  │      123 Transaksi               │    |
|  └──────────────────────────────────┘    |
|  ┌──────────────────────────────────┐    |
|  │  👨‍🍳  Koperasi Minuman  ● LOGIN  │    |
|  │      Kasir: Rudi Hartono         │    |
|  │      Omzet Hari Ini: Rp 450.000  │    |
|  │      89 Transaksi                │    |
|  └──────────────────────────────────┘    |
|  ┌──────────────────────────────────┐    |
|  │  👨‍🍳  Stan Bakso Pak Harto ○ OFF │    |
|  │      Kasir: Harto Subroto        │    |
|  │      Omzet Hari Ini: Rp 0        │    |
|  │      Belum login hari ini        │    |
|  └──────────────────────────────────┘    |
+------------------------------------------+
```

#### Elemen & Aksi Interaksi (Orang Tua)
*   **Seksi Perlu Verifikasi**: Akun ortu yang mendaftar mandiri via aplikasi orang tua, menunggu approval.
    *   **Tombol VERIFIKASI**: Cupertino Dialog konfirmasi → update `profiles.is_verified = true` + trigger notifikasi push ke ortu.
    *   **Tombol TOLAK**: Dialog dengan alasan opsional → `profiles.is_active = false` + notifikasi ke ortu.
*   **Kartu Ortu**: Tap → **Screen 7A: Detail Orang Tua**.
*   **[+]**: Tambah ortu baru → **Screen 6A: Form Tambah Orang Tua**.

#### Elemen & Aksi Interaksi (Petugas Kantin)
*   **Status LOGIN/OFF**: Real-time dari last_login petugas. Hijau = aktif hari ini, abu-abu = tidak login.
*   **Omzet Hari Ini**: `SUM(amount)` dari `transactions` hari ini, per kantin.
*   **Tap Kartu** → **Screen 7B: Detail Petugas Kantin**.
*   **[+]**: Tambah petugas baru → **Screen 6B: Form Tambah Petugas Kantin**.

---

### Screen 6A: Form Tambah Orang Tua

```
+------------------------------------------+
|  ← Batal    Tambah Orang Tua   [Simpan]  |
|                                          |
|  INFORMASI PRIBADI                       |
|  ─────────────────────────────────────── |
|  Nama Lengkap *                          |
|  [ Hasan Basri                      ]    |
|                                          |
|  Hubungan dengan Siswa *                 |
|  [ Ayah                         ▼   ]    |
|                                          |
|  Nomor HP / WhatsApp *                   |
|  [ 082112345678                     ]    |
|                                          |
|  Email *                                 |
|  [ hasan.basri@gmail.com            ]    |
|                                          |
|  NIK (Opsional)                          |
|  [ 3172XXXXXXXXXXXXXX               ]    |
|                                          |
|  AKUN SISTEM                             |
|  ─────────────────────────────────────── |
|  Password Awal *                         |
|  [ ortu123 (auto-generate)          ]    |
|  [🔄 Generate Ulang]                     |
|                                          |
|  HUBUNGKAN KE SISWA                      |
|  ─────────────────────────────────────── |
|  Cari Anak:                              |
|  [ 20260012 (Ahmad Subarjo, 8-B) ×  ]    |
|  [+ Tambah Anak Lain]                    |
|                                          |
|  ☑ Kirim kredensial via WhatsApp/email  |
|                                          |
|  [ SIMPAN & DAFTARKAN ORTU ]            |
+------------------------------------------+
```

---

### Screen 6B: Form Tambah Petugas Kantin

```
+------------------------------------------+
|  ← Batal  Tambah Petugas Kantin [Simpan] |
|                                          |
|  INFORMASI PRIBADI                       |
|  ─────────────────────────────────────── |
|  Nama Lengkap *                          |
|  [ Sari Dewi                        ]    |
|                                          |
|  Nomor HP *                              |
|  [ 081298765432                     ]    |
|                                          |
|  Email (Opsional)                        |
|  [ sari@kantindigital.id            ]    |
|                                          |
|  AKUN SISTEM                             |
|  ─────────────────────────────────────── |
|  Username *                              |
|  [ petugas_sari                     ]    |
|                                          |
|  Password Awal *                         |
|  [ kantin123                        ]    |
|  [🔄 Generate Ulang]                     |
|                                          |
|  PENUGASAN STAN KANTIN                   |
|  ─────────────────────────────────────── |
|  Assign ke Stan Kantin *                 |
|  ┌──────────────────────────────────┐    |
|  │  ○ (Tanpa Stan — Admin Saja)     │    |
|  │  ● Warung Bude Sari              │    |
|  │  ○ Koperasi Minuman              │    |
|  │  ○ Stan Bakso Pak Harto          │    |
|  │  ○ [+ Buat Stan Baru...]         │    |
|  └──────────────────────────────────┘    |
|                                          |
|  [ SIMPAN & AKTIFKAN PETUGAS ]          |
+------------------------------------------+
```

---

### Screen 7A: Detail Orang Tua

```
+------------------------------------------+
|  ← Kembali   Profil Orang Tua  [✏️ Edit] |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │    👤 (Avatar Inisial H·B)       │    |
|  │    Hasan Basri                   │    |
|  │    Ayah dari Ahmad Subarjo       │    |
|  │    [ TERVERIFIKASI ]             │    |
|  │    📧 hasan@gmail.com            │    |
|  │    📞 082112345678               │    |
|  └──────────────────────────────────┘    |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │  👨‍👩‍👧 Anak Terdaftar               │    |
|  │  ─────────────────────────────   │    |
|  │  Ahmad Subarjo · 8-B             │    |
|  │  Saldo: Rp 75.000 ● Aktif   [>] │    |
|  │  [+ Hubungkan Anak Lain]         │    |
|  └──────────────────────────────────┘    |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │  📱 Aktivitas Aplikasi           │    |
|  │  Terakhir Login: 17 Jun 08:30    │    |
|  │  Total Top-Up VA: Rp 500.000     │    |
|  └──────────────────────────────────┘    |
|                                          |
|  ⚡ Aksi Admin                           |
|  ┌──────────────────────────────────┐    |
|  │  🔒 Reset Password Ortu       >  │    |
|  │  🚫 Blokir Akun Ortu          >  │    |
|  └──────────────────────────────────┘    |
+------------------------------------------+
```

---

### Screen 7B: Detail Petugas Kantin

```
+------------------------------------------+
|  ← Kembali  Detail Petugas Kantin [✏️]  |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │    👨‍🍳 (Avatar Inisial S·D)      │    |
|  │    Sari Dewi                     │    |
|  │    Warung Bude Sari              │    |
|  │    [ AKTIF ] ● Login 08:00       │    |
|  │    📞 081298765432               │    |
|  └──────────────────────────────────┘    |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │  📊 Statistik Hari Ini           │    |
|  │  ─────────────────────────────   │    |
|  │  Total Transaksi    123          │    |
|  │  Total Omzet        Rp 780.000   │    |
|  │  Rata-rata Nominal  Rp 6.341     │    |
|  │  [Lihat Grafik Mingguan]         │    |
|  └──────────────────────────────────┘    |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │  🏪 Stan Kantin                  │    |
|  │  Warung Bude Sari                │    |
|  │  [Ganti Stan Penugasan]          │    |
|  └──────────────────────────────────┘    |
|                                          |
|  ⚡ Aksi Admin                           |
|  ┌──────────────────────────────────┐    |
|  │  🔑 Reset Password Petugas    >  │    |
|  │  🚫 Blokir / Nonaktifkan      >  │    |
|  └──────────────────────────────────┘    |
+------------------------------------------+
```

---

### Screen 8: Form Top-Up Tunai (Step 1 — Cari Siswa)

Langkah pertama top-up: mencari siswa penerima saldo.

#### ASCII Mockup
```
+------------------------------------------+
|  ← Kembali         Top-Up Tunai          |
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
|                                          |
|  [ 📷 SCAN KARTU / QR SISWA ]           |
+------------------------------------------+
```

---

### Screen 9: Form Top-Up Tunai (Step 2 — Input Nominal)

Langkah kedua: konfirmasi profil siswa dan input nominal top-up.

#### ASCII Mockup
```
+------------------------------------------+
|  ← Kembali         Top-Up Tunai          |
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
|  Catatan Admin (Opsional)                |
|  [ Titipan ibu siswa...             ]    |
|                                          |
|  [ LANJUT → KONFIRMASI ]                 |
+------------------------------------------+
```

---

### Screen 10: Konfirmasi Top-Up & Struk Digital

Langkah ketiga: konfirmasi akhir sebelum transaksi diproses.

#### ASCII Mockup — Step 3: Konfirmasi
```
+------------------------------------------+
|  ← Kembali         Top-Up Tunai          |
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
|  │  Catatan       Titipan ibu       │    |
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
|  [ ↑ TOP-UP SISWA LAIN ]                |
+------------------------------------------+
```

#### Alur Backend
1. `BEGIN TRANSACTION`
2. `INSERT INTO transactions (student_id, type='TOP_UP_TUNAI', amount, admin_id, notes)`.
3. `UPDATE students SET balance = balance + amount WHERE id = student_id`.
4. `INSERT INTO audit_logs (actor_id, action_type='TOPUP_TUNAI', old_value, new_value, description)`.
5. `COMMIT` — semua atomik, jika gagal satu, semua dibatalkan.
6. Tampilkan struk digital.

---

### Screen 11: Form Koreksi Saldo (Step 1 — Cari Siswa)

Modul penting untuk mengoreksi saldo akibat kesalahan kasir atau input.

#### ASCII Mockup
```
+------------------------------------------+
|  ← Kembali       Koreksi Saldo           |
|                                          |
|  ⚠️  Modul Koreksi Terbatas              |
|  Setiap koreksi wajib beralasan dan      |
|  akan dicatat permanen di audit log.     |
|  Dapat diperiksa Super Admin kapan saja. |
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

### Screen 12: Form Koreksi Saldo (Step 2 — Detail Koreksi)

#### ASCII Mockup
```
+------------------------------------------+
|  ← Kembali       Koreksi Saldo           |
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
|  ⚠️  Saldo akan turun ke bawah Rp 10.000 |
|                                          |
|  Alasan Koreksi (Wajib)                  |
|  ┌──────────────────────────────────┐    |
|  │ Salah input nominal belanja      │    |
|  │ jajan di stan Bude Sari tgl      │    |
|  │ 17 Juni 2026...                  │    |
|  └──────────────────────────────────┘    |
|  Minimal 20 karakter. (48 / 20 ✔)       |
|                                          |
|  Kategori Koreksi                        |
|  [Kesalahan Kasir ▼]                     |
|  (Kesalahan Kasir / Saldo Ganda /        |
|   Refund / Lainnya)                      |
|                                          |
|  [ LANJUT → KONFIRMASI ]                 |
|   (Disabled jika alasan kosong)          |
+------------------------------------------+
```

#### Elemen & Aksi Interaksi
*   **Radio Jenis Koreksi**: Toggle Kurangi / Tambah saldo.
*   **Preview Saldo**: Real-time. Merah jika hasil < Rp 5.000.
*   **Alasan Koreksi**: Wajib minimum 20 karakter. Counter karakter tampil.
*   **Kategori Koreksi**: Dropdown untuk klasifikasi audit yang lebih baik.
*   **Validasi Saldo Minus**: Tidak boleh melebihi saldo terkini untuk jenis "Kurangi".

---

### Screen 13: Konfirmasi Koreksi (Dialog Keamanan)

#### ASCII Mockup — Dialog Konfirmasi
```
+------------------------------------------+
|                                          |
|  ┌──────────────────────────────────┐    |
|  │  ⚠️  KONFIRMASI KOREKSI SALDO    │    |
|  │                                  │    |
|  │  Aksi ini bersifat PERMANEN dan  │    |
|  │  akan tercatat dalam Audit Log   │    |
|  │  yang dapat diperiksa oleh       │    |
|  │  Super Admin kapan saja.         │    |
|  │                                  │    |
|  │  Siswa  : Siti Aminah (7-A)      │    |
|  │  Jenis  : Kurangi Saldo          │    |
|  │  Nominal: -Rp 10.000             │    |
|  │  Saldo baru: Rp 5.000            │    |
|  │  Alasan : Salah input nominal... │    |
|  │  Kategori: Kesalahan Kasir       │    |
|  │                                  │    |
|  │  Ketik "KOREKSI" untuk lanjut:   │    |
|  │  [ _________________ ]           │    |
|  │                                  │    |
|  │  [ Batal ]   [ ✔ PROSES ]        │    |
|  └──────────────────────────────────┘    |
+------------------------------------------+
```

> **Rekomendasi Sistem**: Untuk koreksi > Rp 500.000, tambahkan verifikasi OTP atau persetujuan (approval) dari Super Admin untuk keamanan berlapis.

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

### Screen 14: Riwayat Transaksi Sekolah

Daftar SEMUA transaksi yang terjadi di sekolah ini (top-up, belanja, koreksi, VA).

#### ASCII Mockup
```
+------------------------------------------+
|  ← Kembali  Riwayat Transaksi     [📅]  |
|                                          |
|  Filter: [Semua ▼]  [17 Jun 2026 ▼]     |
|  [ Semua Petugas ▼]                      |
|                                          |
|  Ringkasan Hari Ini:                     |
|  Top-Up: +Rp 1.250.000  Koreksi: -Rp 35k|
|  Belanja: Rp 4.780.000                   |
|  ─────────────────────────────────────── |
|  ┌──────────────────────────────────┐    |
|  │ ↑ TOP-UP   Ahmad Subarjo   13:25 │    |
|  │   +Rp 50.000 · Tunai             │    |
|  │   Oleh: Budi H. · Ref: TXN-0024  │    |
|  └──────────────────────────────────┘    |
|  ┌──────────────────────────────────┐    |
|  │ 🛒 BELANJA  Rian Hidayat   13:20 │    |
|  │   -Rp 15.000 · Warung Bude Sari  │    |
|  │   Oleh: Sari D. · Ref: TRX-0531  │    |
|  └──────────────────────────────────┘    |
|  ┌──────────────────────────────────┐    |
|  │ ⚖️ KOREKSI Siti Aminah     13:40 │    |
|  │   -Rp 10.000 · Kesalahan Kasir   │    |
|  │   Oleh: Budi H. · Ref: ADJ-0003  │    |
|  └──────────────────────────────────┘    |
|                                          |
|  Total hari ini: 287 transaksi           |
+------------------------------------------+
| [🏠 Home] [👤 Siswa] [👥 Pengguna] [💸] [📊]|
+------------------------------------------+
```

#### Elemen & Aksi Interaksi
*   **Filter Jenis**: Semua / Top-Up Tunai / Top-Up VA / Belanja / Koreksi / Registrasi Kartu.
*   **Filter Tanggal**: Date picker → preset Hari Ini / Minggu Ini / Bulan Ini / Custom.
*   **Filter Petugas**: Dropdown semua petugas kantin sekolah ini + "Admin Keuangan".
*   **Tap Kartu Transaksi** → **Screen 14B: Detail Transaksi**.
*   **Ringkasan Footer**: Akumulasi per jenis untuk rentang yang dipilih.

---

### Screen 14B: Detail Transaksi

```
+------------------------------------------+
|  ← Kembali       Detail Transaksi        |
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
|  │  Dilakukan oleh Budi Hartono     │    |
|  │  Jabatan        Admin Keuangan   │    |
|  │  Waktu          17 Jun, 13:25:07 │    |
|  │  Catatan        Titipan ibu      │    |
|  └──────────────────────────────────┘    |
|                                          |
|  [ 🖨️ CETAK ULANG STRUK ]               |
|  [ 🚨 LAPORKAN TRANSAKSI MENCURIGAKAN ] |
+------------------------------------------+
```

---

### Screen 15: Laporan Keuangan (Ringkasan Periode)

Halaman rekapitulasi keuangan sekolah per periode waktu.

#### ASCII Mockup
```
+------------------------------------------+
|  ← Kembali    Laporan Keuangan           |
|                                          |
|  Pilih Periode:                          |
|  [Hari Ini ▼]  01 Jun – 17 Jun 2026      |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │  📈 Ringkasan Periode            │    |
|  │  ─────────────────────────────   │    |
|  │  Total Top-Up Tunai  Rp 8.450.000│    |
|  │  Total Top-Up VA     Rp 5.200.000│    |
|  │  Total Koreksi        -Rp 120.000│    |
|  │  Total Belanja       Rp 9.780.000│    |
|  │  ─────────────────────────────   │    |
|  │  Net Saldo Beredar  Rp 13.530.000│    |
|  │  Jumlah Transaksi        287     │    |
|  │  Siswa Aktif Bertransaksi  98    │    |
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
|  └──────────────────────────────────┘    |
|                                          |
|  Siswa Saldo Rendah (<Rp 5.000): 15      |
|  Siswa Saldo Nol: 3                      |
|                                          |
|  [📊 Grafik Tren]  [📤 Export Laporan]  |
+------------------------------------------+
| [🏠 Home] [👤 Siswa] [👥 Pengguna] [💸] [📊]|
+------------------------------------------+
```

---

### Screen 16: Grafik Tren Transaksi

```
+------------------------------------------+
|  ← Kembali    Tren Transaksi             |
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
|  │  Omzet Belanja per Stan          │    |
|  │  ████████ Bude Sari (42%)        │    |
|  │  ██████   Koperasi (28%)         │    |
|  │  ████     Stan Bakso (18%)       │    |
|  │  ██       Nasi Goreng (12%)      │    |
|  └──────────────────────────────────┘    |
|                                          |
|  Rata-rata Harian:                       |
|  Top-Up : Rp 497.000/hari               |
|  Koreksi: Rp 7.050/hari                 |
|  Belanja: Rp 575.000/hari               |
+------------------------------------------+
```

---

### Screen 17: Export & Kirim Laporan

```
+------------------------------------------+
|  ← Kembali       Export Laporan          |
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
|  ☐ Data Orang Tua                       |
|                                          |
|  Kirim Ke:                               |
|  [ kepsekolah@smp-terpadu.sch.id    ]    |
|  [+ Tambah Penerima]                     |
|  ─────────────────────────────────────── |
|                                          |
|  [ 📤 GENERATE & KIRIM LAPORAN ]         |
|                                          |
|  [ ⬇️ UNDUH KE PERANGKAT ]              |
+------------------------------------------+
```

---

### Screen 18: Audit Log (Semua Aktivitas Sekolah)

Admin Keuangan bisa melihat SEMUA aktivitas di sekolahnya, bukan hanya miliknya.

#### ASCII Mockup
```
+------------------------------------------+
|  ← Kembali    Audit Log Sekolah   [📅]  |
|                                          |
|  Transparansi penuh semua aktivitas      |
|  admin & petugas di SMP Terpadu.         |
|                                          |
|  Filter: [Semua Aksi ▼] [Semua Aktor ▼] |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │ ● KOREKSI_SALDO        13:40     │    |
|  │   Budi Hartono (Admin Keuangan)  │    |
|  │   Koreksi saldo Siti Aminah      │    |
|  │   -Rp 10.000 (Salah input...)    │    |
|  └──────────────────────────────────┘    |
|  ┌──────────────────────────────────┐    |
|  │ 🛒 BELANJA             13:20     │    |
|  │   Sari Dewi (Petugas Kantin)     │    |
|  │   Ahmad Subarjo -Rp 15.000       │    |
|  │   Warung Bude Sari               │    |
|  └──────────────────────────────────┘    |
|  ┌──────────────────────────────────┐    |
|  │ 👤 TAMBAH_SISWA        10:00     │    |
|  │   Budi Hartono (Admin Keuangan)  │    |
|  │   Mendaftarkan Dian Permata      │    |
|  │   NIS: 20260121 Kelas 7-C        │    |
|  └──────────────────────────────────┘    |
+------------------------------------------+
```

#### Elemen & Aksi Interaksi
*   **Filter Aksi**: TOPUP / KOREKSI / BELANJA / REGISTRASI_KARTU / TAMBAH_SISWA / TAMBAH_ORTU / TAMBAH_PETUGAS / BLOKIR_AKUN.
*   **Filter Aktor**: Admin Keuangan (nama saya) / Semua Petugas Kantin / spesifik petugas.
*   **Tap Log** → **Screen 18B: Detail Audit Log (JSON Diff)**.

---

### Screen 18B: Detail Audit Log

```
+──────────────────────────────────────────+
|                  ───                     |
|  Detail Log Perubahan                    |
|  KOREKSI SALDO                           |
|                                          |
|  Pelaksana  : Budi Hartono               |
|  Jabatan    : Admin Keuangan             |
|  Target     : Siti Aminah               |
|  Waktu      : 17 Jun 2026, 13:40:22      |
|  IP / Device: 192.168.1.15 · Android     |
|                                          |
|  Perubahan Data:                         |
|  ┌────────────┐  ┌────────────────────┐  |
|  │  SEBELUM   │  │  SESUDAH           │  |
|  │ {          │  │ {                  │  |
|  │  "balance" │  │  "balance":        │  |
|  │  : 15000   │  │   5000,            │  |
|  │ }          │  │  "reason":         │  |
|  │            │  │  "Salah input...", │  |
|  │            │  │  "category":       │  |
|  │            │  │  "Kasir Error"     │  |
|  │            │  │ }                  │  |
|  └────────────┘  └────────────────────┘  |
|                                          |
|  [ TUTUP ]                               |
+──────────────────────────────────────────+
```

---

### Screen 19: Notifikasi

```
+------------------------------------------+
|  ← Kembali       Notifikasi              |
|  [ Tandai Semua Dibaca ]                  |
|                                          |
|  HARI INI                                |
|  ┌──────────────────────────────────┐    |
|  │ ⚠️ Saldo Rendah Terdeteksi  BARU │    |
|  │   15 siswa memiliki saldo        │    |
|  │   di bawah Rp 5.000.             │    |
|  │   Periksa daftar →               │    |
|  └──────────────────────────────────┘    |
|  ┌──────────────────────────────────┐    |
|  │ 👤 Ortu Baru Mendaftar     09:30 │    |
|  │   Hasan Basri mendaftar sebagai  │    |
|  │   Orang Tua Ahmad Subarjo.       │    |
|  │   [ Verifikasi Sekarang → ]      │    |
|  └──────────────────────────────────┘    |
|  ┌──────────────────────────────────┐    |
|  │ 🔒 Koreksi Besar Terdeteksi 08:00│    |
|  │   Koreksi Rp 500.000 dilakukan   │    |
|  │   memerlukan perhatian.          │    |
|  └──────────────────────────────────┘    |
|                                          |
|  KEMARIN                                 |
|  ┌──────────────────────────────────┐    |
|  │ ✔ Top-Up Berhasil         13:25  │    |
|  │   Ahmad Subarjo +Rp 50.000       │    |
|  └──────────────────────────────────┘    |
+------------------------------------------+
```

---

### Screen 20: Profil & Pengaturan Akun

```
+------------------------------------------+
|  Profil Saya                             |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │     (Avatar Inisial BH) [✏️ Edit] │    |
|  │     Budi Hartono                 │    |
|  │     Admin Keuangan               │    |
|  │     SMP Terpadu                  │    |
|  │     ● Akun Aktif                 │    |
|  └──────────────────────────────────┘    |
|                                          |
|  INFORMASI AKUN                          |
|  ┌──────────────────────────────────┐    |
|  │  📧 budi.finance@f.com           │    |
|  │  👤 Username: budi_fin           │    |
|  │  🏫 Sekolah: SMP Terpadu         │    |
|  │  🪪 Bergabung: 01 Jun 2026       │    |
|  └──────────────────────────────────┘    |
|                                          |
|  KEAMANAN                                |
|  ┌──────────────────────────────────┐    |
|  │  🔒 Ubah Kata Sandi           >  │    |
|  │  📱 Sesi Aktif (2 sesi)       >  │    |
|  │  🔔 Pengaturan Notifikasi     >  │    |
|  └──────────────────────────────────┘    |
|                                          |
|  TENTANG                                 |
|  ┌──────────────────────────────────┐    |
|  │  ℹ️  Versi App: 2.0.0            │    |
|  │  📄 Kebijakan Privasi         >  │    |
|  │  🤝 Syarat & Ketentuan        >  │    |
|  └──────────────────────────────────┘    |
|                                          |
|  ┌──────────────────────────────────┐    |
|  │  🚪 Keluar dari Akun          >  │    |
|  └──────────────────────────────────┘    |
+------------------------------------------+
| [🏠 Home] [👤 Siswa] [👥 Pengguna] [💸] [📊]|
+------------------------------------------+
```

---

### Screen 20A: Sesi Aktif

```
+------------------------------------------+
|  ← Kembali       Sesi Aktif              |
|                                          |
|  📱 Sesi saat ini                        |
|  ┌──────────────────────────────────┐    |
|  │  Samsung Galaxy A55              │    |
|  │  Android 14 · Jakarta            │    |
|  │  Login: 17 Jun 2026, 08:00       │    |
|  │  ● Aktif Sekarang                │    |
|  └──────────────────────────────────┘    |
|                                          |
|  📱 Sesi lain                            |
|  ┌──────────────────────────────────┐    |
|  │  iPhone 14 Pro                   │    |
|  │  iOS 17.4 · Bandung              │    |
|  │  Login: 15 Jun 2026, 09:30       │    |
|  │  Terakhir aktif: 2 hari lalu     │    |
|  │  [ AKHIRI SESI INI ]             │    |
|  └──────────────────────────────────┘    |
|                                          |
|  [ AKHIRI SEMUA SESI LAIN ]             |
+------------------------------------------+
```

---

## 4. Navigasi & Routing

| Screen | Route Flutter | Trigger |
|---|---|---|
| Login | `/login` | App start, logout |
| Dashboard Beranda | `/finance` | Post-login |
| Manajemen Siswa | `/finance/students` | Tab "Siswa" |
| Tambah Siswa | `/finance/students/add` | Tombol [+] |
| Detail Siswa | `/finance/students/:id` | Tap kartu siswa |
| Edit Profil Siswa | `/finance/students/:id/edit` | Tombol ✏️ |
| Registrasi Kartu | `/finance/students/:id/card` | Tap "Registrasi Kartu" |
| Manajemen Pengguna | `/finance/users` | Tab "Pengguna" |
| Detail Orang Tua | `/finance/users/parents/:id` | Tap kartu ortu |
| Tambah Orang Tua | `/finance/users/parents/add` | Tombol [+] |
| Detail Petugas | `/finance/users/staff/:id` | Tap kartu petugas |
| Tambah Petugas | `/finance/users/staff/add` | Tombol [+] |
| Top-Up Step 1 | `/finance/topup` | Tombol cepat / Tab |
| Top-Up Step 2 | `/finance/topup/confirm` | Cari siswa sukses |
| Koreksi Step 1 | `/finance/correction` | Tombol cepat |
| Koreksi Step 2 | `/finance/correction/form` | Cari siswa sukses |
| Konfirmasi Koreksi | `/finance/correction/confirm` | Lanjut dari form |
| Riwayat Transaksi | `/finance/history` | Tab "Transaksi" |
| Detail Transaksi | `/finance/history/:id` | Tap kartu transaksi |
| Laporan | `/finance/report` | Tab "Laporan" / tombol |
| Grafik Tren | `/finance/report/chart` | Tombol grafik |
| Export Laporan | `/finance/report/export` | Tombol export |
| Audit Log | `/finance/audit` | Menu Settings / shortcut |
| Notifikasi | `/finance/notifications` | Ikon 🔔 |
| Profil | `/finance/profile` | Ikon 👤 |
| Sesi Aktif | `/finance/profile/sessions` | Menu Sesi Aktif |

---

## 5. Integrasi Database

### Tabel yang Diakses (Read)
| Tabel | Kolom Kunci | Keterangan |
|---|---|---|
| `profiles` | `id, full_name, email, role, is_active, school_id` | Data semua pengguna sekolah |
| `students` | `id, profile_id, nis, class, balance, card_uid` | Data saldo & kartu siswa |
| `parents` | `id, profile_id, student_ids, relation` | Data & link ortu ke siswa |
| `canteen_operators` | `id, profile_id, canteen_name, assigned_school` | Data petugas & stan kantin |
| `transactions` | `student_id, type, amount, method, actor_id, created_at` | Semua riwayat transaksi |
| `audit_logs` | `actor_id, action_type, old_value, new_value, school_id` | Log aktivitas semua aktor |
| `finance_officers` | `id, profile_id, assigned_school` | Data penugasan admin keuangan |
| `schools` | `id, name, domain, settings` | Info sekolah & konfigurasinya |
| `notifications` | `user_id, title, body, is_read, created_at` | Notifikasi per pengguna |

### Tabel yang Dimodifikasi (Write)
| Tabel | Operasi | Trigger |
|---|---|---|
| `students` | `UPDATE balance, card_uid, is_active` | Top-Up, Koreksi, Registrasi Kartu, Blokir |
| `profiles` | `INSERT, UPDATE` | Tambah Siswa/Ortu/Petugas, Edit Profil, Blokir |
| `students` | `INSERT` | Tambah Siswa Baru |
| `parents` | `INSERT, UPDATE` | Tambah Ortu, Link Ortu ke Siswa |
| `canteen_operators` | `INSERT, UPDATE` | Tambah Petugas, Edit Petugas, Ganti Stan |
| `transactions` | `INSERT` | Setiap Top-Up & Koreksi |
| `audit_logs` | `INSERT` | Setiap aksi (otomatis via DB trigger / kode) |
| `notifications` | `INSERT` | Alert saldo rendah, konfirmasi aksi penting |

### RLS Policies (Admin Keuangan)
*   **`students`**: `WHERE school_id = (SELECT assigned_school FROM finance_officers WHERE profile_id = auth.uid())`.
*   **`profiles`**: Hanya READ untuk role `student`, `parent`, `petugas_kantin` di sekolah sama. Tidak bisa read `super_admin` atau `petugas_keuangan` lain.
*   **`audit_logs`**: READ `WHERE school_id = assigned_school`. Tidak bisa READ log sekolah lain.
*   **`canteen_operators`**: READ & WRITE hanya untuk `assigned_school` yang sama.
*   **`transactions`**: READ semua transaksi `school_id` sekolahnya. WRITE hanya untuk top-up & koreksi.
*   **Tidak bisa**: DELETE pada `transactions`, `audit_logs`, atau `profiles` (soft-delete only).

---

## 6. State & Error Handling

| Kondisi | Tampilan |
|---|---|
| Loading data | `CupertinoActivityIndicator` di tengah layar + skeleton loading |
| Data kosong | Ilustrasi + teks informatif + CTA relevan |
| Koneksi offline | Banner merah atas + Snackbar: *"Tidak ada koneksi internet"* |
| Saldo tidak cukup untuk koreksi | Field merah + teks peringatan inline |
| Alasan koreksi terlalu pendek | Tombol disabled + counter karakter merah |
| UID Kartu sudah dipakai siswa lain | Dialog error + nama & kelas pemilik kartu lama |
| Session expired | Redirect ke Login + Snackbar info |
| NIS sudah terdaftar (duplikat) | Inline error di field NIS + nama siswa yang sudah pakai |
| Email duplikat saat tambah ortu | Inline error: *"Email ini sudah terdaftar"* |
| Username petugas duplikat | Inline error: *"Username sudah digunakan"* |
| Server error (5xx) | Snackbar + tombol "Coba Lagi" |
| Timeout (>15 detik) | Dialog timeout + opsi coba lagi |
| Konfirmasi koreksi salah ketik | Tombol PROSES disabled, field shake animation |

---

## 7. Sistem Notifikasi Push

Admin Keuangan menerima notifikasi push otomatis untuk:

| Trigger | Notifikasi |
|---|---|
| Siswa saldo < Rp 5.000 | "⚠️ {jumlah} siswa memiliki saldo rendah" (batch, 1x/hari) |
| Orang tua baru mendaftar | "👤 {nama} mendaftar sebagai orang tua {nama_siswa}" |
| Koreksi > Rp 500.000 oleh petugas manapun | "🔒 Koreksi besar terdeteksi: Rp {nominal}" |
| Laporan bulanan siap | "📊 Laporan {bulan} siap diunduh" |
| Petugas kantin tidak login (jam 10 pagi) | "🏪 {nama_stan} belum login hari ini" |
| Top-Up VA berhasil oleh orang tua | "✅ Top-Up VA {nama_siswa} Rp {nominal}" |

---

## 8. Aksesibilitas & UX Rules

*   **Semua tombol aksi destruktif** (blokir, koreksi, hapus kartu, hapus siswa) wajib melalui Cupertino Dialog konfirmasi.
*   **Koreksi nominal besar** (> Rp 500.000): wajib ketik konfirmasi teks "KOREKSI" sebelum proses.
*   **Nominal uang** selalu diformat `Rp X.XXX.XXX` menggunakan `NumberFormat.currency`.
*   **Timestamp** selalu ditampilkan dalam zona waktu lokal perangkat (`DateFormat.yMMMd().add_Hm()`).
*   **Pull-to-refresh** tersedia di semua daftar (siswa, transaksi, audit log, pengguna).
*   **Infinite scroll / pagination** untuk daftar lebih dari 20 item.
*   **Haptic feedback**: Getaran ringan saat transaksi berhasil, getaran keras saat error.
*   **Dark mode**: Semua layar mendukung tema gelap otomatis sesuai setting perangkat.
*   **Font scaling**: Layout responsif terhadap font size accessibility perangkat (max 1.3x).

---

## 9. Rekomendasi Sistem yang Baik

Berdasarkan praktik terbaik sistem school payment yang saya rekomendasikan:

### ✅ Hierarki Peran yang Jelas (RBAC)

```
Super Admin
    ├── Bisa kelola semua Admin Keuangan
    ├── Bisa lihat data SEMUA sekolah
    └── Konfigurasi sistem global

Admin Keuangan (Wakil Presiden)
    ├── Kelola Siswa, Ortu, Petugas (scope sekolahnya)
    ├── Bisa top-up & koreksi saldo
    ├── Lihat semua audit log sekolahnya
    └── TIDAK bisa kelola admin keuangan lain

Petugas Kantin (Kasir)
    ├── Transaksi belanja saja
    ├── Lihat saldo siswa saat tap kartu
    └── Tidak bisa top-up atau koreksi

Orang Tua
    ├── Top-Up via VA/QRIS (self-service)
    ├── Lihat saldo & transaksi anak saja
    └── Tidak bisa koreksi

Siswa
    ├── Lihat saldo & riwayat transaksi sendiri
    └── Tap kartu untuk belanja
```

### ✅ Keamanan Berlapis

| Layer | Implementasi |
|---|---|
| Autentikasi | JWT via Supabase Auth |
| Otorisasi | Row Level Security (RLS) PostgreSQL |
| Audit Trail | `audit_logs` immutable (append-only) |
| Koreksi Besar | Verifikasi teks + log khusus |
| Sesi Ganda | Monitor & akhiri dari app |
| Data Sensitif | Enkripsi di transit (HTTPS) + at-rest |

### ✅ Alur Top-Up yang Ideal

```
TUNAI (Admin Keuangan)          VA/QRIS (Orang Tua)
        │                               │
        ▼                               ▼
   Cari Siswa                    Pilih Nominal
        │                               │
        ▼                               ▼
   Input Nominal               Generate VA/QR Code
        │                               │
        ▼                               ▼
   Konfirmasi                  Bayar (Mandiri/BNI/dsb)
        │                               │
        ▼                               ▼
   Proses (Atomik)              Webhook Konfirmasi Bank
        │                               │
        ▼                               ▼
   Audit Log Otomatis           Saldo Bertambah Otomatis
        │                               │
        ▼                               ▼
   Notif ke Ortu               Notif ke Ortu & Admin
```

### ✅ Prinsip Data Integrity

1. **Atomik**: Setiap top-up/koreksi adalah satu transaksi database — jika gagal di tengah, semua dibatalkan.
2. **Immutable Audit**: `audit_logs` tidak boleh di-DELETE atau di-UPDATE oleh siapapun, termasuk Super Admin.
3. **Soft Delete**: Siswa/ortu/petugas yang "dihapus" hanya di-`is_active = false`, data tetap ada untuk audit.
4. **Saldo Non-Negatif**: Database constraint `CHECK (balance >= 0)` mencegah saldo minus dari sisi DB.
5. **Idempotency**: Setiap transaksi punya `reference_id` unik untuk mencegah double-posting.

---

## 10. Kredensial Demo (Development)

| Role | Username | Password | Keterangan |
|---|---|---|---|
| Admin Keuangan | `budi_fin` | `budi123` | Akun default SMP Terpadu |
| (alternatif email) | `budi.finance@f.com` | `budi123` | Login dengan email |

> **Catatan**: Ganti kredensial ini sebelum deploy ke production. Admin Keuangan tidak menggunakan NISN — hanya `username` atau `email`.
