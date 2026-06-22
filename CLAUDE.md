# Kantin Digital — Project Context

## Overview
Sistem Kantin Digital — RFID/NFC-based digital canteen system. Menggantikan uang tunai dengan saldo digital terkontrol melalui kartu RFID/NFC.

## Tech Stack
- **Mobile:** Flutter (SDK ^3.9.2) with Material Design 3 + iOS-style minimalis
- **State Management:** flutter_riverpod ^2.5.1
- **Navigation:** go_router ^14.2.1 (declarative routing)
- **Backend:** Supabase (PostgreSQL + Auth + RPC + Realtime + Storage)
- **Hardware:** nfc_manager ^3.3.0 (RFID/NFC card reading)
- **Fonts:** Google Fonts (Inter)
- **PDF:** pdf + printing packages
- **Local:** shared_preferences, path_provider
- **Other:** connectivity_plus, image_picker, intl (ID locale), url_launcher

## Architecture Rules

### Feature-First Structure
```
lib/
├── core/
│   ├── constants/    # AppColors, AppStrings
│   ├── models/       # All data models (barrel export via models.dart)
│   ├── providers/    # Shared providers
│   ├── router/       # AppRouter — all route definitions
│   ├── services/     # NFC, OfflineQueue, PDF, Storage
│   ├── theme/        # AppTheme (Material + Cupertino)
│   ├── utils/        # CurrencyFormatter
│   └── widgets/      # Shared widgets
├── features/
│   ├── auth/         # Login, Splash
│   ├── admin/        # Super Admin dashboard & management
│   ├── kantin/       # POS cashier (home, cart, check-card, products, sales)
│   ├── keuangan/     # Finance (topup, correction, reports, card reg)
│   ├── parent/       # Parent portal & monitoring
│   ├── public/       # Public pages (no auth required)
│   ├── shared/       # Shared screens across roles
│   └── siswa/        # Student dashboard & history
└── main.dart
```

### Feature Module Pattern
Each feature: `screens/`, `providers/`, `widgets/` subdirectories. Some also have `services/`.

## Design Rules
- **Colors:** ONLY use AppColors constants from `core/constants/app_colors.dart`. NO hardcoded colors.
- **Strings:** ALL UI strings from `core/constants/app_strings.dart`. NO inline strings.
- **Card Style:** radius 16, elevation 0, border 0.5px `AppColors.borderLight`
- **AppBar:** centered title, transparent/no shadow
- **Input Fields:** underline border, iOS-style borderless
- **Loading State:** Use shimmer/skeleton or CupertinoActivityIndicator
- **Empty State:** Show illustration + message
- **Error State:** Show retry button + error message

## Security & Database
- **DO NOT** directly call `supabase.from('students').update(...)` for balance operations
- **ALWAYS** use RPC functions for financial transactions:
  - `process_purchase()` — ACID checkout with row locking, balance deduction, transaction + item logging, notification trigger
  - `process_refund()` — ACID refund with 10-minute expiry check
- **RLS Active:** All queries evaluated against `auth.uid()` via Row Level Security policies
- **Double-Spend Prevention:** Handled entirely inside the PostgreSQL RPC procedure

## App Routes
| Route | Screen | Role |
|-------|--------|------|
| `/` | SplashScreen | All |
| `/login` | LoginScreen | All |
| `/public` | PublicHomeScreen | Public |
| `/public/menu` | PublicMenuScreen | Public |
| `/public/info` | PublicSchoolInfoScreen | Public |
| `/welcome` | StudentWelcomeScreen | Siswa |
| `/student` | SiswaDashboardScreen | Siswa |
| `/student/topup` | SiswaTopUpScreen | Siswa |
| `/student/history` | SiswaHistoryScreen | Siswa |
| `/student/cards` | SiswaCardsScreen | Siswa |
| `/student/profile` | SiswaProfileScreen | Siswa |
| `/student/notifications` | SiswaNotificationsScreen | Siswa |
| `/parent` | ParentPortalScreen | Parent |
| `/parent/dashboard/:studentId` | ParentDashboardScreen | Parent |
| `/parent/topup/:studentId` | ParentTopUpScreen | Parent |
| `/parent/receipt` | ParentReceiptScreen | Parent |
| `/pos` | PosHomeScreen | Kasir |
| `/pos/terminal` | PosDashboardScreen | Kasir |
| `/pos/cart` | CartScreen | Kasir |
| `/pos/check-card` | CheckCardScreen | Kasir |
| `/pos/products` | ManageProductsScreen | Kasir |
| `/pos/products/form` | ProductFormScreen | Kasir |
| `/pos/sales` | SalesHistoryScreen | Kasir |
| `/pos/orders` | OrderListScreen | Kasir |
| `/finance` | KeuanganDashboardScreen | Keuangan |
| `/finance/students` | KeuanganStudentsScreen | Keuangan |
| `/finance/users` | KeuanganUsersScreen | Keuangan |
| `/finance/students/:studentId` | KeuanganStudentDetailScreen | Keuangan |
| `/finance/topup` | KeuanganTopupScreen | Keuangan |
| `/finance/correction` | KeuanganCorrectionScreen | Keuangan |
| `/finance/history` | KeuanganHistoryScreen | Keuangan |
| `/finance/report` | KeuanganReportScreen | Keuangan |
| `/admin` | AdminDashboardScreen | Admin |
| `/admin/users` | AdminUsersScreen | Admin |
| `/admin/audit` | AdminAuditLogScreen | Admin |
| `/admin/settings` | AdminSettingsScreen | Admin |

## Key Models (all in `lib/core/models/`)
- Student, UserProfile, RfidCard, Product
- Transaction, TransactionItem, TransactionType
- BalanceAdjustment, CanteenOperator, FinanceOfficer
- ParentStudent, AppNotification, AuditLog, SystemSetting
- Composite: AdminDashboardData, AdminStudentDetail, ParentDashboardData, etc.

## Build & Test
```bash
flutter pub get
flutter build apk --debug
flutter build apk --release
flutter test
flutter analyze
```

## Key Conventions
- Use `initializeDateFormatting('id_ID', null)` in main()
- NFC scanning via `nfc_manager` — reads UID from tag, formats as hex (04:2A:B5:E2)
- Offline queue stores pending operations in SharedPreferences, processes on reconnect (max 3 retries)
- PDF generation via `pdf` package + `printing` for preview/share
- Currency formatting via core/utils/currency_formatter.dart
