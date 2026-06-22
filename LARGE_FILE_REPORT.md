# Large File Report — Top 5 Largest Screens

Generated: 20 June 2026

## Summary

| # | File | Lines | Classes |
|---|------|-------|---------|
| 1 | `lib/features/keuangan/screens/keuangan_users_screen.dart` | 1,668 | 6 |
| 2 | `lib/features/admin/screens/admin_users_screen.dart` | 1,593 | 2 |
| 3 | `lib/features/parent/screens/parent_dashboard_screen.dart` | 1,514 | 2 |
| 4 | `lib/features/parent/screens/parent_topup_screen.dart` | 1,173 | 2 |
| 5 | `lib/features/keuangan/screens/keuangan_correction_screen.dart` | 1,159 | 2 |

---

### 1. keuangan_users_screen.dart (1,668 lines)
- `KeuanganUsersScreen` (ConsumerStatefulWidget) — L13
- `_KeuanganUsersScreenState` (ConsumerState) — L21
- `_StudentsTab` (ConsumerStatefulWidget) — L680
- `_StudentsTabState` (ConsumerState) — L688
- `_ParentsTab` (ConsumerWidget) — L1007
- `_StaffTab` (ConsumerWidget) — L1393

### 2. admin_users_screen.dart (1,593 lines)
- `AdminUsersScreen` (ConsumerStatefulWidget) — L11
- `_AdminUsersScreenState` (ConsumerState) — L18

### 3. parent_dashboard_screen.dart (1,514 lines)
- `ParentDashboardScreen` (ConsumerStatefulWidget) — L13
- `_ParentDashboardScreenState` (ConsumerState) — L21

### 4. parent_topup_screen.dart (1,173 lines)
- `ParentTopUpScreen` (ConsumerStatefulWidget) — L14
- `_ParentTopUpScreenState` (ConsumerState) — L22

### 5. keuangan_correction_screen.dart (1,159 lines)
- `KeuanganCorrectionScreen` (ConsumerStatefulWidget) — L13
- `_KeuanganCorrectionScreenState` — L22

---

## Observations
- **keuangan_users_screen.dart** is the largest and most complex — it embeds 4 private widget classes (`_StudentsTab`, `_StudentsTabState`, `_ParentsTab`, `_StaffTab`) inside the screen file. These could be extracted into separate files.
- **admin_users_screen.dart** is 1,593 lines with only 2 classes — the state class is extremely long and could benefit from breaking into smaller widget methods or extracted components.
- All 5 files exceed 1,000 lines, which makes them candidates for refactoring into smaller, focused files.
