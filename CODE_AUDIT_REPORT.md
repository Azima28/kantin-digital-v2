# Code Audit Report — Kantin Digital

**Date:** 2026-06-20  
**Scope:** All 100 Dart files (95 in `lib/`, 5 in `test/`)  
**Analyzer:** `flutter analyze` — **No issues found**

---

## 1. DEAD FILES — Never Imported by Any Other File

### `lib/core/providers/app_providers.dart` ⚠️ DEAD
Contains the following symbols — **NONE are used anywhere in the project**:
- `AppState` class
- `AppStateNotifier` class
- `appStateProvider`
- `networkStatusProvider`
- `isOnlineProvider`
- `globalRefreshKeyProvider`
- `globalErrorProvider`
- `CacheDuration` class

All of this code (208 lines) is unreferenced dead code.

### `lib/core/providers/shared_providers.dart` ⚠️ DEAD
Contains the following symbols — **NONE of these specific definitions are imported/used**:
- `supabaseClientProvider` (DUPLICATE — see §2)
- `transactionTypesProvider`
- `transactionTypeMapProvider`
- `currentUserProfileProvider`
- `studentByIdProvider`
- `rfidCardsProvider`
- `rfidByUidProvider`

All of this code (109 lines) is unreferenced dead code.

---

## 2. DUPLICATE PROVIDER DEFINITION ⚠️

`supabaseClientProvider` is defined in **two** files:
| File | Line | Status |
|------|------|--------|
| `lib/core/providers/shared_providers.dart` | 9 | **Dead** (never imported) |
| `lib/features/auth/providers/auth_provider.dart` | 7 | **Active** (used across 10+ files) |

This creates a latent conflict: if anything ever imports `shared_providers.dart`, the compiler would see two top-level `supabaseClientProvider` definitions. The `shared_providers.dart` version should be removed.

---

## 3. PRODUCTION DEBUG PRINT STATEMENTS (17 calls)

| File | Count |
|------|-------|
| `lib/core/services/offline_queue_service.dart` | 6 |
| `lib/core/providers/app_providers.dart` | 3 *(dead file)* |
| `lib/core/services/nfc_service.dart` | 2 |
| `lib/core/services/storage_service.dart` | 2 |
| `lib/features/auth/providers/auth_provider.dart` | 2 |
| `lib/features/siswa/screens/siswa_notifications_screen.dart` | 1 |
| `lib/core/providers/app_providers.dart` *(dead)* | 2 |

All use `debugPrint()` — should be replaced with a proper logging mechanism or removed before release.

---

## 4. UNUSED IMPORT

| File | Import | Issue |
|------|--------|-------|
| `lib/features/parent/screens/parent_dashboard_screen.dart` | `import 'dart:math';` (line 1) | `dart:math` symbols (`Random`, `min`, `max`, etc.) are never used anywhere in this file |

---

## 5. WEB-INCOMPATIBLE PLATFORM IMPORT

| File | Import | Risk |
|------|--------|------|
| `lib/features/kantin/screens/product_form_screen.dart` | `import 'dart:io';` (line 1) | Will fail at compile time on web; use `universal_io` or conditional imports |

---

## 6. MISSING FEATURE SUBDIRECTORIES

Feature should ideally have `screens/`, `providers/`, and `widgets/` subdirectories:

| Feature | providers/ | widgets/ | Notes |
|---------|-----------|----------|-------|
| `admin/` | ✅ | ✅ | |
| `auth/` | ✅ | ❌ Missing | has `services/` instead |
| `kantin/` | ✅ | ✅ | |
| `keuangan/` | ✅ | ✅ | |
| `parent/` | ✅ | ❌ Missing | |
| `public/` | ❌ Missing | ❌ Missing | Only has `screens/` |
| `shared/` | ❌ Missing | ❌ Missing | Only has `screens/` |
| `siswa/` | ✅ | ✅ | |

---

## 7. CLEAN — No Issues Found ✅

| Check | Status |
|-------|--------|
| **Route screens exist** | ✅ All 49 route constants in `app_router.dart` map to existing files |
| **AppRouter imports resolve** | ✅ All 48 `import` statements in `app_router.dart` point to real files |
| **Model barrel export** | ✅ All 22 model files in `core/models/` are exported from `models.dart` |
| **TODO/FIXME/HACK comments** | ✅ Zero found |
| **print() calls** | ✅ Zero found (only `debugPrint`) |
| **Commented-out code blocks** | ✅ Not detected |
| **Duplicate model imports** | ✅ No file imports both `models.dart` AND a specific model file |
| **Flutter analyze** | ✅ Passes with "No issues found" |
| **Test files reference real sources** | ✅ All 5 test files import existing source files |
| **Provider cross-references** | ✅ All 8 feature provider files are imported by screens in the same feature |

---

## 8. PROJECT STATS

| Metric | Value |
|--------|-------|
| Total Dart files | 100 |
| lib/ files | 95 |
| test/ files | 5 |
| Dead files | 2 (1,952 bytes / 317 lines) |
| debugPrint calls | 17 |
| Unused imports | 1 |
| Web-incompatible imports | 1 |
| Duplicate providers | 1 |
| Missing feature dirs | 6 |

---

## RECOMMENDATIONS

1. **Remove** `lib/core/providers/app_providers.dart` entirely (dead code)
2. **Remove** `lib/core/providers/shared_providers.dart` entirely (dead code + duplicate provider)
3. **Replace** `debugPrint()` calls with a proper logging package (e.g., `logger`)
4. **Remove** unused `import 'dart:math'` from `parent_dashboard_screen.dart`
5. **Replace** `import 'dart:io'` in `product_form_screen.dart` with conditional/platform import
6. Add `widgets/` directories to features that are missing them (if needed)
