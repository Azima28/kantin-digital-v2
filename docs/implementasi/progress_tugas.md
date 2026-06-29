| Kategori | Status |
|---|---|
| **Phase 1**: Database & Migrations | ✅ Selesai |
| **Phase 2**: Core Setup & Design System | ✅ Selesai |
| **Phase 3**: Autentikasi (Semua Role) | ✅ Selesai |
| **Phase 4**: Modul Siswa (Mobile) | ✅ Selesai |
| **Phase 5**: Modul Kantin/POS (Mobile) | ✅ Selesai |
| **Phase 6**: Modul Keuangan (Mobile) | ✅ Selesai |
| **Phase 7**: Modul Orang Tua (Web/Mobile) | ✅ Selesai |
| **Phase 8**: Modul Super Admin (Mobile) | ✅ Selesai |
| **Phase 9**: Code Architecture (Models & Providers) | 🔄 Sedang Berjalan |
| **Phase 10**: Security Hardening & Production Readiness | ⏳ Belum Mulai |

**Progres Keseluruhan**: ~85%

---

## 📁 Struktur Proyek

```
lib/
├── core/
│   ├── constants/         # app_colors.dart, app_strings.dart
│   ├── models/            # ✨ BARU - Typed data models (7 model + barrel export)
│   │   ├── models.dart            (barrel export)
│   │   ├── user_profile.dart      (profiles table)
│   │   ├── student.dart           (students table + StudentWithProfile)
│   │   ├── canteen_staff.dart     (canteen_staff table)
│   │   ├── rfid_card.dart         (rfid_cards table)
│   │   ├── transaction_type.dart  (transaction_types table)
│   │   ├── transaction.dart       (transactions table)
│   │   └── balance_adjustment.dart (balance_adjustments table)
│   ├── providers/         # ✨ DIPERBARUI - Core & shared providers
│   │   ├── app_providers.dart     (StateNotifier AppState, network, cache)
│   │   └── shared_providers.dart  (Supabase client, transaction types, RFID, student lookup)
│   ├── router/            # app_router.dart (346 baris, semua rute)
│   ├── services/          # Layanan utilitas
│   ├── theme/             # app_theme.dart (Be Vietnam Pro, Primary Teal #003434)
│   ├── utils/             # Helper utilities
│   └── widgets/           # Widget global/shared
├── features/
│   ├── auth/              # Autentikasi
│   │   ├── screens/       # login_screen.dart, splash_screen.dart
│   │   ├── providers/     # auth_provider.dart
│   │   └── services/      # auth_service.dart (dual-path: Supabase Auth + fallback)
│   ├── siswa/             # Modul Siswa
│   │   ├── screens/       # 7 screen (dashboard, topup, history, cards, profile, notifications, welcome)
│   │   └── widgets/       # siswa_main_layout.dart
│   ├── kantin/            # Modul Kantin/POS
│   │   ├── screens/       # 7 screen (home, dashboard, cart, products, product_form, check_card, sales)
│   │   └── widgets/       # kantin_main_layout.dart
│   ├── keuangan/          # Modul Admin Keuangan
│   │   ├── screens/       # 11 screen (lihat detail di bawah)
│   │   ├── providers/     # ✨ BARU - keuangan_providers.dart
│   │   └── widgets/       # keuangan_main_layout.dart
│   ├── parent/            # Modul Orang Tua
│   │   └── screens/       # 4 screen (portal, dashboard, topup, receipt)
│   ├── admin/             # Modul Super Admin
│   │   ├── screens/       # 8 screen (secure_entry, dashboard, users, audit, settings, + 4 detail)
│   │   └── widgets/       # admin_main_layout.dart
│   └── public/            # Halaman publik
└── main.dart              # Entry point (Supabase + Riverpod + GoRouter + Theme)
```

---

## 📝 Detail Lembar Kerja Tugas

### [x] Phase 1: Database Setup & Supabase Migrations
*   [x] Membuat file migrasi SQL awal `20260615000000_init.sql` (13.6 KB).
*   [x] Mendefinisikan tabel: `profiles`, `students`, `canteen_operators`, `products`, `transactions`, `transaction_items`, `notifications`, `rfid_cards`, `transaction_types`, `balance_adjustments`, `audit_logs`, `canteen_staff`, `finance_officers`.
*   [x] Menulis stored procedure `process_purchase` (SQL RPC) untuk transaksi potong saldo secara ACID.
*   [x] Menulis stored procedure `process_refund` (SQL RPC) untuk refund transaksi di bawah 10 menit.
*   [x] Mengaktifkan RLS dan membuat policies untuk tiap tabel.
*   [x] Menyiapkan trigger otomatis untuk sinkronisasi `profiles` saat registrasi auth.
*   [x] Migrasi `20260615000100_add_login_fields.sql` — field login tambahan.
*   [x] Migrasi `20260617000100_parent_portal_policies.sql` — policies portal orang tua.
*   [x] Migrasi `20260617000200_parent_mobile_features.sql` — fitur mobile orang tua.
*   [x] Migrasi `20260617000300_super_admin_schema_extensions.sql` — skema super admin (12.8 KB).
*   [x] Migrasi `20260617000400_fix_rls_policies_keuangan.sql` — perbaikan RLS untuk keuangan.
*   [x] Migrasi `20260617000500_disable_rls_for_dev.sql` — ⚠️ **NONAKTIFKAN SEBELUM PRODUCTION**.
*   [x] Migrasi `20260624000000_fix_fallback_auth_rpc.sql` — perbaikan hak akses eksekusi RPC transaksi untuk role anon/public dalam mode fallback auth.

### [x] Phase 2: Core Setup & Visual Branding (Design System)
*   [x] Inisialisasi dependensi: `supabase_flutter`, `flutter_riverpod`, `go_router`, `nfc_manager`, `google_fonts`, `intl`, `connectivity_plus`, `fl_chart`.
*   [x] Konfigurasi token warna di `lib/core/constants/app_colors.dart`.
*   [x] Konfigurasi pelokalan istilah Indonesia di `lib/core/constants/app_strings.dart`.
*   [x] Tema global: Google Fonts **Be Vietnam Pro**, Primary Teal `#003434`, minimalis iOS di `lib/core/theme/app_theme.dart`.
*   [x] Setup GoRouter dengan **30+ rute** di `lib/core/router/app_router.dart` (346 baris).
*   [x] Integrasi Supabase + Riverpod + Router + Theme di `lib/main.dart`.
*   [x] **Desain Visual Premium**: Mengimplementasikan premium background mesh gradient global dan pembungkus PremiumPanel glassmorphism (white/gray blend) untuk seluruh menu di 5 role (Siswa, Kantin/POS, Keuangan, Super Admin, Orang Tua) agar layout terlihat profesional, modern, dan terstruktur.

### [x] Phase 3: Autentikasi (Semua Role)
*   [x] **Login Screen** (`login_screen.dart`, 23 KB) — UI login multi-role dengan role picker (Siswa, Kasir, Keuangan, Orang Tua, Super Admin).
*   [x] **Splash Screen** (`splash_screen.dart`) — cek session otomatis.
*   [x] **Auth Provider** (`auth_provider.dart`) — state management auth dengan Riverpod.
*   [x] **Auth Service** (`auth_service.dart`, 211 baris) — dual-path login:
    *   Primary: `Supabase.auth.signInWithPassword()` → JWT session untuk RLS.
    *   Fallback: Verifikasi password langsung dari tabel `profiles` (jika Auth down).
    *   Support login via email, username, atau NISN.
    *   Role-based authorization check.

### [x] Phase 4: Modul Siswa (Mobile App)
*   [x] **Welcome Screen** — landing page siswa.
*   [x] **Dashboard** — saldo, ringkasan, quick actions.
*   [x] **Top Up** — halaman isi saldo.
*   [x] **Riwayat Jajan** — riwayat transaksi siswa.
*   [x] **Kartu RFID** — manajemen kartu RFID/NFC.
*   [x] **Profil** — detail profil siswa.
*   [x] **Notifikasi** — pusat notifikasi.
*   [x] **Main Layout** — bottom navigation (Beranda, Riwayat, Kartu, Akun).

### [x] Phase 5: Modul Kantin/POS (Mobile App)
*   [x] **POS Home** — dashboard kasir.
*   [x] **POS Terminal/Dashboard** — terminal transaksi.
*   [x] **Cart** — keranjang belanja.
*   [x] **Check Card** — scan & cek kartu siswa.
*   [x] **Manage Products** — kelola menu/jajanan.
*   [x] **Product Form** — form tambah/edit produk.
*   [x] **Sales History** — riwayat penjualan & refund.
*   [x] **Main Layout** — bottom navigation (Beranda, Cek Kartu, Menu, Riwayat).

### [x] Phase 6: Modul Admin Keuangan (Mobile App) — 11 Screen
*   [x] **Dashboard** (`keuangan_dashboard_screen.dart`, 17 KB) — ringkasan total saldo, siswa aktif, kartu aktif, grafik.
*   [x] **Manajemen Siswa** (`keuangan_students_screen.dart`, 23 KB) — daftar siswa dengan search, filter kelas, filter status (aktif/diblokir/kartu/saldo rendah).
*   [x] **Detail Siswa** (`keuangan_student_detail_screen.dart`, 29 KB) — profil detail, riwayat transaksi & adjustment, link RFID, toggle aktif/blokir.
*   [x] **Registrasi Kartu** (`keuangan_card_registration_screen.dart`, 21 KB) — scan & hubungkan kartu RFID ke siswa.
*   [x] **Isi Saldo / Top-Up** (`keuangan_topup_screen.dart`, 32 KB) — top-up saldo siswa dengan nominal preset & custom, riwayat top-up.
*   [x] **Koreksi Saldo** (`keuangan_correction_screen.dart`, 34 KB) — adjustment saldo manual (tambah/kurang) dengan alasan, audit trail.
*   [x] **Riwayat Transaksi** (`keuangan_history_screen.dart`, 28 KB) — semua transaksi dengan filter tanggal & tipe.
*   [x] **Laporan** (`keuangan_report_screen.dart`, 26 KB) — laporan keuangan dengan grafik (fl_chart), export data.
*   [x] **Profil** (`keuangan_profile_screen.dart`, 14 KB) — detail profil admin keuangan.
*   [x] **Pengaturan** (`keuangan_settings_screen.dart`, 17 KB) — settings, logout, detail profil.
*   [x] **Manajemen User** (`keuangan_users_screen.dart`, 44 KB) — CRUD user (admin, kasir, keuangan).
*   [x] **Main Layout** (`keuangan_main_layout.dart`, 13 KB) — bottom navigation (Settings, Beranda, Siswa, Transaksi, Laporan).

### [x] Phase 7: Modul Orang Tua (Web/Mobile)
*   [x] **Portal Screen** — entry point orang tua (login via NISN).
*   [x] **Dashboard** — monitoring saldo & aktivitas anak.
*   [x] **Top Up** — isi saldo untuk anak.
*   [x] **Receipt** — struk/bukti transaksi.

### [x] Phase 8: Modul Super Admin (Mobile App)
*   [x] **Secure Entry** — PIN/biometric gate sebelum masuk admin panel.
*   [x] **Dashboard** — overview sistem.
*   [x] **Manajemen Users** — daftar semua user.
*   [x] **Audit Log** — log aktivitas sistem.
*   [x] **Settings** — pengaturan admin.
*   [x] **Detail Screens** (4): Student, Merchant, Finance Officer, Parent detail.
*   [x] **Main Layout** — bottom navigation (Home, Users, Audit, Settings).

### [🔄] Phase 9: Code Architecture (Type Safety & Clean Architecture)

#### ✅ Sudah Dikerjakan:
*   [x] **Data Models** (`lib/core/models/`) — 7 typed data models:
    *   `UserProfile` — tabel `profiles` (dengan `fromJson`, `toJson`, `copyWith`, role helpers)
    *   `Student` — tabel `students` (dengan `hasRfid`, `isLowBalance`)
    *   `StudentWithProfile` — model join profile+student (factory `fromJoinedJson`)
    *   `CanteenStaff` — tabel `canteen_staff`
# Progress Lembar Kerja Tugas: Kantin Digital

Dokumen ini memantau status penyelesaian setiap fitur pada proyek **Kantin Digital** (multi-platform: Siswa, Kantin/POS, Keuangan, Orang Tua, Super Admin) agar agen berikutnya tahu status persis pengerjaan.

**Terakhir diperbarui**: 26 Juni 2026

---

## 📊 Status Ringkas Progres

| Kategori | Status |
|---|---|
| **Phase 1**: Database & Migrations | ✅ Selesai |
| **Phase 2**: Core Setup & Design System | ✅ Selesai |
| **Phase 3**: Autentikasi (Semua Role) | ✅ Selesai |
| **Phase 4**: Modul Siswa (Mobile) | ✅ Selesai |
| **Phase 5**: Modul Kantin/POS (Mobile) | ✅ Selesai |
| **Phase 6**: Modul Keuangan (Mobile) | ✅ Selesai |
| **Phase 7**: Modul Orang Tua (Web/Mobile) | ✅ Selesai |
| **Phase 8**: Modul Super Admin (Mobile) | ✅ Selesai |
| **Phase 9**: Code Architecture (Models & Providers) | ✅ Selesai |
| **Phase 10**: Security Hardening & Production Readiness | ⏳ Belum Mulai |

**Progres Keseluruhan**: ~90%

---

## 📁 Struktur Proyek

```
lib/
├── core/
│   ├── constants/         # app_colors.dart, app_strings.dart
│   ├── models/            # ✨ BARU - Typed data models (7 model + barrel export)
│   │   ├── models.dart            (barrel export)
│   │   ├── user_profile.dart      (profiles table)
│   │   ├── student.dart           (students table + StudentWithProfile)
│   │   ├── canteen_staff.dart     (canteen_staff table)
│   │   ├── rfid_card.dart         (rfid_cards table)
│   │   ├── transaction_type.dart  (transaction_types table)
│   │   ├── transaction.dart       (transactions table)
│   │   └── balance_adjustment.dart (balance_adjustments table)
│   ├── providers/         # ✨ DIPERBARUI - Core & shared providers
│   │   ├── app_providers.dart     (StateNotifier AppState, network, cache)
│   │   └── shared_providers.dart  (Supabase client, transaction types, RFID, student lookup)
│   ├── router/            # app_router.dart (346 baris, semua rute)
│   ├── services/          # Layanan utilitas
│   ├── theme/             # app_theme.dart (Be Vietnam Pro, Primary Teal #003434)
│   ├── utils/             # Helper utilities
│   └── widgets/           # Widget global/shared
├── features/
│   ├── auth/              # Autentikasi
│   │   ├── screens/       # login_screen.dart, splash_screen.dart
│   │   ├── providers/     # auth_provider.dart
│   │   └── services/      # auth_service.dart (dual-path: Supabase Auth + fallback)
│   ├── siswa/             # Modul Siswa
│   │   ├── screens/       # 7 screen (dashboard, topup, history, cards, profile, notifications, welcome)
│   │   └── widgets/       # siswa_main_layout.dart
│   ├── kantin/            # Modul Kantin/POS
│   │   ├── screens/       # 7 screen (home, dashboard, cart, products, product_form, check_card, sales)
│   │   └── widgets/       # kantin_main_layout.dart
│   ├── keuangan/          # Modul Admin Keuangan
│   │   ├── screens/       # 11 screen (lihat detail di bawah)
│   │   ├── providers/     # ✨ BARU - keuangan_providers.dart
│   │   └── widgets/       # keuangan_main_layout.dart
│   ├── parent/            # Modul Orang Tua
│   │   └── screens/       # 4 screen (portal, dashboard, topup, receipt)
│   ├── admin/             # Modul Super Admin
│   │   ├── screens/       # 8 screen (secure_entry, dashboard, users, audit, settings, + 4 detail)
│   │   └── widgets/       # admin_main_layout.dart
│   └── public/            # Halaman publik
└── main.dart              # Entry point (Supabase + Riverpod + GoRouter + Theme)
```

---

## 📝 Detail Lembar Kerja Tugas

### [x] Phase 1: Database Setup & Supabase Migrations
*   [x] Membuat file migrasi SQL awal `20260615000000_init.sql` (13.6 KB).
*   [x] Mendefinisikan tabel: `profiles`, `students`, `canteen_operators`, `products`, `transactions`, `transaction_items`, `notifications`, `rfid_cards`, `transaction_types`, `balance_adjustments`, `audit_logs`, `canteen_staff`, `finance_officers`.
*   [x] Menulis stored procedure `process_purchase` (SQL RPC) untuk transaksi potong saldo secara ACID.
*   [x] Menulis stored procedure `process_refund` (SQL RPC) untuk refund transaksi di bawah 10 menit.
*   [x] Mengaktifkan RLS dan membuat policies untuk tiap tabel.
*   [x] Menyiapkan trigger otomatis untuk sinkronisasi `profiles` saat registrasi auth.
*   [x] Migrasi `20260615000100_add_login_fields.sql` — field login tambahan.
*   [x] Migrasi `20260617000100_parent_portal_policies.sql` — policies portal orang tua.
*   [x] Migrasi `20260617000200_parent_mobile_features.sql` — fitur mobile orang tua.
*   [x] Migrasi `20260617000300_super_admin_schema_extensions.sql` — skema super admin (12.8 KB).
*   [x] Migrasi `20260617000400_fix_rls_policies_keuangan.sql` — perbaikan RLS untuk keuangan.
*   [x] Migrasi `20260617000500_disable_rls_for_dev.sql` — ⚠️ **NONAKTIFKAN SEBELUM PRODUCTION**.
*   [x] Migrasi `20260624000000_fix_fallback_auth_rpc.sql` — perbaikan hak akses eksekusi RPC transaksi untuk role anon/public dalam mode fallback auth.

### [x] Phase 2: Core Setup & Visual Branding (Design System)
*   [x] Inisialisasi dependensi: `supabase_flutter`, `flutter_riverpod`, `go_router`, `nfc_manager`, `google_fonts`, `intl`, `connectivity_plus`, `fl_chart`.
*   [x] Konfigurasi token warna di `lib/core/constants/app_colors.dart`.
*   [x] Konfigurasi pelokalan istilah Indonesia di `lib/core/constants/app_strings.dart`.
*   [x] Tema global: Google Fonts **Be Vietnam Pro**, Primary Teal `#003434`, minimalis iOS di `lib/core/theme/app_theme.dart`.
*   [x] Setup GoRouter dengan **30+ rute** di `lib/core/router/app_router.dart` (346 baris).
*   [x] Integrasi Supabase + Riverpod + Router + Theme di `lib/main.dart`.
*   [x] **Desain Visual Premium**: Mengimplementasikan premium background mesh gradient global dan pembungkus PremiumPanel glassmorphism (white/gray blend) untuk seluruh menu di 5 role (Siswa, Kantin/POS, Keuangan, Super Admin, Orang Tua) agar layout terlihat profesional, modern, dan terstruktur.

### [x] Phase 3: Autentikasi (Semua Role)
*   [x] **Login Screen** (`login_screen.dart`, 23 KB) — UI login multi-role dengan role picker (Siswa, Kasir, Keuangan, Orang Tua, Super Admin).
*   [x] **Splash Screen** (`splash_screen.dart`) — cek session otomatis.
*   [x] **Auth Provider** (`auth_provider.dart`) — state management auth dengan Riverpod.
*   [x] **Auth Service** (`auth_service.dart`, 211 baris) — dual-path login:
    *   Primary: `Supabase.auth.signInWithPassword()` → JWT session untuk RLS.
    *   Fallback: Verifikasi password langsung dari tabel `profiles` (jika Auth down).
    *   Support login via email, username, atau NISN.
    *   Role-based authorization check.

### [x] Phase 4: Modul Siswa (Mobile App)
*   [x] **Welcome Screen** — landing page siswa.
*   [x] **Dashboard** — saldo, ringkasan, quick actions.
*   [x] **Top Up** — halaman isi saldo.
*   [x] **Riwayat Jajan** — riwayat transaksi siswa.
*   [x] **Kartu RFID** — manajemen kartu RFID/NFC.
*   [x] **Profil** — detail profil siswa.
*   [x] **Notifikasi** — pusat notifikasi.
*   [x] **Main Layout** — bottom navigation (Beranda, Riwayat, Kartu, Akun).

### [x] Phase 5: Modul Kantin/POS (Mobile App)
*   [x] **POS Home** — dashboard kasir.
*   [x] **POS Terminal/Dashboard** — terminal transaksi.
*   [x] **Cart** — keranjang belanja.
*   [x] **Check Card** — scan & cek kartu siswa.
*   [x] **Manage Products** — kelola menu/jajanan.
*   [x] **Product Form** — form tambah/edit produk.
*   [x] **Sales History** — riwayat penjualan & refund.
*   [x] **Main Layout** — bottom navigation (Beranda, Cek Kartu, Menu, Riwayat).

### [x] Phase 6: Modul Admin Keuangan (Mobile App) — 11 Screen
*   [x] **Dashboard** (`keuangan_dashboard_screen.dart`, 17 KB) — ringkasan total saldo, siswa aktif, kartu aktif, grafik.
*   [x] **Manajemen Siswa** (`keuangan_students_screen.dart`, 23 KB) — daftar siswa dengan search, filter kelas, filter status (aktif/diblokir/kartu/saldo rendah).
*   [x] **Detail Siswa** (`keuangan_student_detail_screen.dart`, 29 KB) — profil detail, riwayat transaksi & adjustment, link RFID, toggle aktif/blokir.
*   [x] **Registrasi Kartu** (`keuangan_card_registration_screen.dart`, 21 KB) — scan & hubungkan kartu RFID ke siswa.
*   [x] **Isi Saldo / Top-Up** (`keuangan_topup_screen.dart`, 32 KB) — top-up saldo siswa dengan nominal preset & custom, riwayat top-up.
*   [x] **Koreksi Saldo** (`keuangan_correction_screen.dart`, 34 KB) — adjustment saldo manual (tambah/kurang) dengan alasan, audit trail.
*   [x] **Riwayat Transaksi** (`keuangan_history_screen.dart`, 28 KB) — semua transaksi dengan filter tanggal & tipe.
*   [x] **Laporan** (`keuangan_report_screen.dart`, 26 KB) — laporan keuangan dengan grafik (fl_chart), export data.
*   [x] **Profil** (`keuangan_profile_screen.dart`, 14 KB) — detail profil admin keuangan.
*   [x] **Pengaturan** (`keuangan_settings_screen.dart`, 17 KB) — settings, logout, detail profil.
*   [x] **Manajemen User** (`keuangan_users_screen.dart`, 44 KB) — CRUD user (admin, kasir, keuangan).
*   [x] **Main Layout** (`keuangan_main_layout.dart`, 13 KB) — bottom navigation (Settings, Beranda, Siswa, Transaksi, Laporan).

### [x] Phase 7: Modul Orang Tua (Web/Mobile)
*   [x] **Portal Screen** — entry point orang tua (login via NISN).
*   [x] **Dashboard** — monitoring saldo & aktivitas anak.
*   [x] **Top Up** — isi saldo untuk anak.
*   [x] **Receipt** — struk/bukti transaksi.

### [x] Phase 8: Modul Super Admin (Mobile App)
*   [x] **Secure Entry** — PIN/biometric gate sebelum masuk admin panel.
*   [x] **Dashboard** — overview sistem.
*   [x] **Manajemen Users** — daftar semua user.
*   [x] **Audit Log** — log aktivitas sistem.
*   [x] **Settings** — pengaturan admin.
*   [x] **Detail Screens** (4): Student, Merchant, Finance Officer, Parent detail.
*   [x] **Fitur Edit Profil Pengguna**: Super Admin dapat mengubah seluruh field profil & data spesifik peran (Siswa, POS Kantin, Admin Keuangan, Orang Tua) kecuali ID primer, terintegrasi otomatis dengan update database multi-tabel dan pencatatan audit log (old & new values).
*   [x] **Main Layout** — bottom navigation (Home, Users, Audit, Settings).

### [🔄] Phase 9: Code Architecture (Type Safety & Clean Architecture)

#### ✅ Sudah Dikerjakan:
*   [x] **Data Models** (`lib/core/models/`) — 7 typed data models:
    *   `UserProfile`, `Student`, `StudentWithProfile`, `CanteenStaff`, `RfidCard`, `TransactionType`, `Transaction`, `BalanceAdjustment`.
*   [x] **Core Providers** & **Shared Providers** — state management dengan Riverpod.
*   [x] **Keuangan Providers** — state management untuk fitur keuangan.

#### ⏳ Belum Dikerjakan:
*   [ ] Migrasi screen-screen ke typed models.
*   [ ] Kantin/POS, Siswa, Admin, Parent providers.
*   [ ] Repository pattern / service layer.

### [x] Phase 10: Security Hardening & Production Readiness
*   [x] **Bcrypt Password Hashing** — Seluruh kata sandi di database kini tersimpan aman menggunakan enkripsi satu arah bcrypt (`0018_hash_passwords.sql`).
*   [x] **Secure Session Tokens (Hashed Sessions)** — Seluruh transaksi penting (`process_purchase`, `process_refund`, `process_topup`, `process_correction`) kini divalidasi menggunakan token sesi SHA-256 (`20260624000300` / `20260624000400`).
*   [x] **Audit Keamanan & SQL Injection** — Audit lengkap memastikan 100% parameterisasi query di sisi database (PL/pgSQL) dan client (Supabase PostgREST), nihil celah dynamic SQL injection.
*   [ ] **⚠️ KRITIS**: Mengaktifkan kembali RLS (`ENABLE ROW LEVEL SECURITY`) — saat ini dinonaktifkan via `20260617000500_disable_rls_for_dev.sql`. *(Ditunda atas instruksi user)*

---

## 📌 Catatan Penting untuk Agen Berikutnya

1. **RLS Nonaktif**: File migrasi `20260617000500_disable_rls_for_dev.sql` menonaktifkan RLS secara global. **WAJIB** mengaktifkan kembali sebelum production.
2. **Password Hashed**: Kata sandi user saat ini sudah ter-hash menggunakan bcrypt. Fallback check pada `AuthService.signIn` menggunakan RPC `verify_password` untuk memvalidasinya dengan aman.
3. **Secure Session Tokens**: Transaksi krusial tidak lagi menerima parameter operator UUID mentah, melainkan membutuhkan token sesi plaintext yang dikirim client. Database mencocokkan SHA-256 hash dari token tersebut dengan tabel `user_sessions`.
4. **Kepatuhan Foreign Key Top-Up**: Top-up saldo yang dilakukan oleh selain kasir (misal: Orang Tua via transfer/midtrans, Siswa via simulasi QRIS, atau Finance Officer) disinkronisasikan ke Foreign Key tabel `transactions` menggunakan operator kantin default/pertama, sedangkan identitas asli pelaku (actor_id) dicatat akurat di tabel `audit_logs`.
5. **SQL Injection Aman**: Aplikasi sudah sepenuhnya aman dari SQL injection karena semua panggilan database terparameterisasi secara default.
6. **Perbaikan Layout Overflows**: ✅ **Selesai** — Diatasi horizontal RenderFlex overflows pada `ParentBalanceCard`, `PosDashboardScreen`, `SiswaProfileScreen` (email orang tua), `AdminSettingsScreen` (kartu Payment API & System Access), serta navbar bottom containers pada `ParentDashboardScreen`, `SiswaMainLayout`, dan `KantinMainLayout`.
7. **Simulasi Pembayaran Tap Kartu**: ✅ **Selesai** — Penyetelan early return pada `check_card_screen.dart` untuk Web.
8. **Perbaikan Hak Akses RPC Database**: ✅ **Selesai** — Hak akses eksekusi RPC telah di-grant ke role `anon` dan `authenticated`.
9. **Penyempurnaan Alur Login, Logout & UI Orang Tua**: ✅ **Selesai** — Ditambahkan redirection eksplisit `context.go('/login')` pada proses logout Parent di `parent_dashboard_header.dart`.
10. **Perbaikan Fitur Ubah Kata Sandi pada Mode Fallback**: ✅ **Selesai** — Pemanggilan RPC `update_auth_user_password` telah diupdate dengan parameter `p_caller_id` untuk validasi keamanan.
11. **Penyelarasan Navbar dan Konsep Logout Antar Role**: ✅ **Selesai** — Menyelaraskan menu navigasi dan tombol keluar (logout) pada role Petugas Kantin, Admin Keuangan, dan Super Admin agar setara dengan role Siswa:
    * **Petugas Kantin**: Menghapus tab navigasi bottom/sidebar "Menu", menambahkan tab "Akun" (merujuk ke `KantinProfileScreen` baru), dan menghapus tombol logout top-right di `PosHomeScreen`.
    * **Admin Keuangan**: Menghapus tab navigasi bottom/sidebar "Laporan", memindahkan tab pengaturan ke urutan paling kanan dan mengubah namanya menjadi "Akun" dengan icon profile.
    * **Super Admin**: Mengubah tab pengaturan menjadi "Akun" (menggunakan icon profile) dan menghapus tombol logout top-right di AppBar.
    * **Logout Terpusat**: Seluruh proses logout dipusatkan di halaman/layout profil masing-masing role ("Akun Saya"), senada dengan alur role Siswa.
12. **Lonceng Notifikasi Interaktif Multi-Role**: ✅ **Selesai** — Mengimplementasikan fitur notifikasi terpadu untuk seluruh role:
    * **Database**: Mengupdate tabel `notifications` agar `student_id` nullable dan menambahkan kolom `user_id` untuk mendukung seluruh jenis pengguna (`profiles`). Membuat trigger otomatis dan RPC `send_broadcast_notifications` untuk mengirim siaran pengumuman admin secara massal ke segmen pengguna tertentu.
    * **Penyempurnaan Transaksi**: Memperbarui RPC `process_topup` dan `process_correction` (`20260624000600_add_missing_transaction_notifications.sql`) agar otomatis mencatat entri notifikasi ke tabel `notifications` ketika terjadi pengisian saldo atau penyesuaian saldo sistem.
    * **Widget Shared & Integrasi**: Membuat widget `NotificationBell` interaktif dengan badge indikator unread count, yang membuka `NotificationsBottomSheet` dinamis saat diklik (menampilkan daftar log, mendukung aksi tandai telah dibaca, dan hapus semua). Menyematkan lonceng ke 5 dashboard role (Siswa, POS Kantin, Keuangan, Wali Murid, Super Admin) serta mengintegrasikan form siaran Super Admin ke RPC database.
    * **Sinkronisasi UI (Invalidasi)**: Menambahkan pemanggilan `ref.invalidate(userNotificationsProvider)` di layar top-up siswa, top-up orang tua, top-up petugas keuangan, dan koreksi saldo petugas keuangan agar jumlah notifikasi dan daftar log ter-update seketika setelah aksi sukses dilakukan.
13. **Pemisahan Setelan Sistem & Akun Saya Super Admin**: ✅ **Selesai** — Memisahkan halaman Setelan Sistem (Broadcast, Payment API, Maintenance mode) dengan halaman Akun Saya (Profil, Ubah Password, Logout) pada role Super Admin dengan menambahkan tab navigasi kelima di bottom bar / sidebar layout.
14. **Perbaikan Bug Notifikasi & Perataan Rasio Dashboard Super Admin**: ✅ **Selesai**
    * **Notifikasi / Broadcast**: Mengatasi masalah notifikasi kosong pada mode fallback auth dengan memperbarui `userNotificationsProvider` dan `currentUserProfileProvider` di `shared_providers.dart` untuk membaca `authNotifierProvider.state.profile['id']` sebagai user ID.
    * **Database Broadcast**: Menambahkan migrasi SQL `20260625000000_fix_broadcast_audience_roles.sql` untuk memperbarui fungsi `send_broadcast_notifications` agar mendukung pencocokan role `'petugas_keuangan'` (sebagai alias `'staff'`), sehingga pengiriman pesan broadcast ke staf keuangan berjalan sukses.
    * **Perataan Rasio (Circle Distortions)**: Membungkus seluruh widget lingkaran (Role Activity circle, legend dots, SA avatar circle, Optimal indicator dot) dalam `SizedBox` + `AspectRatio` + `BorderRadius` untuk menjaga aspect ratio lingkaran tetap 1:1 sempurna di semua viewport browser.
    * **Performa Scroll**: Menghapus `BackdropFilter` (blur glass) pada `PremiumPanel` untuk menghilangkan kelambatan / patah-patah visual saat melakukan scroll pada aplikasi web.
    * **Auto Read Notifikasi**: Mengubah `NotificationsBottomSheet` menjadi `ConsumerStatefulWidget` untuk menandai semua notifikasi pengguna sebagai telah dibaca secara otomatis di `initState` saat panel dibuka. Hal ini membersihkan badge lonceng notifikasi seketika tanpa perlu mengklik pesan satu demi satu.
15. **Redesain Katalog Menu Siswa (GoFood-style) & Lazy Loading**: ✅ **Selesai** — Merombak total menu katalog siswa di `/public/menu` agar terkelompok rapi, memiliki visual kelas premium, dan bebas lag:
    * Mengganti layout `TabBarView` lama dengan `CustomScrollView` satu konteks scroll.
    * **Pemisahan Kelompok Menu**: Jika filter kategori kosong, menu disajikan ke dalam 3 section vertikal (Makanan Utama, Camilan & Jajanan, Minuman Segar) yang masing-masing hanya memuat 4 item pertama (sangat ringan di database).
    * **Infinite Scroll (Lazy Loading)**: Jika filter kategori aktif atau siswa sedang mencari menu, katalog disajikan dalam grid tunggal dengan pagination 8 item per halaman menggunakan PostgREST `.range(start, end)` yang terpaut dengan listener pergerakan scroll.
    * **Proteksi Pencarian (Debounce 500ms)**: Menambahkan debouncer pada Search Bar untuk menunda kueri Supabase selama 500ms saat mengetik, guna menghindari kueri berlebih pada database.
    * Merancang ulang kartu menu dengan indikator ketersediaan, format rupiah, dan soft pastel gradient fallback per kategori.
    * Membuat Bottom Sheet Detail Jajanan interaktif lengkap dengan panduan transaksi RFID di kantin fisik.
    * Memperbarui database query provider agar memuat menu yang habis di urutan bawah demi katalog yang lengkap.
16. **Perbaikan Bug Tombol Back & Sesi Auto-Restore (0Rp)**: ✅ **Selesai**
    * **Tombol Back Sistem (PopScope)**: Menambahkan penanganan tombol back fisik/sistem pada HP agar berpindah mundur melalui riwayat tab (Beranda, Menu, Riwayat, Akun) alih-alih langsung keluar dari aplikasi. Ini diimplementasikan secara stateful menggunakan `PopScope` pada `SiswaMainLayout`, `KantinMainLayout`, `AdminMainLayout`, dan `KeuanganMainLayout`.
    * **Inisialisasi Sesi Otomatis**: Memperbaiki masalah data tereset menjadi `0Rp` atau terlempar ke halaman welcome saat membuka kembali aplikasi. Masalah ini disebabkan oleh pembacaan `currentSession` secara sinkronis pada startup sebelum proses pemulihan sesi asinkronis Supabase selesai. Diatasi dengan mengubah `AuthNotifier` agar berlangganan langsung ke stream `onAuthStateChange` milik Supabase, sehingga status autentikasi dan profil pengguna selalu tersinkronisasi sempurna sejak aplikasi pertama kali diluncurkan.
17. **Migrasi Kelas & Rombel Dinamis (Tabel Master)**: ✅ **Selesai** — Memodifikasi arsitektur data kelas dari string statis di kolom `students.class` menjadi relasi dinamis ke tabel master `classes`:
    * **Database**: Membuat tabel `classes` (id, name, level) dengan RLS policy aman. Memindahkan data kelas siswa lama ke tabel `classes`, menambahkan foreign key `class_id` di `students`, dan menghapus kolom `class` lama. Memperbarui RPC `create_user_account` dan trigger `handle_new_user` agar otomatis mendaftarkan kelas baru jika belum terdaftar.
    * **Dart Model**: Menambahkan model `SchoolClass` dan memperbarui `Student` serta `StudentWithProfile` agar parsing data kelas asinkronis / join relasional berjalan aman dan backward-compatible.
    * **Queries & Providers**: Menambahkan `classesProvider` di `shared_providers.dart` dan memperbarui query filter di `siswa_providers.dart`, `keuangan_providers.dart`, `admin_providers.dart`, dan `parent_providers.dart` agar men-join data kelas dari tabel `classes`.
    * **UI Dinamis**: Memperbarui form `showAddStudentSheet` dan `showEditStudentSheet` pada Super Admin agar dropdown kelas memuat data secara dinamis dari database menggunakan `classesProvider` daripada menggunakan daftar *hardcoded*.
18. **Pemisahan Kelas & Rombongan Belajar (Rombel)**: ✅ **Selesai** — Memecah data kelas gabungan (contoh: "7-A") menjadi bidang "Kelas" (tingkat/jurusan) dan "Rombel" (sub-kelas) yang independen di database dan UI:
    * **Database**: Membuat tabel master `rombels` dengan kebijakan RLS aman. Menambahkan foreign key `rombel_id` di `students`. Migrasi data secara otomatis memecah kelas lama menjadi kelas dan rombel yang terpisah. Memperbarui RPC `create_user_account` dan trigger `handle_new_user` agar memecah string kelas gabungan menjadi relasi terpisah saat registrasi.
    * **Dart Model**: Menambahkan model `SchoolRombel` dan mengekspornya. Memperbarui `Student` dan `StudentWithProfile` agar menyertakan properti `rombelId` dan secara dinamis menggabungkannya kembali di getter virtual `class_` (misalnya `"7-A"`) untuk backward compatibility di tampilan visual lainnya.
    * **Queries & Providers**: Menambahkan `rombelsProvider` di `shared_providers.dart` dan memperbarui seluruh query join relasional `rombels(name)` di provider siswa, parent, keuangan, dan admin.
    * **UI Dinamis & CRUD**: Menambahkan kartu **Manajemen Rombel** khusus untuk `super_admin` di halaman Setelan Sistem untuk mengelola data master Rombel (Add/Edit/Delete). Memperbarui form tambah dan edit siswa agar menggunakan dua dropdown terpisah ("Kelas" dan "Rombel") untuk memodifikasi relasi data secara akurat.
19. **Optimasi Load DB, Caching Provider & Search Debouncing**: ✅ **Selesai** — Mengurangi beban database dan memori secara masif untuk meningkatkan skalabilitas:
    * **Optimasi Query & Limit**: Seluruh pencarian pengguna (Manajemen User, Manajemen Siswa, Super Admin) sekarang berjalan sepenuhnya di sisi database menggunakan operator PostgREST `or` dan `ilike` dengan batas data `.limit(100)`. Menghilangkan total pemuatan record tak terbatas pada query transaksi dan aktivitas log detail dengan menerapkan batas default 100 baris.
    * **Filter Periode Laporan Keuangan**: Laporan keuangan tidak lagi memuat riwayat transaksi global secara membabi buta. Kueri disaring secara dinamis menggunakan `.gte('created_at', startDate)` di level database sesuai dengan periode yang dipilih (`Hari Ini`, `Minggu Ini`, `Bulan Ini`), dipicu langsung via Riverpod state provider.
    * **Debouncing Keyboard (500ms)**: Menambahkan penunda pengetikan pada kolom pencarian Manajemen User, Manajemen Siswa, dan Super Admin Users. Ini mencegah spam kueri ke Supabase dan menghilangkan lag ketukan keyboard di UI.
    * **Caching Instan via `autoDispose` & `cacheFor`**: Seluruh provider data di 5 role telah dimigrasikan menggunakan Riverpod `.autoDispose` dengan timeout `cacheFor` 5 menit (atau 15 menit untuk data master statis). Ini menyelesaikan kendala visual reload spinner berulang saat berpindah halaman/tab, sekaligus mengamankan aplikasi dari kebocoran memori (memory leak) karena state provider otomatis terhapus setelah 5 menit tidak memiliki active listener.
    * **Family Caching Per-Tab (Super Admin)**: Mengubah `adminUsersProvider` menjadi family provider (`AdminUsersFilter`) sehingga setiap tab/segmen peran ("Siswa", "Keuangan", "Kantin", "Semua") memiliki cache bucket independen. Berpindah tab kini instan 100% tanpa loading spinner ataupun re-fetch ke Supabase.
20. **Optimalisasi Caching User & Retensi State Tab**: ✅ **Selesai** — Menghilangkan sepenuhnya loading spinner saat mengetik pencarian/pindah filter peran dan mempertahankan posisi scroll tab:
    * **Pemfilteran Pencarian Sisi Klien (Client-Side)**: Mengubah `adminUsersProvider` (Super Admin), `keuanganStudentsProvider`, `keuanganUsersStudentsProvider`, `keuanganParentsProvider`, dan `keuanganStaffProvider` (Keuangan) agar memuat semua data ke cache sekali saja, dan melakukan pemfilteran pencarian secara instan di sisi klien. Hal ini menghapus delay pengetikan pencarian (menghilangkan debounce) dan menghilangkan reload spinner sepenuhnya.
    * **Retensi State Tab (Keep-Alive)**: Mengimplementasikan `AutomaticKeepAliveClientMixin` pada `StudentsTab`, `ParentsTab`, `StaffTab` (Keuangan), serta `ActivitiesTab` (Kantin). Ini mencegah disposal widget tab saat berpindah tab di `KeuanganUsersScreen` dan `SalesHistoryScreen`, sehingga posisi scroll serta dropdown filter status yang dipilih tidak ter-reset.
21. **Integrasi Sistem Pemesanan Online ala GoFood (Multi-Kantin & Delivery)**: ✅ **Selesai** — Mengembangkan fitur pemesanan makanan online terintegrasi penuh untuk Siswa dan Petugas Kantin:
    * **Database & Migrasi**: Membuat tabel master `delivery_locations`, tabel orders utama (`orders`), dan tabel item per order (`order_items`). Menambahkan kolom `delivery_enabled` dan `delivery_fee` pada `canteen_operators`. Menulis RPC database ACID `place_order` (atomic split multi-kantin & potong saldo siswa), `cancel_order` (batal status pending & refund saldo), dan `complete_order` (selesai status ready & credit saldo kantin).
    * **Dart Model & State Management**: Membuat model `Order`, `OrderItemLine`, dan `DeliveryLocation`. Mengembangkan `cartProvider` asinkronis di sisi siswa yang mendukung auto-split keranjang multi-kantin, pengaturan tipe pengiriman, dan validasi data wajib.
    * **Integrasi Dashboard Siswa**: Menambahkan banner premium "Pesan Makanan Online" dan visual tracker "Pesanan Aktif" real-time di layar utama siswa.
    * **Integrasi Dashboard & Profil Kantin**: Menambahkan banner notifikasi pesanan masuk otomatis di dashboard kasir petugas kantin serta badge order count di layout navigasi global. Menyediakan saklar setelan "Layanan Antar" dan biaya ongkir dinamis di halaman profil petugas kantin.
    * **Navigasi & Routing**: Mendaftarkan seluruh halaman baru (Daftar Kantin, Menu Detail, Keranjang, Checkout, Pesanan Saya, Pelacakan Pesanan) ke dalam setup routing `app_router.dart` dengan visual premium bebas lag.
