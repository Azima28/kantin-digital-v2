# Hardcoded Bahasa Indonesia Strings Audit

**Date:** $(date)
**Project:** ~/projects/kantin-digital
**AppStrings Source:** lib/core/constants/app_strings.dart (108 constants)

## Summary

| Metric | Count |
|--------|-------|
| AppStrings constants defined | 108 |
| Dart files scanned | 124 |
| Files with hardcoded ID strings | **82** |
| Total hardcoded occurrences | **542** |

## Per-File Breakdown (Top 20)

| # | Occurrences | File |
|---|------------|------|
| 1 | 29 | lib/features/admin/screens/admin_audit_log_screen.dart |
| 2 | 23 | lib/features/keuangan/screens/keuangan_students_screen.dart |
| 3 | 21 | lib/features/kantin/screens/sales_history_screen.dart |
| 4 | 20 | lib/features/keuangan/screens/keuangan_history_screen.dart |
| 5 | 19 | lib/features/siswa/screens/siswa_dashboard_screen.dart |
| 6 | 19 | lib/features/admin/screens/admin_users_screen.dart |
| 7 | 18 | lib/features/parent/screens/parent_dashboard_screen.dart |
| 8 | 17 | lib/features/admin/widgets/admin_import_csv_dialog.dart |
| 9 | 14 | lib/features/siswa/screens/siswa_history_screen.dart |
| 10 | 14 | lib/features/keuangan/screens/keuangan_users_screen.dart |
| 11 | 14 | lib/features/keuangan/screens/keuangan_card_registration_screen.dart |
| 12 | 14 | lib/features/kantin/screens/cart_screen.dart |
| 13 | 12 | lib/features/keuangan/screens/keuangan_student_detail_screen.dart |
| 14 | 11 | lib/features/kantin/screens/product_form_screen.dart |
| 15 | 11 | lib/features/admin/screens/admin_student_detail_screen.dart |
| 16 | 11 | lib/features/admin/screens/admin_parent_detail_screen.dart |
| 17 | 10 | lib/features/siswa/screens/siswa_profile_screen.dart |
| 18 | 10 | lib/features/siswa/screens/siswa_cards_screen.dart |
| 19 | 10 | lib/features/keuangan/widgets/keuangan_users_tabs.dart |
| 20 | 10 | lib/features/keuangan/screens/keuangan_report_screen.dart |

## Priority Words Audit

| Word | Hardcoded Occurrences | AppStrings Constant Available? |
|------|----------------------|-------------------------------|
| **Gagal** | 81 | `labelError` = 'Terjadi kesalahan' (partial match) |
| **Memuat** | 36 | `labelLoading` = 'Memuat...' |
| **Berhasil** | 11 | `labelSuccess` = 'Berhasil' |
| **Tambah** | 19 | `kantinAddMenu` = 'Tambah Menu', `buttonAddProduct` |
| **Detail** | 16 | ❌ NOT available |
| **Pilih** | 15 | ❌ NOT available (except `buttonChoosePhoto`) |
| **Hapus** | 7 | `buttonDelete` = 'Hapus' |
| **Cari** | 7 | `labelSearch` = 'Cari...' |
| **Kembali** | 5 | `buttonBack` = 'Kembali' |
| **Konfirmasi** | 4 | ❌ NOT available |
| **Simpan** | 3 | `buttonSave` = 'Simpan' |
| **Tidak** | 3 | ❌ NOT available |
| **Batal** | 2 | `buttonCancel` = 'Batal' |
| **Edit** | 1 | ❌ NOT available (kantinEditMenu = 'Ubah Menu') |
| **Ya** | 0 | ❌ NOT available |
| **Loading** | 0 | Uses 'Memuat...' (correct) |

## Most Common Hardcoded Patterns

1. **'Gagal memuat data'** — appears in 12+ files (audit, dashboard, detail screens)
2. **'Kata Sandi' / 'sandi baru' / 'sandi'** — 10+ files (labelPassword exists!)
3. **'Total'** — various contexts (labelTotal exists)
4. **'Nama Siswa', 'Nama', 'Nama Lengkap'** — widely used (labelStudentName exists)
5. **'Kelas'** — many files (labelStudentClass exists)
6. **'Saldo'** — many files (labelBalance, labelRemainingBalance exist)
7. **'Transaksi'** — many files (no generic constant)
8. **'Riwayat'** — various (sectionTodayPurchase, titleHistorySales exist)
9. **'Kartu'** — various (labelCardStatus, nfcCardVerified exist)
10. **'Status'** — various (labelCardStatus, statusCardActive exist)

## Key Missing AppStrings (Suggested Additions)

These commonly used words/phrases have NO AppStrings constant:

- `Detail` — used in 16 instances ('Detail Transaksi', 'Detail Siswa', etc.)
- `Konfirmasi` — used in 4 instances
- `Tidak` — used in 3 instances ('Tidak Mencukupi', 'Tidak Terdaftar')
- `Edit/Ubah` — only `kantinEditMenu = 'Ubah Menu'` exists (no generic 'Edit')
- `Pilih` — only context-specific (buttonChoosePhoto)
- `Ya` — 0 occurrences but useful to have for dialogs
- `Nama Lengkap` — labelStudentName is 'Nama Siswa' only
- `Kata Sandi` — labelPassword exists but many files use variations
- `Transaksi` — no generic 'Transaksi' constant
- `Berkas/Data` — general purpose labels

## Recommendations

1. **Add 5-10 new AppStrings constants** for the most frequent missing words (Detail, Konfirmasi, Pilih, Ya, Tidak, Edit, Transaksi, Riwayat)
2. **Prioritize high-count files** — admin_audit_log_screen.dart (29), keuangan_students_screen.dart (23), sales_history_screen.dart (21)
3. **Replace 'Gagal memuat data' pattern** with a reusable error string constant
4. **Standardize 'Nama' fields** — use `labelStudentName` consistently
5. Run `flutter analyze` after each batch of replacements to catch issues
