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
    *   `globalErrorProvider` — error state global
*   [x] **Shared Providers** (`lib/core/providers/shared_providers.dart`) — baru:
    *   `supabaseClientProvider` — Supabase client singleton
    *   `transactionTypesProvider` — cached transaction types
    *   `transactionTypeMapProvider` — id→type lookup map
    *   `currentUserProfileProvider` — profile user login
    *   `studentByIdProvider` — student by ID (family provider)
    *   `rfidCardsProvider` — semua RFID cards
    *   `rfidByUidProvider` — RFID by UID (family provider)
*   [x] **Keuangan Providers** (`lib/features/keuangan/providers/keuangan_providers.dart`) — baru:
    *   `keuanganStudentsProvider` — daftar siswa (typed `StudentWithProfile`)
    *   `studentDetailProvider` — detail siswa + transaksi + adjustment
    *   `unlinkedRfidsProvider` — RFID belum ter-link
    *   `usersProvider` — daftar non-student users
    *   `topupStudentsProvider` — siswa dengan RFID untuk top-up
    *   `topupTransactionsProvider` — riwayat top-up
    *   `adjustmentTransactionsProvider` — riwayat adjustment
    *   `reportTransactionsProvider` — data laporan transaksi
    *   `reportAdjustmentsProvider` — data laporan adjustment
    *   `dashboardDataProvider` — data ringkasan dashboard

#### ⏳ Belum Dikerjakan:
*   [ ] Migrasi screen-screen ke typed models (masih menggunakan `Map<String, dynamic>`)
*   [ ] Kantin/POS providers (ekstraksi dari inline screen providers)
*   [ ] Siswa providers (ekstraksi dari inline screen providers)
*   [ ] Admin providers (ekstraksi dari inline screen providers)
*   [ ] Parent providers (ekstraksi dari inline screen providers)
*   [ ] Repository pattern / service layer untuk business logic

### [ ] Phase 10: Security Hardening & Production Readiness
*   [ ] **⚠️ KRITIS**: Mengaktifkan kembali RLS (`ENABLE ROW LEVEL SECURITY`) — saat ini dinonaktifkan via `20260617000500_disable_rls_for_dev.sql`.
*   [ ] **⚠️ KRITIS**: Password hashing (bcrypt/argon2) — saat ini password disimpan plaintext di tabel `profiles`.
*   [ ] Audit & cleanup file orphan.
*   [ ] Input validation & sanitization.
*   [ ] Rate limiting untuk API calls.
*   [ ] Error boundary & crash reporting.
*   [ ] Environment configuration (dev/staging/prod).

**Progres Keseluruhan**: ~85%



---

## 📌 Catatan Penting untuk Agen Berikutnya

1. **RLS Nonaktif**: File migrasi `20260617000500_disable_rls_for_dev.sql` menonaktifkan RLS secara global. **WAJIB** mengaktifkan kembali sebelum production.
2. **Password Plaintext**: Password user saat ini disimpan tanpa hashing di kolom `profiles.password`. Perlu migrasi ke bcrypt/argon2.
3. **Dual-Path Auth**: `auth_service.dart` memiliki fallback ke plaintext password check. Setelah RLS aktif dan password di-hash, fallback ini harus dihapus/disesuaikan.
4. **Typed Models Tersedia**: Data models sudah dibuat di `lib/core/models/` tapi screen-screen masih menggunakan `Map<String, dynamic>`. Perlu migrasi bertahap.
5. **Providers Tersedia**: Shared & keuangan providers sudah dibuat di `lib/core/providers/` dan `lib/features/keuangan/providers/`. Screen providers perlu dimigrasi.
6. **Perbaikan Layout Overflows**: Mengatasi horizontal RenderFlex overflows pada `ParentBalanceCard`, `ParentActionGrid`, `ParentDailyLimitCard`, `PosHomeScreen`, `PosDashboardScreen` (floating cart bar di bagian bawah), `SalesHistoryScreen` (pada item daftar aktivitas penjualan kasir), `TransactionDetailsSheet`, judul `"AKTIVITAS TERAKHIR HARI INI"` pada `ParentHomeTab`, rekap header `'Ringkasan Periode (...)'` pada `KeuanganReportScreen`, serta status pills pada `KeuanganStudentCard` dengan menambahkan `LayoutBuilder`, `Expanded`, `Wrap`, atau `FittedBox` dengan `BoxFit.scaleDown` untuk support display pada narrow screen.
7. **Simulasi Pembayaran Tap Kartu**: Menambahkan preset simulasi tap kartu RFID untuk siswa Ahmad Subarjo (`04:A3:F8:12`) pada panel `NfcSimulationInput` serta memperbaiki alur inisialisasi sesi NFC di `nfc_payment_provider.dart` agar tidak memicu `NfcPaymentStatus.error` secara instan pada platform Web. Serta memperbaiki horizontal overflow pada teks button preset Ahmad Subarjo dan header panel menggunakan `FittedBox` (scaleDown).
8. **Perbaikan Hak Akses RPC Database**: Menambahkan hak akses eksekusi RPC (`process_purchase`, `process_refund`, `process_topup`, `process_correction`) secara eksplisit ke role `anon` dan `authenticated` melalui migrasi `20260624000000_fix_fallback_auth_rpc.sql`, yang berhasil di-push ke remote database menggunakan Supabase CLI. Hal ini mengatasi masalah `PostgrestException: permission denied for function process_purchase`.
9. **Penyempurnaan Alur Login, Logout & UI Orang Tua**: Mengganti tombol `"Ganti NISN"` di dashboard Orang Tua dengan tombol **Logout** standar (`showLogoutConfirmationDialog`). Mengonfigurasi `redirect` GoRouter agar Orang Tua langsung masuk ke dashboard anak (`/parent/dashboard/$studentId`) setelah login, serta membungkus bottom navigation bar dalam `Container` berlatar belakang putih solid untuk menghilangkan shadow/gradien hitam vignette default.
10. **Perbaikan Fitur Ubah Kata Sandi pada Mode Fallback**: Memperbaiki pemanggilan RPC `update_auth_user_password` di seluruh 7 halaman/modul (Admin & Keuangan) dengan menambahkan parameter `p_caller_id` agar dapat tervalidasi dengan sukses saat menggunakan fallback auth (role `anon` di mana `auth.uid()` bernilai null). Serta memperbaiki error handling agar tidak menelan exception/kesalahan secara diam-diam.
