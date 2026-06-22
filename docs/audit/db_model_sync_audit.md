# Database & Model Sync Audit Report
**Date**: 2026-06-20
**Project**: kantin-digital

---

## 1. DB vs DART MODEL COMPARISON

### Table: `profiles` ↔ `UserProfile` (`lib/core/models/user_profile.dart`)

| DB Column | DB Type | Dart Field | Dart Type | Match? |
|-----------|---------|------------|-----------|--------|
| id | UUID/text | id | String | ✅ |
| email | TEXT NOT NULL | email | String? | ⚠️ Not null in DB, nullable in Dart |
| full_name | TEXT NOT NULL | fullName | String? | ⚠️ Not null in DB, nullable in Dart |
| username | TEXT UNIQUE|null | username | String? | ✅ |
| nisn | TEXT UNIQUE|null | nisn | String? | ✅ |
| password | TEXT|null | password | String? | ✅ |
| phone_number | TEXT|null | phoneNumber | String? | ✅ |
| relation | TEXT|null | relation | String? | ✅ |
| role | TEXT NOT NULL | role | String? | ⚠️ Not null in DB, nullable in Dart |
| is_active | BOOLEAN NOT NULL | isActive | bool? | ⚠️ Not null in DB, nullable in Dart |
| avatar_url | TEXT|null | avatarUrl | String? | ✅ |
| created_at | TIMESTAMPTZ NOT NULL | createdAt | DateTime? | ⚠️ Not null in DB, nullable in Dart |
| **—** | **—** | **updatedAt** | **DateTime?** | 🚨 **EXTRA FIELD** — `updated_at` does NOT exist in DB schema |

### Table: `students` ↔ `Student` (`lib/core/models/student.dart`)

| DB Column | DB Type | Dart Field | Dart Type | Match? |
|-----------|---------|------------|-----------|--------|
| id | UUID PK | id | String | ✅ |
| class | TEXT NOT NULL | class_ | String? | ⚠️ Not null in DB, nullable in Dart |
| balance | NUMERIC(12,2) DEFAULT 0 | balance | double | ✅ |
| daily_limit | NUMERIC(12,2) DEFAULT NULL | dailyLimit | double? | ✅ |
| is_active | BOOLEAN DEFAULT true | isActive | bool | ✅ |
| rfid_uid | TEXT UNIQUE|null | rfidUid | String? | ✅ |
| wa_notifications_enabled | BOOLEAN DEFAULT true | waNotificationsEnabled | bool | ✅ |
| parent_phone | TEXT|null | parentPhone | String? | ✅ |
| **—** | **—** | **lastTopupAt** | **DateTime?** | 🚨 **EXTRA FIELD** — `last_topup_at` does NOT exist in DB |
| **—** | **—** | **createdAt** | **DateTime?** | 🚨 **EXTRA FIELD** — `created_at` does NOT exist in `students` table |

### Table: `products` ↔ `Product` (`lib/core/models/product.dart`) ✅ ALL MATCH

| DB Column | DB Type | Dart Field | Dart Type | Match? |
|-----------|---------|------------|-----------|--------|
| id | UUID PK | id | String | ✅ |
| operator_id | UUID FK NOT NULL | operatorId | String | ✅ |
| name | TEXT NOT NULL | name | String | ✅ |
| price | NUMERIC(12,2) NOT NULL | price | double | ✅ |
| category | TEXT NOT NULL | category | String | ✅ |
| is_available | BOOLEAN DEFAULT true | isAvailable | bool | ✅ |
| image_url | TEXT|null | imageUrl | String? | ✅ |
| created_at | TIMESTAMPTZ NOT NULL | createdAt | DateTime? | ✅ |

### Table: `transactions` ↔ `Transaction` (`lib/core/models/transaction.dart`) ✅ ALL MATCH

| DB Column | DB Type | Dart Field | Dart Type | Match? |
|-----------|---------|------------|-----------|--------|
| id | UUID PK | id | String | ✅ |
| student_id | UUID FK NOT NULL | studentId | String | ✅ |
| operator_id | UUID FK NOT NULL | operatorId | String | ✅ |
| status | TEXT NOT NULL | status | String | ✅ |
| total_amount | NUMERIC(12,2) NOT NULL | totalAmount | double | ✅ |
| type | TEXT NOT NULL | type | String | ✅ |
| created_at | TIMESTAMPTZ NOT NULL | createdAt | DateTime | ✅ |
| (join data) | — | operator | Map? | ✅ extra (not column) |
| (join data) | — | student | Map? | ✅ extra (not column) |

### Table: `transaction_items` ↔ `TransactionItem` (`lib/core/models/transaction_item.dart`) ✅ ALL MATCH

| DB Column | DB Type | Dart Field | Dart Type | Match? |
|-----------|---------|------------|-----------|--------|
| id | UUID PK | id | String | ✅ |
| transaction_id | UUID FK NOT NULL | transactionId | String | ✅ |
| product_id | UUID FK|null | productId | String? | ✅ |
| quantity | INTEGER NOT NULL | quantity | int | ✅ |
| unit_price | NUMERIC(12,2) NOT NULL | unitPrice | double | ✅ |
| custom_notes | TEXT|null | customNotes | String? | ✅ |

### Table: `canteen_operators` ↔ `CanteenOperator` (`lib/core/models/canteen_operator.dart`)

| DB Column | DB Type | Dart Field | Dart Type | Match? |
|-----------|---------|------------|-----------|--------|
| id | UUID PK | id | String | ✅ |
| canteen_name | TEXT NOT NULL | canteenName | String | ✅ |
| balance_earned | NUMERIC(12,2) DEFAULT 0 | balanceEarned | double | ✅ |
| **—** | **—** | **createdAt** | **DateTime?** | 🚨 **EXTRA FIELD** — `created_at` does NOT exist in `canteen_operators` table |

### Table: `finance_officers` ↔ `FinanceOfficer` (`lib/core/models/finance_officer.dart`) ✅ ALL MATCH

| DB Column | DB Type | Dart Field | Dart Type | Match? |
|-----------|---------|------------|-----------|--------|
| id | UUID PK | id | String | ✅ |
| assigned_school | TEXT NOT NULL | assignedSchool | String | ✅ |
| authority_level | TEXT NOT NULL | authorityLevel | String | ✅ |
| features | TEXT[] DEFAULT '{}' | features | List\<String\> | ✅ |
| created_at | TIMESTAMPTZ NOT NULL | createdAt | DateTime? | ✅ |

### Table: `parent_students` ↔ `ParentStudent` (`lib/core/models/parent_student.dart`) ✅ ALL MATCH

| DB Column | DB Type | Dart Field | Dart Type | Match? |
|-----------|---------|------------|-----------|--------|
| parent_id | UUID PK | parentId | String | ✅ |
| student_id | UUID PK | studentId | String | ✅ |
| created_at | TIMESTAMPTZ NOT NULL | createdAt | DateTime? | ✅ |

### Table: `notifications` ↔ `AppNotification` (`lib/core/models/app_notification.dart`) ✅ ALL MATCH

| DB Column | DB Type | Dart Field | Dart Type | Match? |
|-----------|---------|------------|-----------|--------|
| id | UUID PK | id | String | ✅ |
| student_id | UUID FK NOT NULL | studentId | String | ✅ |
| title | TEXT NOT NULL | title | String | ✅ |
| message | TEXT NOT NULL | message | String | ✅ |
| type | TEXT NOT NULL | type | String | ✅ |
| is_read | BOOLEAN DEFAULT false | isRead | bool | ✅ |
| created_at | TIMESTAMPTZ NOT NULL | createdAt | DateTime? | ✅ |

### Table: `audit_logs` ↔ `AuditLog` (`lib/core/models/audit_log.dart`) ✅ ALL MATCH

| DB Column | DB Type | Dart Field | Dart Type | Match? |
|-----------|---------|------------|-----------|--------|
| id | UUID PK | id | String | ✅ |
| actor_id | UUID FK|null | actorId | String? | ✅ |
| actor_name | TEXT NOT NULL | actorName | String | ✅ |
| action_type | TEXT NOT NULL | actionType | String | ✅ |
| description | TEXT NOT NULL | description | String | ✅ |
| target_id | UUID|null | targetId | String? | ✅ |
| old_value | JSONB DEFAULT '{}' | oldValue | Map\<String, dynamic\> | ✅ |
| new_value | JSONB DEFAULT '{}' | newValue | Map\<String, dynamic\> | ✅ |
| ip_address | TEXT|null | ipAddress | String? | ✅ |
| user_agent | TEXT|null | userAgent | String? | ✅ |
| created_at | TIMESTAMPTZ NOT NULL | createdAt | DateTime? | ✅ |

### Table: `system_settings` ↔ `SystemSetting` (`lib/core/models/system_setting.dart`) ✅ ALL MATCH

| DB Column | DB Type | Dart Field | Dart Type | Match? |
|-----------|---------|------------|-----------|--------|
| key | TEXT PK | key | String | ✅ |
| value | JSONB NOT NULL | value | dynamic | ✅ |
| updated_by | UUID FK|null | updatedBy | String? | ✅ |
| updated_at | TIMESTAMPTZ NOT NULL | updatedAt | DateTime? | ✅ |

### Orphaned Dart Models (no corresponding DB table)

| Model File | Status | Notes |
|-----------|--------|-------|
| `rfid_card.dart` | ✅ Deprecated (`@Deprecated`) | RFID stored in `students.rfid_uid` — no separate table |
| `balance_adjustment.dart` | ✅ Deprecated (`@Deprecated`) | No `balance_adjustments` table in DB |
| `canteen_staff.dart` | ✅ Deprecated (`@Deprecated`) | No `canteen_staff` table in DB |
| `transaction_type.dart` | 🚨 **NOT deprecated, actively USED** | `transaction_types` table does NOT exist in DB schema or any migration! But `shared_providers.dart` queries `client.from('transaction_types').select('*')` |

### Composite Models (aggregate, no direct table mapping)

| Model File | Purpose |
|-----------|---------|
| `operator_transaction.dart` | Transaction with joined canteen/student data |
| `admin_dashboard_data.dart` | Super admin dashboard metrics |
| `admin_student_detail.dart` | Student detail (profile + student + transactions) |
| `admin_parent_detail.dart` | Parent detail (profile + children) |
| `admin_merchant_detail.dart` | Merchant detail (profile + operator + products + transactions) |
| `admin_finance_detail.dart` | Finance officer detail (profile + officer + audit logs) |
| `parent_dashboard_data.dart` | Parent dashboard (profile + student + transactions) |

---

## 2. MIGRATION FILE ANALYSIS

### File List & Summary

| # | File | What It Does | Lines |
|---|------|-------------|-------|
| 1 | `20260615000000_init.sql` | Creates extension uuid-ossp; creates tables: `profiles`, `students`, `canteen_operators`, `products`, `transactions`, `transaction_items`, `notifications`; creates trigger `handle_new_user`; creates RPCs `process_purchase` and `process_refund`; enables RLS on all tables; creates RLS policies | 351 |
| 2 | `20260615000100_add_login_fields.sql` | Adds `username` and `nisn` columns to `profiles`; populates initial data | 17 |
| 3 | `20260617000100_parent_portal_policies.sql` | Creates anon (public) RLS policies for all tables for parent portal | 39 |
| 4 | `20260617000200_parent_mobile_features.sql` | Adds `daily_limit`, `wa_notifications_enabled`, `parent_phone` to `students`; updates product category check to include 'camilan'; recreates `process_purchase` with daily limit validation | 116 |
| 5 | `20260617000300_super_admin_schema_extensions.sql` | Adds `password`, `phone_number`, `is_active` to `profiles`; creates `parent_students`, `finance_officers`, `audit_logs`, `system_settings` tables; updates role check constraint; updates `handle_new_user`; inserts mock data | 302 |
| 6 | `20260617000400_fix_rls_policies_keuangan.sql` | Adds INSERT/UPDATE RLS policies for finance/admin roles on `audit_logs`, `students`, `notifications`, `transactions`, `profiles`, `canteen_operators`, `finance_officers` | 134 |
| 7 | `20260617000500_disable_rls_for_dev.sql` | Disables RLS on ALL tables for development | 17 |
| 8 | `20260617000600_fix_student_auth_account.sql` | Creates/fixes auth user entry for student Ahmad Subarjo; ensures profile and student records exist | 77 |
| 9 | `20260619000100_add_daily_limit_validation.sql` | Recreates `process_purchase` RPC with improved daily limit validation using WIB (UTC+7) timezone | 128 |
| 10 | `20260619000200_add_avatar_storage.sql` | Creates `avatars` storage bucket; adds `avatar_url` column to `profiles`; creates storage RLS policies | 58 |
| 11 | `20260619000300_sync_profile_to_auth.sql` | Adds `relation` column to `profiles`; replaces `handle_new_user`; creates `create_user_account` RPC function | 164 |
| 12 | `20260619000400_auto_create_parent.sql` | Drops old `create_user_account`; creates new `create_user_account` with auto-create parent feature; retroactive sync for existing students without parents | 307 |

### Sequential Order Check ✅
- All 12 files are present, none missing
- Numeric suffixes within each date are correctly ordered
- Date gaps (20260615→20260617→20260619) are logical date jumps, not numbering gaps

---

## 3. RPC FUNCTION USAGE AUDIT

### Defined in DB Schema (db-schema-types.ts + migrations)

| RPC Function | DB Signature | Called From Dart? | Params Match? |
|-------------|-------------|------------------|--------------|
| `process_purchase` | `(p_rfid_uid: TEXT, p_operator_id: UUID, p_items: JSONB, p_total_amount: NUMERIC)` | ✅ `lib/features/kantin/providers/nfc_payment_provider.dart:205` | ✅ Params: `p_rfid_uid`, `p_operator_id`, `p_items`, `p_total_amount` |
| `process_refund` | `(p_transaction_id: UUID, p_operator_id: UUID, p_reason: TEXT)` | ✅ `lib/features/kantin/screens/sales_history_screen.dart:68` | ✅ Params: `p_transaction_id`, `p_operator_id`, `p_reason` |
| `create_user_account` | `(p_email: TEXT, p_password: TEXT, p_full_name: TEXT, p_role: TEXT, p_phone_number?, p_username?, p_nisn?, p_class?, p_canteen_name?, p_relation?, p_is_active?, p_rfid_uid?, p_parent_phone?)` | ✅ 6 call sites in `admin_users_screen.dart` (lines 645, 680, 730, 764, 1010, 1220) | ✅ All callers pass appropriate subset of parameters |
| `graphql` | built-in | ❌ Not called | N/A |

### Undocumented RPC (not in schema or migrations)

| RPC Function | Called From | Issue |
|-------------|------------|-------|
| `update_auth_user_password` | `admin_student_detail_screen.dart:46`, `keuangan_profile_screen.dart:89`, `keuangan_settings_screen.dart:89`, `keuangan_student_detail_screen.dart:50` | 🚨 **NOT DEFINED** in any migration or db-schema-types.ts. Calls are wrapped in try/catch as fallback, but function doesn't exist in the documented schema |

---

## 4. SUPABASE CLIENT INITIALIZATION

### Initialization (`lib/main.dart` lines 16-19)
```dart
await Supabase.initialize(
  url: String.fromEnvironment('SUPABASE_URL', defaultValue: '...'),
  publishableKey: String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '...'),
);
```
✅ Properly initialized with environment variable overrides and sensible defaults.

### Client Access Patterns
Both `shared_providers.dart` and `auth_provider.dart` define an identical `supabaseClientProvider`:
```dart
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
```

### 🚨 DUPLICATE PROVIDER WARNING
Both files define `supabaseClientProvider` identically:
1. `lib/core/providers/shared_providers.dart:9`
2. `lib/features/auth/providers/auth_provider.dart:7`

This creates a **naming conflict** — when both are imported, one will shadow the other. The `auth_provider.dart` version should import from `shared_providers.dart` instead of redefining.

---

## 5. ISSUE SUMMARY

### 🔴 Critical Issues

| # | Issue | Location | Severity |
|---|-------|----------|----------|
| 1 | `transaction_types` table doesn't exist in DB but is queried by Dart code | `shared_providers.dart:23` queries `client.from('transaction_types')` | 🔴 **HIGH** — Will cause runtime error |
| 2 | `update_auth_user_password` RPC called from 4 locations but not defined in any migration or schema | 4 Dart files | 🔴 **HIGH** — Will fail at runtime (wrapped in try/catch) |
| 3 | Duplicate `supabaseClientProvider` definition in two files | `shared_providers.dart` and `auth_provider.dart` | 🟡 **MEDIUM** — Naming conflict |

### 🟡 Notable Mismatches

| # | Issue | Details |
|---|-------|---------|
| 4 | **`UserProfile.updatedAt`** — extra field | `updated_at` doesn't exist in DB schema for `profiles` table |
| 5 | **`Student.lastTopupAt`** — extra field | `last_topup_at` doesn't exist in `students` table |
| 6 | **`Student.createdAt`** — extra field | `created_at` doesn't exist in `students` table |
| 7 | **`CanteenOperator.createdAt`** — extra field | `created_at` doesn't exist in `canteen_operators` table |
| 8 | **Nullable Dart fields for non-null DB columns** | `UserProfile.email`, `full_name`, `role`, `is_active`, `created_at` are NOT NULL in DB but nullable (`String?`, `bool?`, `DateTime?`) in Dart |
| 9 | **`Student.class` nullable in Dart** | DB `class` is TEXT NOT NULL, but Dart `class_` is `String?` |

### ⚪ Informational

| # | Issue | Details |
|---|-------|---------|
| 10 | Deprecated models retained in codebase | `RfidCard`, `BalanceAdjustment`, `CanteenStaff` — correctly marked `@Deprecated` |
| 11 | Hardcoded Supabase credentials in source | Default URL and anon key in `main.dart` — should use env vars in production |
