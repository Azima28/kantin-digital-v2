# Progress Lembar Kerja Tugas: Kantin Digital

Dokumen ini memantau status penyelesaian setiap fitur pada proyek **Kantin Digital** (multi-platform: Siswa, Kantin/POS, Keuangan, Orang Tua, Super Admin) agar agen berikutnya tahu status persis pengerjaan.

**Terakhir diperbarui**: 24 Juni 2026

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
*   [x] **Redesain Visual Standar Aplikasi & Web per Role**: Mengubah seluruh tampilan dan design system per role dari gaya sci-fi/AI neon template menjadi standar aplikasi mobile & web modern (Material 3 & Apple HIG). Role Siswa menggunakan Emerald Teal, Kasir Kantin menggunakan Warm Amber, Orang Tua menggunakan Financial Indigo, Keuangan menggunakan Enterprise Slate Blue, Guru menggunakan Deep Violet, dan Admin menggunakan Executive Slate. Halaman web `login.html` juga diredesain menjadi sheet konfirmasi RFID bergaya web standar.

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
*   [x] **Dashboard** — saldo, ringkasan, quick actions (bagian pesanan aktif telah dihapus dari beranda), carousel promo makanan kantin mingguan dinamis dengan **auto-scroll loop tak terbatas (infinite scrolling)** yang responsif menyesuaikan ukuran viewport HP/Tablet/Desktop, serta perbaikan responsivitas bagian "Jajan Hari Ini" (lebar penuh untuk kotak kosong dan tampilan grid 2 kolom di tablet/desktop).
*   [x] **Top Up** — halaman isi saldo (tata letak diperbaiki agar grid nominal cepat responsif dan tidak mengalami bottom overflow).
*   [x] **Riwayat Jajan** — riwayat transaksi siswa (tata letak diperbaiki agar rapi saat nominal saldo sangat besar, tampilan kartu diselaraskan dengan visual kartu pesanan, dan tab filter menggunakan sliding segmented control dengan badge hitungan).
*   [x] **Kartu RFID** — manajemen kartu RFID/NFC.
*   [x] **Profil** — detail profil siswa.
*   [x] **Notifikasi** — pusat notifikasi.
*   [x] **Main Layout** — bottom navigation (Beranda, Riwayat, Kartu, Akun).

### [x] Phase 5: Modul Kantin/POS (Mobile App)
*   [x] **POS Home** — dashboard kasir (termasuk filter harian otomatis pada tab selesai & batal di daftar pesanan).
*   [x] **POS Terminal/Dashboard** — terminal transaksi.
*   [x] **Cart** — keranjang belanja.
*   [x] **Check Card** — scan & cek kartu siswa.
*   [x] **Manage Products** — kelola menu/jajanan.
*   [x] **Product Form** — form tambah/edit produk dengan input kelola kustomisasi topping/opsi menu berbayar maupun gratis untuk murid.
*   [x] **Sales History** — riwayat penjualan & refund (dikelompokkan berdasarkan hari, tanggal, nama bulan, dan tahun).
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
*   [x] **Dashboard** — monitoring saldo & aktivitas anak (tata letak navigasi diperbaiki agar responsif menggunakan Sidebar di layar PC/desktop dan tetap menggunakan Bottom Navigation Bar di layar HP/mobile, serta mendukung Mode Gelap secara penuh).
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
    *   `RfidCard` — tabel `rfid_cards` (dengan `isActive`, `isAssigned`)
    *   `TransactionType` — tabel `transaction_types`
    *   `Transaction` — tabel `transactions` (dengan nested `transactionType`, `student`)
    *   `BalanceAdjustment` — tabel `balance_adjustments` (dengan `isAdd`, `isSubtract`)
    *   `models.dart` — barrel export untuk import tunggal
*   [x] **Core Providers** (`lib/core/providers/app_providers.dart`) — ditulis ulang:
    *   `AppStateNotifier` (StateNotifier) — network monitoring, maintenance mode, sync status
    *   `networkStatusProvider` — StreamProvider dari connectivity_plus
    *   `isOnlineProvider` — derived boolean provider
    *   `globalRefreshKeyProvider` — trigger refresh global
    *   `CacheDuration` — konfigurasi cache per jenis data
# Progress Lembar Kerja Tugas: Kantin Digital

Dokumen ini memantau status penyelesaian setiap fitur pada proyek **Kantin Digital** (multi-platform: Siswa, Kantin/POS, Keuangan, Orang Tua, Super Admin) agar agen berikutnya tahu status persis pengerjaan.

**Terakhir diperbarui**: 25 Juni 2026

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
| **Phase 9**: Code Architecture (Models & Providers) | 🔄 Sedang Berjalan |
| **Phase 10**: Security Hardening & Production Readiness | ⏳ Belum Mulai |

**Progres Keseluruhan**: ~86%

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
*   [x] **Dashboard** — saldo, ringkasan, quick actions (bagian pesanan aktif telah dihapus dari beranda), dan carousel promo makanan kantin mingguan dinamis (dengan auto-scroll/sliding otomatis).
*   [x] **Top Up** — halaman isi saldo.
*   [x] **Riwayat Jajan** — riwayat transaksi siswa (tata letak diperbaiki agar rapi saat nominal saldo sangat besar, tampilan kartu diselaraskan dengan visual kartu pesanan, dan tab filter menggunakan sliding segmented control dengan badge hitungan).
*   [x] **Kartu RFID** — manajemen kartu RFID/NFC.
*   [x] **Profil** — detail profil siswa.
*   [x] **Notifikasi** — pusat notifikasi.
*   [x] **Main Layout** — bottom navigation (Beranda, Riwayat, Kartu, Akun).

### [x] Phase 5: Modul Kantin/POS (Mobile App)
*   [x] **POS Home** — dashboard kasir (termasuk grafik volume penjualan harian & grafik donat distribusi makanan terlaris dengan filter tanggal interaktif).
*   [x] **POS Terminal/Dashboard** — terminal transaksi.
*   [x] **Cart** — keranjang belanja.
*   [x] **Check Card** — scan & cek kartu siswa.
*   [x] **Manage Products** — kelola menu/jajanan.
*   [x] **Product Form** — form tambah/edit produk dengan input kelola kustomisasi topping/opsi menu berbayar maupun gratis untuk murid.
*   [x] **Sales History** — riwayat penjualan & refund (dikelompokkan berdasarkan hari, tanggal, nama bulan, dan tahun).
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
*   [x] **Perbaikan Bug Kategori Orang Tua & Riwayat Transaksi**:
    * Mengoreksi nama constraint join PostgREST (`parent_students!parent_students_parent_id_fkey`) di `keuanganParentsProvider` agar pemuatan daftar Orang Tua terbebas dari crash database.
    * Melepas filter `actor_id` dari `keuanganHistoryProvider` agar seluruh transaksi top-up siswa (tunai maupun mandiri/simulasi) dan koreksi saldo tampil di menu transaksi Admin Keuangan secara real-time.
    * Memetakan tipe aksi `'TOPUP'` pada filter, statistik ringkasan, dan ikon di `KeuanganHistoryScreen`.
    * Menyajikan kolom Pelaku (Actor) di bottom sheet detail riwayat aktivitas keuangan.

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
17. **Efek Bouncing & Border pada Tab Status Pesanan Kantin**: ✅ **Selesai** — Menambahkan efek bouncing pada tab filter status pesanan (Baru, Proses, Selesai, Batal) di menu pesanan petugas kantin dengan menerapkan `BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())` pada `SingleChildScrollView`. Selain itu, membungkus widget `OrderStatusTabs` dalam `Container` dengan border dan background `cardBackground` agar terlihat seperti track tab terpadu dan mengurangi celah/ruang kosong yang tidak proporsional.
18. **Penyegaran Visual & Micro-Interaction Menu Pesanan Petugas Kantin**: ✅ **Selesai** — Meningkatkan tampilan halaman Daftar Pesanan role Petugas Kantin menjadi berkelas premium:
    * **Sliding Capsule Tab**: Mengubah `OrderStatusTabs` menjadi iOS/Gojek-style sliding pill bar (`canteenPrimary` background bergeser halus dengan durasi 280ms) lengkap dengan scale text dan badge pesanan baru biru melingkar.
    * **ViewPager Transitions**: Menggunakan `PageView` horizontal yang terikat dengan controller untuk navigasi halaman layaknya tab Android native.
    * Menyajikan kolom Pelaku (Actor) di bottom sheet detail riwayat aktivitas keuangan.

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

### [x] Phase 9: Code Architecture (Type Safety & Clean Architecture)

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
17. **Efek Bouncing & Border pada Tab Status Pesanan Kantin**: ✅ **Selesai** — Menambahkan efek bouncing pada tab filter status pesanan (Baru, Proses, Selesai, Batal) di menu pesanan petugas kantin dengan menerapkan `BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())` pada `SingleChildScrollView`. Selain itu, membungkus widget `OrderStatusTabs` dalam `Container` dengan border dan background `cardBackground` agar terlihat seperti track tab terpadu dan mengurangi celah/ruang kosong yang tidak proporsional.
18. **Penyegaran Visual & Micro-Interaction Menu Pesanan Petugas Kantin**: ✅ **Selesai** — Meningkatkan tampilan halaman Daftar Pesanan role Petugas Kantin menjadi berkelas premium:
    * **Sliding Capsule Tab**: Mengubah `OrderStatusTabs` menjadi iOS/Gojek-style sliding pill bar (`canteenPrimary` background bergeser halus dengan durasi 280ms) lengkap dengan scale text dan badge pesanan baru biru melingkar.
    * **ViewPager Transitions**: Menggunakan `PageView` horizontal yang terikat dengan controller untuk navigasi halaman layaknya tab Android native.
    * **Skeleton Shimmer Loading**: Membuat widget shimmer loader mandiri `Shimmer` & `SkeletonCard` untuk placeholder pemuatan data.
    * **Staggered Entrance & Exit Anim**: Menambahkan staggered animation (`60ms * index` delay) untuk cascade-in efek kartu pesanan, elastic bounce click micro-interaction pada tap, serta animasi exit fade-out saat merubah status pesanan agar kartu keluar secara halus sebelum berpindah ke tab berikutnya.
19. **Animasi Storytelling Transaksi Sukses & Navigasi Tab Proses Siswa**: ✅ **Selesai** — Mengubah total alur sukses pembayaran murid dari popup biasa menjadi perjalanan storytelling sinematik:
    * **Step 1-3 (Lifting & Float)**: Tombol bayar spring scale-down (96% -> 100%) bertuliskan "Memproses Pembayaran...". Card transaksi terangkat (scale 105%, glow, shadow membesar) lalu mengecil (70%), rotasi 4 derajat, dan mengambang di atas background blur.
    * **Step 4-5 (Curved Bezier Flight)**: Ikon dapur 🍳 muncul di atas layar, kemudian card meluncur ke arah dapur mengikuti lintasan melengkung (Bezier Curve), berputar cepat, mengecil, dengan motion blur aslinya dan light trail (koordinat trail melingkar pudar) di belakangnya.
    * **Step 6-7 (Received & Page Transition)**: Ikon dapur memantul (elastic bounce), cincin gelombang (expanding ripples) keluar, memunculkan badge hijau "✔ Pesanan Diterima" disertai kilau bintang (sparkles), dilanjutkan dengan transisi geser kiri + fade untuk menutup overlay.
    * **Step 8-10 (Active Orders List Integration)**: Mengubah BottomNavigationBar layout utama siswa menjadi custom bar interaktif dengan sliding indicator line di bagian atas dan tab-item berskala. Di dalam halaman Pesanan Siswa, pesanan baru meluncur turun (translateY -40px -> 0px) dengan efek bounce ketika mendarat, memiliki glow outline hijau lembut selama 1.5 detik, dan status "🟡 Sedang Diproses" ter-scale ke dalam.
20. **Animasi Lottie Pembayaran Berhasil (Siswa)**: ✅ **Selesai** — Membuat file animasi Lottie JSON (`assets/images/pembayaran_berhasil.json`) sebesar 51.63 KB (di bawah target 60 KB) yang mendetailkan visual ceria 5-tahap: kemunculan avatar siswa peci/cap netral-gender, kartu meluncur naik dan memantul, sapuan cahaya keemasan & partikel mini sekolah, transformasi kartu menjadi lingkaran centang hijau dengan topi wisuda melayang mendarat di atas centang, ledakan 20 partikel ceria berbasis persamaan fisika (gravitasi dan pantulan tanah), serta pesan penutup personal.
21. **Perbaikan Bug Kategori Orang Tua & Transaksi Top-Up Admin Keuangan**: ✅ **Selesai** — Mengatasi masalah pemuatan data pada kategori Orang Tua di Menu Pengguna dengan mengoreksi nama constraint join PostgREST, serta membenahi alur data riwayat transaksi:
    * Menghapus filter `actor_id` di `keuanganHistoryProvider` agar admin dapat memonitor semua aksi finansial (termasuk top-up mandiri siswa/orang tua).
    * Mendeteksi tipe aksi `'TOPUP'` selain `'TOPUP_TUNAI'` pada filter, statistik harian, dan ikon riwayat transaksi.
    * Menampilkan data Pelaku (Actor Name) di detail log riwayat transaksi.
    * Mengintegrasikan invalidasi otomatis `ref.invalidate(keuanganHistoryProvider)` di seluruh form keuangan (Top-up, Koreksi, Link/Unlink kartu, dan Registrasi User) agar tabel riwayat selalu ter-update secara real-time.
22. **Penyelarasan & Redesain Dialog Ubah Sandi Semua Role**: ✅ **Selesai**
    * **Redesain Dialog**: Merancang ulang dialog Ubah Sandi Siswa dengan visual premium (ikon gembok shield bersinar, layout ringkas, placeholder/hint bertitik `••••••••` meniru referensi mock-up, dan tombol Batal/Simpan berbayang).
    * **Widget Reusable**: Membuat widget `ChangePasswordPanel` terpadu di `lib/core/widgets/change_password_panel.dart` yang dapat digunakan oleh semua role.
    * **Integrasi Keamanan Supabase RPC**: Memperbarui proses verifikasi password lama agar berjalan melalui RPC `verify_password` (lebih aman karena bcrypt diproses di server database) dan proses update password melalui RPC `update_auth_user_password`. Hal ini mengamankan password dari penyimpanan plaintext dan menyelaraskannya dengan enkripsi Supabase Auth.
    * **Penyebaran**: Mengganti dialog password bawaan (CupertinoAlertDialog lama) pada role **Siswa**, **Petugas Kantin/Kasir**, **Admin Keuangan**, dan **Super Admin** agar semuanya menggunakan dialog premium `ChangePasswordPanel` baru secara seragam.
23. **Penyelarasan Mode Terang & Gelap Seluruh Halaman Semua Role**: ✅ **Selesai**
    * **Audit & Eliminasi Campuran Warna Dark Mode**: Melakukan peninjauan menyeluruh terhadap skema warna pada seluruh halaman dan widget di semua role (Siswa, Petugas Kantin, Orang Tua, Admin Keuangan, dan Super Admin).
    * **Implementasi Tema Dinamis Secara Penuh**: Mengganti semua warna latar belakang statis (`Colors.white`, dll.) dan referensi teks keras dengan properti tema dinamis (`context.cardBg`, `context.surfaceBg`, `context.textPrimary`, `context.textSecondary`, `context.dividerCol`, dll.). Hal ini memastikan bahwa ketika aplikasi diatur ke mode terang, seluruh UI benar-benar bersih dan terang tanpa adanya elemen bayangan gelap atau kontras teks yang tertukar.
    * **Refaktor NebulaCard**: Mengubah `NebulaCard` di `lib/core/widgets/nebula_components.dart` agar menggunakan warna latar belakang dinamis (`context.cardBg`) dan warna border dinamis (`context.dividerCol`) alih-alih nilai statis dark mode (`Cosmic.surface`). Perubahan ini secara instan memperbaiki tampilan seluruh kartu pendapatan, riwayat jajan, dashboard POS kantin, serta panel detail di semua modul peran agar adaptif sempurna terhadap Mode Terang.
    * **Perbaikan Kompilasi & Parameter Helper**: Memperbaiki tanda tangan method helper (`_sectionHeader`, `_sectionLabel`, `_buildFormField`, `_buildDropdownRow`, `_buildStatCard`, dll.) pada panel dan bottom sheet manajemen pengguna di role Keuangan dan Admin agar secara eksplisit menerima `BuildContext context` sehingga dapat mengakses ekstensi tema dinamis secara aman.
24. **Penambahan Toggle Dark Mode pada Role Admin Keuangan**: ✅ **Selesai**
    * **Integrasi ThemeToggleTile**: Mengimpor dan mengintegrasikan komponen `ThemeToggleTile` pada layar `KeuanganSettingsScreen` ("Akun Saya"). Ini memberikan Admin Keuangan kendali penuh untuk mengaktifkan/nonaktifkan Dark Mode langsung dari panel profil mereka, selaras dengan fungsionalitas di peran-peran lain.
25. **Perbaikan Background Aktivitas Terbaru Admin Keuangan**: ✅ **Selesai**
    * **Penyelarasan Warna Latar Belakang**: Mengganti properti `color: Colors.white` keras dengan properti dinamis `color: context.cardBg` pada widget container riwayat aktivitas terbaru di `KeuanganDashboardScreen`. Ini secara sempurna meluruskan keterbacaan teks deskripsi log aktivitas dalam Mode Gelap.
26. **Penyampaian Harga Toping / Kustomisasi untuk Role Siswa**: ✅ **Selesai**
    * **Pemisahan & Penampilan Harga Toping**: Memperbarui modal kustomisasi jajanan (`_showCustomizationSheet` di `lib/features/public/screens/public_menu_screen.dart`) dengan helper `parseOptionDetails` agar memisahkan nama toping dari harga tambahan secara bersih.
    * **Visual Tag Harga**: Menampilkan tag harga toping secara jelas (`+Rp X.XXX` dengan font tebal dan warna teal `Nebula.teal`, atau `Gratis` jika tanpa biaya) pada bagian Tingkat Kepedasan, Pilihan Topping, dan Lalapan & Sayuran agar siswa mengetahui pasti rincian harga toping saat melakukan kustomisasi menu.
27. **Redesain Tombol Melayang Keranjang Belanja (Floating Cart Bar)**: ✅ **Selesai**
    * **Bar Melayang GoFood/GrabFood-style**: Mengubah tombol keranjang melayang di `lib/features/public/screens/public_menu_screen.dart` dari lingkaran abu-abu kecil menjadi Floating Cart Bar meluncur horizontal yang menonjol dan menarik.
    * **Informasi Lengkap & Jelas**: Menampilkan chip jumlah item (contoh: `1 Item`), total harga rupiah terformat (contoh: `Rp 12.000`), dan tombol aksi `Lihat Keranjang` lengkap dengan ikon panah chevron dan efek animasi tekan (`PressScale`).
28. **Fitur Foto Toping pada Form Petugas Kantin & Modal Siswa**: ✅ **Selesai**
    * **Upload & Edit Foto Toping Petugas Kantin**: Menambahkan dialog khusus unggah foto minimalis (`_showPhotoOnlyUploadDialog`) untuk tombol `+ Tambahkan Toping dengan Foto` yang hanya menampilkan area unggah (*Cloud Upload Box*) serta tombol **Batal** & **Tambah** (persis sesuai desain). Sementara tombol pensil edit (`✏️`) membuka modal lengkap untuk mengubah nama, harga, dan foto toping.
    * **Visualisasi Foto Toping Role Siswa**: Memperbarui parser kustomisasi (`parseOptionDetails`) di `lib/features/public/screens/public_menu_screen.dart` agar menampilkan thumbnail foto toping (`CachedNetworkImage`) pada modal kustomisasi siswa ketika foto toping tersedia.


29. **Redesain Floating Cart Bar Menu POS Petugas Kantin**: ✅ **Selesai**
    * **Desain Modern GoFood/GrabFood Style**: Mengubah tampilan keranjang belanja melayang di `lib/features/kantin/screens/pos_dashboard_screen.dart` menjadi bar horizontal berwarna teal (`Nebula.teal`) dengan animasi mikro tekan (`PressScale`).
    * **Elemen Visual Presisi**: Dilengkapi chip jumlah item dengan ikon tas belanja (`CupertinoIcons.bag_fill` + `X Item`), harga total terformat tebal (`CurrencyFormatter.format`), serta label aksi `Lihat Keranjang` dan ikon panah chevron (`>`).
30. **Pengelompokan 3 Kategori Toping pada Form Petugas Kantin**: ✅ **Selesai**
    * **Pembagian 3 Seksi Terstruktur**: Mengelompokkan tampilan daftar kustomisasi/toping yang ditambahkan petugas kantin di `lib/features/kantin/screens/product_form_screen.dart` ke dalam 3 bagian terpisah: **1. Tingkat Kepedasan**, **2. Pilihan Topping**, dan **3. Lalapan & Sayuran**.
    * **Presisi Visual**: Setiap seksi dilengkapi dengan judul tebal, badge indikator jumlah item (`X item`), ikon kategori (🌶️, 🍳, 🥒), harga terformat (`+Rp X.XXX` / `Gratis`), serta tombol aksi edit (`✏️`) dan hapus (`🗑️`).
32. **Redesain Halaman Login (LoginScreen) & Adaptif Light/Dark Mode**: ✅ **Selesai**
    * **Perombakan Visual Presisi**: Merombak total `LoginScreen` di `lib/features/auth/screens/login_screen.dart` agar sesuai persis dengan sampel mock-up desain baru.
    * **Komponen & Visual**:
      - Tombol Navigasi `< Kembali` di sudut kiri atas.
      - Panel Kredensial Demo (`AKSES DEMO` + `• PREVIEW AKUN UJI COBA` di [login_account_preview.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/auth/widgets/login_account_preview.dart)) berisi 5 akun demo siap pakai.
      - Card Login Utama berisi logo `KANTIN DIGITAL` (`Akses layanan sekolah`), tagline bullet `• AREA AMAN`, Judul hero `Selamat datang kembali.`, input Username & Sandi, tombol primary `MASUK >`, tombol sekunder `Masuk sebagai Orang Tua`, link bantuan koperasi, dan catatan keamanan footer `🔒 Data Anda tersimpan dengan aman`.
    * **Dukungan Responsif & Adaptif Multi-Perangkat**:
      - Desktop (`> 900px`): Panel Akses Demo berdampingan di sebelah kiri form login utama.
      - Mobile & Tablet (`< 900px`): Card login utama centered dengan toggle fleksibel untuk membuka/menutup panel Akses Demo.
      - Adaptif penuh untuk Light Mode & Dark Mode.
33. **Audit & Optimalisasi Responsif Seluruh Layar (System-wide Responsiveness)**: ✅ **Selesai**
    * **Audit & Penyelarasan**: Memeriksa seluruh layar di modul Siswa, Kantin/POS, Keuangan, Orang Tua, dan Admin untuk memastikan tidak ada elemen terpotong atau meregang berlebihan pada layar Desktop/Tablet.
    * **Penyempurnaan Layar Kunci**:
      - `CheckCardScreen` ([check_card_screen.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/kantin/screens/check_card_screen.dart)): Mengubah tampilan Desktop/Tablet (`width >= 800px`) menjadi 2-kolom split (Sisi Kiri: Visual Pemindaian NFC & Detail Kartu Siswa; Sisi Kanan: Panel Simulator Cek Kartu).
      - `KeuanganTopupScreen` ([keuangan_topup_screen.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/keuangan/screens/keuangan_topup_screen.dart)): Menambahkan pembatas `ConstrainedBox(maxWidth: 800)` dan perataan tengah.
34. **Redesain Halaman Selamat Datang Presisi Sesuai Template selaamat_datang.html**: ✅ **Selesai**
    * **Penyelarasan Template Web**: Merombak total `StudentWelcomeScreen` di [student_welcome_screen.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/siswa/screens/student_welcome_screen.dart) agar persis mengikuti struktur layout Bento Grid dari `selaamat_datang.html`.
    * **Komponen & Visual**:
      - Header Pill Badge `Kantin Digital` berlatar soft teal (`.brand-badge`).
      - Judul Hero `Jajan jadi sederhana.` dengan penekanan kata `sederhana.` menggunakan warna aksen utama teal (`.title span`).
      - Paragraf deskripsi: *"Pesan, bayar, dan ambil makanan tanpa antre panjang. Semua kebutuhan istirahatmu dalam satu aplikasi."*
      - Tombol Utama `Masuk Kantin →` berbentuk rounded pill (`.btn-primary`).
      - Panel Hero Bento (`.bento-hero`) berisi header *Sorotan Hari Ini (08.00 — 14.00)*, **Banner Iklan Spotlight Produk Dagangan Petugas Kantin** (menggunakan PageView carousel otomatis dengan gambar produk, nama stan kantin, kategori, badge `🔥 SOROTAN`, serta harga & tombol `Pesan`), dan status pill pulsing green indicator *• Kantin siap melayani*.
      - 3 Card Bento Fitur (`.features-grid`): **Tanpa Antre** (Pesan dari kelas), **Cashless** (Bayar praktis), dan **Tepat Waktu** (Notifikasi saat makanan matang).
    * **Skema Warna Aplikasi**: Menggunakan palet warna terpusat aplikasi Kantin Digital (Teal `#0D9488`/`#065F56` pada Light Mode dan Mint `#2DD4BF`/`#14B8A6` pada Dark Mode).
35. **Penyederhanaan CTA Selamat Datang**: ✅ **Selesai**
    * Menghapus tombol sekunder `Lihat Menu` dan modal preview terkait dari [student_welcome_screen.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/siswa/screens/student_welcome_screen.dart) sesuai permintaan user.
36. **Pembaruan Skema Warna Mode Gelap ke Abu-Abu Gelap (Pure Dark Grey Dark Mode)**: ✅ **Selesai**
    * **Penyelarasan Sistem Desain Terpusat**: Mengubah skema warna mode gelap di [nebula_colors.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/core/theme/nebula_colors.dart), [app_colors.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/core/constants/app_colors.dart), [app_theme.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/core/theme/app_theme.dart), dan [theme_extensions.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/core/extensions/theme_extensions.dart) menggunakan nuansa abu-abu gelap netral sesuai spesifikasi pengguna (`#1A1A1A`, `#202020`, `#242424`, `#262626`, `#2E2E2E`, `#343434`).
    * **Komponen & Visual Seluruh Role**: Memperbarui [premium_background.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/core/widgets/premium_background.dart), [premium_bottom_nav_bar.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/core/widgets/premium_bottom_nav_bar.dart), serta warna hardcoded di [login_screen.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/auth/screens/login_screen.dart), [student_welcome_screen.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/siswa/screens/student_welcome_screen.dart), dialog profil, dan form produk agar seragam 100% menggunakan warna abu-abu gelap `#1A1A1A`.
37. **Sistem Escrow Penahanan Saldo & Transaksi Kantin**: ✅ **Selesai**
    * **Penahanan Saldo saat Pemesanan (Checkout Cart)**: Mengupdate [siswa_cart_screen.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/siswa/screens/siswa_cart_screen.dart) dan RPC [20260729100000_escrow_payment_system.sql](file:///d:/mantap%20sih/kantin-digital-v2/supabase/migrations/20260729100000_escrow_payment_system.sql) sehingga saldo siswa langsung terpotong saat membuat pesanan dan dana **ditahan sementara oleh sistem (Escrow)** tanpa langsung masuk ke pendapatan kantin.
    * **Pencairan Dana saat Selesai (`'Selesai'`)**: Mengupdate [order_list_screen.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/kantin/screens/order_list_screen.dart) dan RPC `complete_order_release_escrow` sehingga saat makanan diserahkan dan status menjadi `Selesai`, dana escrow baru diteruskan ke akun kantin (`canteen_operators.balance_earned`).
    * **Pengembalian Saldo saat Dibatalkan (`'Dibatalkan'`)**: Mengupdate [cancel_order_modal.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/core/widgets/cancel_order_modal.dart) dan RPC `cancel_order` sehingga jika pesanan dibatalkan (oleh siswa atau kantin), saldo siswa **dikembalikan 100%** (`students.balance = balance + total_amount`) dan status transaksi diperbarui menjadi `cancelled`.
38. **Penyelarasan Warna Panel Akun Demo**: ✅ **Selesai**
    * Mengubah latar belakang komponen [login_account_preview.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/auth/widgets/login_account_preview.dart) dan [login_preview_item.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/auth/widgets/login_preview_item.dart) dari biru gelap ke abu-abu gelap netral (`0xA6202020` & `0x992A2A2A`) agar selaras 100% dengan tema mode gelap `#1A1A1A` pada kartu utama halaman login.
39. **Konfirmasi Pembayaran Memasukkan PIN Kartu**: ✅ **Selesai**
    * Mengubah modal verifikasi pemesanan di [siswa_cart_screen.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/siswa/screens/siswa_cart_screen.dart) dari simulasi tap RFID/NFC menjadi input **PIN 6-Digit Kartu Siswa** (`StudentPinPaymentModal`).
    * Menyediakan input field PIN tersembunyi (`••••••`) dengan tombol toggle lihat/sembunyikan PIN, ikon gembok keamanan (`Icons.lock_outline_rounded`), tombol *"BAYAR"*, serta opsi simulasi PIN default (`123456`).
40. **Perombakan Total UI/UX Seluruh Aplikasi (Standard Industri Mobile)**: ✅ **Selesai**
    * **Audit & Redesain Visual**: Merombak total seluruh desain aplikasi agar memenuhi standar aplikasi mobile modern (level Gojek, Grab, Tokopedia, Shopee, Revolut, dan DANA) serta terbebas dari kesan AI/gimmick (seperti warna sci-fi void dan glow berlebihan).
    * **Komponen & Layout System**:
      - Sistem token warna slate bersih di [app_colors.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/core/constants/app_colors.dart), [app_theme.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/core/theme/app_theme.dart), dan [nebula_tokens.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/core/theme/nebula_tokens.dart).
      - Redesain indikator bottom navigation bar [premium_bottom_nav_bar.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/core/widgets/premium_bottom_nav_bar.dart) dengan badge dan penanda tab aktif yang jernih.
      - Redesain tampilan kosong [empty_state_widget.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/core/widgets/empty_state_widget.dart) dengan kontainer ikon melingkar yang modern dan tipografi yang proporsional.
      - Menjaga 100% fungsionalitas logika bisnis, RPC Supabase, dan aturan keamanan aplikasi.
42. **Redesain Modal Detail Aktivitas Keuangan & Penyempurnaan Teks Keterangan**: ✅ **Selesai**
    * **Tampilan Modal Dialog Terpusat**: Mengubah modal detail aktivitas keuangan pada [keuangan_history_screen.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/keuangan/screens/keuangan_history_screen.dart) dari bottom sheet menjadi dialog modal terpusat (`Dialog`) berlayar bersih dengan ikon dokumen hijau mint besar, baris Waktu/Keterangan/Pelaku berikon, kartu komparasi `SEBELUM` & `SESUDAH`, dan tombol pill `TUTUP` hijau tua di kanan bawah persis sesuai gambar referensi.
    * **Penyempurnaan Teks Keterangan**: Menghapus UUID teknis panjang dan memformat ulang teks keterangan agar lebih jelas mencantumkan nama siswa, nama stan/petugas kantin, serta nominal uang terformat (contoh: *"Pesanan oleh Ahmad Subarjo di Stan Bakso Enak dibatalkan. Saldo Rp 10.231 dikembalikan ke siswa."*).
43. **Redesain Dialog Export Laporan (Excel & PDF)**: ✅ **Selesai**
    * **Presisi Sesuai Gambar**: Mengubah dialog eksport laporan pada [keuangan_report_screen.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/keuangan/screens/keuangan_report_screen.dart) menjadi dialog terpusat dengan:
      - Header berikon dokumen pencarian biru/teal lembut + judul **Export Laporan**.
      - Kartu pilihan format berdampingan (**Excel (.xls)** dengan border & aksen atas hijau + label "Terpilih", dan **PDF** dengan border & aksen atas merah).
      - Sakelar `CupertinoSwitch` untuk opsi *"Rekap Riwayat Audit Log"* dan *"Detail Per-Siswa (Data Sensitif)"*.
      - Tombol teks *"Batal"* di tengah dan tombol utama *"Download File"* berupa tombol pill penuh bergaris membulat dengan ikon unduh.
44. **Filter 3 Dropdown (Tanggal, Bulan, Tahun) Laporan Keuangan**: ✅ **Selesai**
    * **Penyederhanaan Tampilan Filter**: Mengubah komponen filter pada [keuangan_report_screen.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/keuangan/screens/keuangan_report_screen.dart) menjadi **hanya 3 dropdown** yang disusun rapi berdampingan dalam 1 baris:
      - **Dropdown 1 (Tanggal)**: Pilihan *Semua* (rekap penuh 1 bulan) atau *Tgl 01* s/d *Tgl 31* (rekap harian spesifik).
      - **Dropdown 2 (Bulan)**: Pilihan *Januari* s/d *Desember*.
      - **Dropdown 3 (Tahun)**: Pilihan *2024* s/d *2030*.
      - **Pencegahan Hari Tidak Valid**: Pilihan tanggal pada dropdown secara otomatis membatasi hari maksimum sesuai bulan & tahun yang dipilih (contoh: Februari 28/29 hari, April 30 hari).
45. **Redesain Detail Aktivitas Keuangan Tipe Batal Pesanan**: ✅ **Selesai**
    * **Presisi 100% Sesuai Gambar Referensi**: Merombak modal dialog detail aktivitas keuangan untuk tipe `BATAL_PESANAN` di [keuangan_history_screen.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/keuangan/screens/keuangan_history_screen.dart) dengan:
      - Badge header melingkar merah lembut berikon `xmark_circle_fill` merah + tag `TIPE AKSI:` ` BATAL PESANAN ` dalam pill merah muda lembut.
      - Susunan baris informasi vertikal (*Waktu*, *Keterangan*, *Pelaku (Actor)*) lengkap dengan label terpisah dan teks tebal terformat.
      - Kartu `SEBELUM` (Latar slate/abu-abu lembut + `Status: Dipesan`) & Kartu `SESUDAH` (Latar merah muda lembut + border merah + header `SESUDAH` merah + `Status: Dibatalkan` merah) yang dipisahkan ikon panah melingkar `( -> )` di tengah.
      - Tombol utama **TUTUP** selebar kontainer (*full width*) berbentuk pill membulat di bagian paling bawah.
46. **Kustomisasi Logo Top Up pada Detail & Riwayat Keuangan**: ✅ **Selesai**
    * **Penerapan Gambar Logo Kustom + Fallback**: Menambahkan aset gambar dompet *Top Up* teal ([ic_topup_wallet.png](file:///d:/mantap%20sih/kantin-digital-v2/assets/icons/ic_topup_wallet.png)) dengan `errorBuilder` fallback ikon dompet bawaan Flutter pada:
      - Header modal `_showDetailDialog` untuk seluruh aktivitas keuangan bertipe *Top Up* (`TOPUP_SALDO`, `TOPUP_TUNAI`, `TOPUP`).
      - Ikon kontainer melingkar pada setiap item riwayat transaksi *Top Up* di daftar [keuangan_history_screen.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/keuangan/screens/keuangan_history_screen.dart).
      - Menambahkan `errorBuilder` otomatis agar saat aplikasi dijalankan via Hot Reload/pemuatan aset baru belum di-restart, ikon dompet bawaan yang rapi dan elegan tetap tampil tanpa pernah memicu kotak silang merah (broken image placeholder).
47. **Single Filter Button & Modal Dialog Filter Periode**: ✅ **Selesai**
    * **Presisi 100% Sesuai Gambar Referensi**: Mengganti tampilan 3-dropdown pada [keuangan_report_screen.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/keuangan/screens/keuangan_report_screen.dart) menjadi **1 Tombol Filter** yang dapat diklik untuk membuka modal dialog **Filter Periode**:
      - Header: Judul **Filter Periode** + tombol silang `X` di sudut kanan atas.
      - Section **PILIHAN CEPAT**: Chip pill pilihan cepat (*Hari Ini*, *Minggu Ini*, *Bulan Ini*) berlatar teal saat terpilih.
      - Section **RENTANG WAKTU**: Dua kotak pemilih tanggal berdampingan (*Dari* & *Sampai*) berikon kalender.
      - Section **PILIH BULAN 🔒**: Pemilih tahun (*< 2026 >*) yang **bisa diketik langsung** (Typable 4-digit input field) maupun diklik via tombol panah (`<` / `>`), serta grid 12 tombol bulan (*Jan* s/d *Des*) berlatar abu-abu lembut.
      - **Eliminasi Popup Material DatePicker**: Menghapus `showDatePicker` bawaan Flutter yang memunculkan dialog `August 2026` di atas modal, dan menggantinya dengan dialog pemilih tanggal custom yang bersih dan serasi dengan tema aplikasi.
      - Footer: Tombol **Batal** (Outline) dan **Terapkan** (Teal Pill).
48. **Pembaruan Logo & Warna Batal Pesanan pada Riwayat Transaksi**: ✅ **Selesai**
    * **Integrasi Ikon & Tema Warna Merah Batal Pesanan**: Mengubah logo ikon dan skema warna untuk seluruh item aktivitas `BATAL_PESANAN` di [keuangan_history_screen.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/keuangan/screens/keuangan_history_screen.dart), [audit_log_tile.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/admin/widgets/audit_log_tile.dart), dan [officer_activities_screen.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/shared/screens/officer_activities_screen.dart):
      - Ikon lingkaran silang merah (`xmark_circle_fill`) dengan latar lingkaran merah muda lembut.
      - Teks judul `BATAL PESANAN` berwarna merah menyala (`Nebula.rose` / `0xFFDC2626`) agar konsisten dengan tema merah pada modal detail pembatalan pesanan.
49. **Pembaruan & Penyempurnaan Format File Ekspor Excel**: ✅ **Selesai**
    * **Penataan Layout & Formatting Profesional**: Merombak total `downloadExcelReport` pada [report_export_service.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/core/services/report_export_service.dart):
      - **Penataan Perataan Sel (Alignment)**: Angka nominal/uang dirata-kanan (Right-aligned), nomor & status dirata-tengah (Center-aligned), dan teks deskripsi dirata-kiri (Left-aligned).
      - **Penyusun Baris Total Summary**: Menambahkan baris **Total Row** ber-highlight teal muda (`#CCFBF1`) pada bagian paling bawah tabel metrik dan tabel stan kantin.
      - **Header Seksi Terstruktur**: Menambahkan seksi header bertata letak rapi (`I. RINGKASAN METRIK KEUANGAN`, `II. PENDAPATAN PER STAN KANTIN`).
      - **Lebar Kolom Ekstra Luas**: Mengatur lebar kolom (36.0, 26.0, 36.0, dst) agar tidak ada teks yang terpotong.
50. **Logo Aset Kustom untuk Blokir Kartu & Aktifkan Kartu**: ✅ **Selesai**
    * **Penerapan Gambar Logo Kustom + Fallback**: Mengintegrasikan 2 aset gambar kustom baru:
      - [ic_card_block.png](file:///d:/mantap%20sih/kantin-digital-v2/assets/icons/ic_card_block.png) (Kartu RFID Teal + Gembok Terkunci Putih) untuk aktivitas **Blokir Kartu / Unlink Kartu / Freeze Kartu**.
      - [ic_card_activate.png](file:///d:/mantap%20sih/kantin-digital-v2/assets/icons/ic_card_activate.png) (Kartu RFID Teal + Gembok Terbuka Putih) untuk aktivitas **Aktifkan Kartu / Registrasi Kartu / Unfreeze Kartu**.
      - Diaplikasikan pada modal detail `_showDetailDialog`, riwayat transaksi [keuangan_history_screen.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/keuangan/screens/keuangan_history_screen.dart), dan [audit_log_tile.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/admin/widgets/audit_log_tile.dart) lengkap dengan `errorBuilder` fallback yang aman.
51. **Penyelarasan Warna Card Panel Akun Demo dengan Card Form Login**: ✅ **Selesai**
    * **Presisi Token Warna AppColors**: Merombak total variabel warna pada [login_account_preview.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/auth/widgets/login_account_preview.dart) dan [login_preview_item.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/auth/widgets/login_preview_item.dart) agar menggunakan sistem token warna `AppColors` yang persis sama dengan kartu form utama login.
52. **Redesain Total Styling Cetak PDF Laporan Keuangan (Executive Grade Layout)**: ✅ **Selesai**
    * **Redesain Visual & Layout dokumen PDF**: Merombak fungsi `downloadPdfReport` di [report_export_service.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/core/services/report_export_service.dart) dengan standar tata letak eksekutif profesional.
53. **Integrasi Grafik Tren Transaksi Harian Realtime (Supabase Realtime Stream)**: ✅ **Selesai**
    * **Stream Realtime & Pengolahan Data Transaksi Asli**: Merombak [daily_trend_chart_dialog.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/keuangan/widgets/daily_trend_chart_dialog.dart) dan [keuangan_providers.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/keuangan/providers/keuangan_providers.dart) dari data statis/mock menjadi data **Realtime**.
54. **Penyelarasan Grafik Tren Transaksi dengan Periode Filter Terpilih**: ✅ **Selesai**
    * **Penyesuaian Rentang Tanggal & Agregasi Dinamis**: Meng-update `DailyTrendChartDialog` dan `dailyTrendChartRealtimeProvider` agar menerima parameter `ReportFilterParam` yang dipilih user (contoh: *01 Jul 2026 - 17 Jul 2026*, *Hari Ini*, *Minggu Ini*, *Bulan Ini*, atau *Rentang Tanggal Kustom*):
      - Mengagregasikan data transaksi Supabase secara presisi sesuai rentang tanggal awal (`startDate`) dan akhir (`endDate`) yang aktif.
      - **Adaptif Skala Waktu**: Rentang <= 14 hari menampilkan titik harian dengan tanggal/nama hari, rentang 15-31 hari menampilkan titik per tanggal (1..31), dan rentang > 31 hari mengelompokkan data per bulan.
      - Menghitung rata-rata harian dan perbandingan % dengan periode sebelumnya secara dinamis.
      - Menyesuaikan label header modal dialog dengan nama periode yang sedang aktif.
55. **Dukungan Tampilan Keseluruhan Menu Saat Memilih "Semua Stan"**: ✅ **Selesai**
    * **Penyelarasan Query & Filter Provider**: Memperbaiki logika filter pada `categoryPreviewProvider`, `PaginatedProductsNotifier`, serta [public_menu_screen.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/public/screens/public_menu_screen.dart) dan [public_providers.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/public/providers/public_providers.dart):
      - Ketika opsi **"Semua Stan"** (`canteenId == 'semua'`) dipilih, sistem tidak lagi menyaring berdasarkan satu operator ID spesifik, melainkan secara otomatis menampilkan seluruh daftar makanan, minuman, dan camilan dari semua stan kantin yang terdaftar di aplikasi.
      - Menambahkan label nama stan penyedia (misal: `🏬 Bude Ani`, `🏬 Stan Bakso Enak`, `🏬 Stan Utama`) pada kartu menu agar pengguna dapat langsung mengetahui asal stan dari setiap item menu.
56. **Penyempurnaan Kategorisasi Otomatis Opsi Toping (Saus vs Sayuran/Lalapan)**: ✅ **Selesai**
    * **Presisi Pengelompokan Jenis Toping**: Memperbaiki fungsi klasifikasi `_isSauce` dan `_isVegetable` di [product_form_screen.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/kantin/screens/product_form_screen.dart) dan [public_menu_screen.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/public/screens/public_menu_screen.dart):
      - **Kategori Saus (`_isSauce`)**: Hanya mengategorikan item yang mengandung kata `saus`/`sauce` atau nama racikan saus spesifik (`tiram`, `barbekyu`, `teriyaki`, `mayo`).
      - **Kategori Sayuran & Lalapan (`_isVegetable`)**: Nama sayuran polos seperti `tomat`, `timun`, `bayam`, `selada`, `kubis`, `kemangi`, `bawang`, dll. yang tidak mengandung kata `saus` kini secara tepat dimasukkan ke seksi **"4. Lalapan & Sayuran"**.
57. **Komponen Toast Notifications Eksekutif 'Berhasil Disimpan' di Seluruh Role**: ✅ **Selesai**
    * **Pembuatan Komponen Reusable `AppToast`**: Membuat [app_toast.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/core/widgets/app_toast.dart) yang mereplikasi desain Toast 'Berhasil Disimpan' 100% presisi sesuai gambar acuan pengguna:
      - Kartu melayang (floating card) berwarna putih/gelap dengan border halus, bayangan elevasi modern, serta garis aksen vertikal hijau emerald (`#10B981`) di sisi kiri.
      - Badge bundar checkmark hijau dengan ikon centang putih.
      - Judul bold **"Berhasil Disimpan"** dan subjudul rincian status (contoh: *"Data Anda telah aman diperbarui."*).
      - Tombol penutup 'X' untuk menutup toast secara instan.
    * **Penerapan Lintas Role**: Menghubungkan `AppToast.showSuccess` ke seluruh form simpan, ubah kata sandi, registrasi rfid, update profil, tambah pengguna/stan, dan simpan jajanan di role **Kantin/Merchant**, **Admin**, **Petugas Keuangan**, **Siswa**, dan **Orang Tua**.
58. **Integrasi Grafik Tren 'Daily Sales Volume' di Beranda Petugas Kantin**: ✅ **Selesai**
    * **Komponen Grafik Reusable `DailySalesVolumeWidget`**: Membuat [daily_sales_volume_widget.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/kantin/widgets/daily_sales_volume_widget.dart) yang menampilkan kartu grafik tren penjualan harian sesuai gambar acuan pengguna:
      - Header dengan judul **"Daily Sales Volume"**, subjudul penjelasan, dan dua indikator legenda di kanan: 🔵 **Current Period** (biru/teal solid) & ⚪ **Previous Period** (abu-abu putus-putus).
      - **Dua Deret Garis Kurva Smooth Bezier**: Garis kurva biru/teal dengan area isi gradien transparan di bawahnya untuk *Current Period* (bulan ini) dan garis kurva putus-putus (dashed) untuk *Previous Period* (bulan sebelumnya).
      - Label sumbu X (`01`, `05`, `10`, `15`, `20`, `25`, `30`) dan sumbu Y adaptif skala penjualan.
    * **Provider Supabase Realtime (`canteenSalesVolumeProvider`)**: Menambahkan provider stream di [pos_providers.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/kantin/providers/pos_providers.dart) yang mendengarkan perubahan transaksi secara realtime dan mengagregasi volume penjualan harian stan kantin yang sedang login.
    * **Pemasangan di Beranda**: Menempatkan `DailySalesVolumeWidget` pada [pos_home_screen.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/kantin/screens/pos_home_screen.dart) tepat di bawah tombol aksi cepat Kasir POS & Cek Kartu.
59. **Lokalisasi Bahasa Indonesia & Filter Rentang Periode Kustom Grafik Penjualan Kantin**: ✅ **Selesai**
    * **Lokalisasi Bahasa Indonesia**: Mengubah teks pada [daily_sales_volume_widget.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/kantin/widgets/daily_sales_volume_widget.dart) menjadi Bahasa Indonesia:
      - Judul: **"Volume Penjualan Harian"**
      - Subjudul: *"Volume penjualan harian stan kantin Anda"*
      - Legenda: 🔵 **Periode Saat Ini** & ⚪ **Periode Sebelumnya**
    * **Filter Rentang Tanggal, Bulan, & Tahun Kustom**:
      - Menambahkan tombol pemilih periode (`[ 📅 Bulan Ini ▾ ]`) di pojok kanan atas grafik.
      - Menyediakan menu modal bottom sheet dengan opsi pilihan cepat: **Bulan Ini**, **Bulan Lalu**, **7 Hari Terakhir**, **30 Hari Terakhir**, **Tahun Ini (2026)**, serta **Pilih Rentang Tanggal (Kustom)...**.
      - Menghubungkan ke `showDateRangePicker` Flutter bawaan berlokalisasi Indonesia sehingga pengguna dapat mengatur tanggal awal dan akhir bebas antar bulan dan tahun.
    * **Penyelarasan Agregasi Data Dinamis**: Memperbarui `canteenSalesVolumeProvider` di [pos_providers.dart](file:///d:/mantap%20sih/kantin-digital-v2/lib/features/kantin/providers/pos_providers.dart) untuk menerima parameter `CanteenSalesFilterParam`, yang secara otomatis mengagregasi data harian/bulanan periode terpilih dan menghitung periode perbandingan sebelumnya secara tepat.






