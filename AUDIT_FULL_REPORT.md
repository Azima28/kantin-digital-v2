# Kantin Digital — Full Security + Migration + Structure Audit

**Date:** 2026-06-20  
**Scope:** All Dart files under `lib/`, all SQL files under `supabase/migrations/`  
**Type:** Audit Only — no files modified

---

## 1. SECURITY AUDIT

### 1.1 Direct `supabase.from('...').update()/.insert()/.delete()` bypassing RPC

#### 🔴 CRITICAL — Balance-related table mutations bypassing RPC

| File | Line | Table | Operation | Issue |
|------|------|-------|-----------|-------|
| `parent_dashboard_screen.dart` | 90 | `students` | UPDATE | Parent directly updates `daily_limit`, `is_active`, `wa_notifications_enabled`, `parent_phone` on students table. Should use RPC. |
| `keuangan_card_registration_screen.dart` | 218 | `students` | UPDATE | Direct update of `rfid_uid`, `is_active` instead of RPC. |
| `keuangan_card_registration_screen.dart` | 125 | `students` | UPDATE | Direct update setting `rfid_uid = null`. |
| `admin_users_screen.dart` | 77 | `students` | UPDATE | Direct update of `is_active` status. |

#### 🔴 CRITICAL — Password writes to profiles table (plaintext by design, but no RPC)

| File | Line | Operation | Issue |
|------|------|-----------|-------|
| `admin_finance_detail_screen.dart` | 36 | `profiles.update({'password': password})` | Plaintext password write, no RPC, no bcrypt hashing |
| `admin_merchant_detail_screen.dart` | 36 | `profiles.update({'password': password})` | Same |
| `admin_parent_detail_screen.dart` | 34 | `profiles.update({'password': password})` | Same |
| `keuangan_profile_screen.dart` | 84 | `profiles.update({'password': password})` | Same |
| `keuangan_settings_screen.dart` | 84 | `profiles.update({'password': password})` | Same |

> **Impact:** These writes store plaintext password strings in `profiles.password`, bypassing the bcrypt hashing migration (`0018_hash_passwords.sql`). Hashed passwords compared via `crypt()` in RPC will break if a plaintext password is overwritten.

#### 🟡 MEDIUM — Other direct table mutations

| File | Line | Table | Issue |
|------|------|-------|-------|
| `admin_users_screen.dart` | 73 | `profiles` | Direct `is_active` update |
| `admin_parent_detail_screen.dart` | 65 | `profiles` | Direct `is_active` update |
| `admin_settings_screen.dart` | 116 | `system_settings` | Direct update of `maintenance_mode` |
| `admin_settings_screen.dart` | 121 | `system_settings` | Direct update of `midtrans_config` |
| `admin_users_screen.dart` | 703 | `finance_officers` | Direct update of finance officer data |
| `admin_import_csv_dialog.dart` | 232 | `parent_students` | Direct insert of parent-student links |
| `product_form_screen.dart` | 152 | `products` | Direct update of product |
| `product_form_screen.dart` | 156 | `products` | Direct insert of product |
| `manage_products_screen.dart` | 69 | `products` | Direct delete of product |
| `siswa_cards_screen.dart` | 45 | `notifications` | Direct insert of notification |

#### 🟢 LOW — Audit log writes (intentional, RLS permits)
Multiple files: `admin_settings_screen.dart:63,126`, `admin_student_detail_screen.dart:60,110`, `admin_users_screen.dart:86,510,714`, `admin_add_student_sheet.dart:150`, `admin_import_csv_dialog.dart:346`, `product_form_screen.dart:162`, `sales_history_screen.dart:80`, `keuangan_card_registration_screen.dart:128,229`, `keuangan_students_screen.dart:635`, `keuangan_student_detail_screen.dart:62,183`, `keuangan_users_screen.dart:321,528`, `parent_dashboard_screen.dart:104`, `siswa_cards_screen.dart:45`.

> These are audit log writes. Since RLS allows INSERT for authenticated users in proper roles, this is acceptable. However, centralizing to an RPC would be more consistent.

---

### 1.2 Auth Service — Fallback Path

**File:** `auth_service.dart`

- Fallback uses RPC `verify_password()` ✅ (line 141)
- However, profile lookups at lines 40-45, 50-54, 60-64, 74-78, 86-90, 125-135, 198-202 use direct `profiles.select()` — these are **SELECT-only** and acceptable for read operations.
- The `verify_password` RPC has `SECURITY DEFINER` ✅
- The fallback is properly gated (only fires when `authSessionEstablished == false`) ✅

---

### 1.3 Route Guards (`app_router.dart`)

All role-protected route groups properly checked:

| Route Prefix | Role Check | Status |
|-------------|-----------|--------|
| `/admin/` | `_adminRoles = {'super_admin', 'admin'}` | ✅ |
| `/finance/` | `_keuanganRoles = {'petugas_keuangan'}` | ✅ |
| `/pos/` | `_canteenRoles = {'petugas_kantin'}` | ✅ |
| `/student/` | `_studentRoles = {'student'}` | ✅ |
| `/parent/` | `_parentRoles = {'parent'}` | ✅ |
| `/public/`, `/login`, `/splash`, `/unauthorized`, `/welcome` | Public (no auth) | ✅ |

**No gaps found.** Every protected route requires a matching role. Redirects to `/unauthorized` on mismatch.

---

### 1.4 Hardcoded Secrets / Credentials in Code

#### In SQL migration files:

1. **`20260617000300_super_admin_schema_extensions.sql`**
   - Line 16: `DEFAULT 'password123'` — default password for all new profiles
   - Line 146: `"client_key": "SB-Mid-client-1234567890"` — mock Midtrans sandbox key
   - Line 197: `crypt('parent123', ...)` — mock parent password
   - Line 213: `crypt('budi123', ...)` — mock finance officer password
   - Line 229: `crypt('admin123', ...)` — mock super admin password
   - Lines 241, 245, 249: Plaintext passwords stored in profiles

2. **`20260617000600_fix_student_auth_account.sql`**
   - Line 14: `crypt('password123', ...)` — hardcoded student password
   - Line 28: `crypt('password123', ...)` — same
   - Line 54: `'password123'` — plaintext in profiles insert
   - Hardcoded UUID: `03525ad9-d9e3-4f55-8ee6-7ff5b06d2025`

3. **`20260619000400_auto_create_parent.sql`**
   - Line 237: `'password123'` — fallback password for retroactive sync

> **NOTE:** These are mock/seed data in migration files, intended for development. However, they represent a real security risk if this migration is applied to production without changing these defaults.

**In Dart files:** No hardcoded API keys, tokens, or secrets found. ✅

---

### 1.5 RPC Functions — SECURITY DEFINER Status

| RPC Function | SECURITY DEFINER | File |
|-------------|-----------------|------|
| `verify_password` | ✅ YES | `0014_verify_password_rpc.sql` |
| `get_student_by_nisn` | ✅ YES | `0015_get_student_by_nisn_rpc.sql` |
| `process_topup` | ✅ YES | `0017_...sql` / `0019_int_balance.sql` |
| `process_correction` | ✅ YES | `0017_...sql` / `0019_int_balance.sql` |
| `process_purchase` | ✅ YES | `20260617000200_...sql` / `0019_...sql` / `20260619000100_...sql` |
| `process_refund` | ✅ YES | `0019_int_balance.sql` |
| `create_user_account` | ✅ YES | `0018_hash_passwords.sql` / `20260619000300_...sql` / `20260619000400_...sql` |
| `handle_new_user` | ✅ YES | `20260617000300_...sql` / `20260619000300_...sql` |
| `update_auth_user_password` | ✅ YES | `20260620000000_...sql` |

**All RPC functions have SECURITY DEFINER.** ✅

---

### 1.6 RLS Policies (0016_enable_rls.sql)

**Anon policies:**
- ✅ Products (SELECT) — safe: public menu
- ✅ Canteen operators (SELECT) — safe: public info
- ✅ System settings (SELECT) — safe: public settings
- ✅ Parent-students (SELECT) — needed for parent portal
- ✅ Finance officers (SELECT) — safe: public info
- ⚠️ Students (SELECT) — exposes all student data (names, classes) to anon. Acceptable for parent portal but worth noting.
- ✅ Transactions (SELECT) — read-only
- ✅ Transaction items (SELECT) — read-only
- ⚠️ Audit logs (SELECT) — anon can read audit logs. Low risk but unnecessary.
- ✅ No DANGEROUS INSERT/UPDATE policies remain (pre-0016 anon-insert policies dropped)

**Authenticated policies:** All tables have appropriate authenticated policies for SELECT/INSERT/UPDATE based on role. ✅

**Key finding:** Migration `20260617000500_disable_rls_for_dev.sql` **disabled RLS on all tables** for development. This is later reversed by `0016_enable_rls.sql`. If `0016` is not applied after `20260617000500`, all tables remain open. The ordering must ensure `0016` runs AFTER `20260617000500`.

---

## 2. MIGRATION AUDIT

### 2.1 Naming Consistency

**Two naming conventions:**
- **Numeric series:** `0014_verify_password_rpc.sql` through `0019_int_balance.sql` (6 files)
- **Timestamp series:** `20260615000000_init.sql` through `20260620000000_add_update_password_rpc.sql` (14 files)

**Gaps detected:**
- No migrations numbered `0001`–`0013` in the numeric series
- The timestamp series starts at `20260615000000`, suggesting the project was rebuilt/rebased

**Ordering concern:** Numeric files (0014-0019) sort BEFORE timestamp files lexicographically. If applied alphabetically, `0014` to `0019` run before any `202606...` migration. This means:
- `0014` (verify_password RPC) runs before `20260615000000` (init schema) → would fail since `profiles` table doesn't exist yet
- This implies the numeric series was created BEFORE the timestamp series was adopted, and the actual application order is chronological by content, not by filename

**Recommendation:** Rename numeric files to timestamp convention for consistency and to avoid ordering confusion.

### 2.2 NUMERIC(12,2) → BIGINT Migration

**Status:** Migration `0019_int_balance.sql` successfully converts:
- `students.balance` → BIGINT ✅
- `canteen_operators.balance_earned` → BIGINT ✅
- `process_topup`, `process_correction`, `process_purchase`, `process_refund` all updated to BIGINT ✅

**Remaining NUMERIC(12,2) references:**
| File | Line | Column | Type |
|------|------|--------|------|
| `20260615000000_init.sql` | 21,30,38,50 | students.balance, canteen_operators.balance_earned, products.price, transactions.total_amount | NUMERIC(12,2) |
| `0017_process_topup_and_correction.sql` | 9,20,21,77,87 | RPC params/vars | NUMERIC(12,2) |
| `20260617000200_parent_mobile_features.sql` | 5,17,25,28 | students.daily_limit | NUMERIC(12,2) |
| `20260619000100_add_daily_limit_validation.sql` | 10,17,25 | students.daily_limit, RPC vars | NUMERIC |

> The old-style NUMERIC references in `0017` and `20260615000000` are superseded by migration `0019` and are **not applied in order** — they are intermediate files. The `daily_limit` column remaining NUMERIC is by design since it's a limit value, but is INCONSISTENT with the BIGINT balance approach.

---

## 3. DEAD CODE / STRUCTURE

### 3.1 Potentially Orphaned Files

Files not directly imported by `app_router.dart` or any other barrel file:
- `lib/features/shared/screens/officer_activities_screen.dart` — Not referenced in router
- `lib/features/shared/screens/student_transactions_screen.dart` — Not referenced in router

> Most other files are properly imported via `app_router.dart` or `models.dart` barrel.

### 3.2 Barrel File Check

**`lib/core/models/models.dart`** exports all 18 model files — complete coverage. ✅

### 3.3 Unused Imports

`flutter analyze` shows **0 issues** in `lib/` code (only 15 info/warning issues in `tooling/replace_colors.dart`). ✅ No unused imports in production code.

### 3.4 File Size Heatmap

| Lines | Count | Notable Largest Files |
|-------|-------|----------------------|
| <50 | 11 | Main, barrels, small widgets |
| 50-200 | 24 | Core models, services, small screens |
| 200-500 | 23 | Medium screens and providers |
| 500-800 | 15 | Large screens |
| **800+** | **5** | Largest: `parent_topup_form.dart` (994), `keuangan_topup_screen.dart` (923), `admin_users_screen.dart` (863), `parent_dashboard_screen.dart` (834), `admin_settings_screen.dart` (804) |

**Focus for refactoring:**
- `parent_topup_form.dart` (994 lines) — too large for a single widget
- `keuangan_topup_screen.dart` (923 lines) — too large
- `admin_users_screen.dart` (863 lines) — too large
- `parent_dashboard_screen.dart` (834 lines) — too large
- `admin_settings_screen.dart` (804 lines) — too large

---

## 4. SUMMARY OF FINDINGS

### 🔴 Critical (Fix Required)
1. **5 plaintext password writes** bypass RPC in: `admin_finance_detail_screen.dart:36`, `admin_merchant_detail_screen.dart:36`, `admin_parent_detail_screen.dart:34`, `keuangan_profile_screen.dart:84`, `keuangan_settings_screen.dart:84`
2. **Parent dashboard** (`parent_dashboard_screen.dart:90`) directly updates `students` table — could skip daily limit/freeze enforcement
3. **Card registration** (`keuangan_card_registration_screen.dart:125,218`) bypasses RPC for student status changes

### 🟡 High Priority
4. Direct table mutations in: `admin_users_screen.dart:73,77`, `admin_parent_detail_screen.dart:65`, `admin_settings_screen.dart:116,121`, `admin_import_csv_dialog.dart:232`, `admin_users_screen.dart:703` — should use RPC for consistency
5. Migration naming inconsistency (numeric vs timestamp) risks ordering confusion
6. Hardcoded default passwords in migration seed data (`'password123'`, `'admin123'`, `'parent123'`)

### 🟢 Medium / Informational
7. `20260617000500_disable_rls_for_dev.sql` exists — ensure `0016_enable_rls.sql` is applied after it in production
8. Anon users can SELECT from `audit_logs` — unnecessary data exposure
9. Migration naming could be unified to timestamp convention  
10. 5 files exceed 800 lines — consider splitting

### ✅ Already Good
- All RPC functions use `SECURITY DEFINER`
- Route guards cover all role-specific routes
- Fallback auth uses RPC `verify_password()` (not direct SELECT)
- Barrel file covers all models
- `flutter analyze` passes clean (0 errors/warnings in lib/)
- `0019_int_balance.sql` properly converts balance columns to BIGINT

---

*End of Audit Report*
