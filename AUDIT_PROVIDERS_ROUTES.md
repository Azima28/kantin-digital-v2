# Ultra-Deep Audit: Providers & Routes

## Kantin Digital Flutter Project
**Date:** 2026-06-20  
**Auditor:** Hermes Agent  
**Scope:** 11 provider files + 1 router file + navigation surface

---

## PROVIDER FILES AUDITED

| # | File | Lines |
|---|------|-------|
| 1 | `lib/features/auth/providers/auth_provider.dart` | 108 |
| 2 | `lib/features/kantin/providers/nfc_payment_provider.dart` | 244 |
| 3 | `lib/features/kantin/providers/cart_provider.dart` | 134 |
| 4 | `lib/features/kantin/providers/pos_providers.dart` | 101 |
| 5 | `lib/core/providers/app_providers.dart` | 208 |
| 6 | `lib/core/providers/shared_providers.dart` | 107 |
| 7 | `lib/features/admin/providers/admin_providers.dart` | 372 |
| 8 | `lib/features/parent/providers/parent_providers.dart` | 38 |
| 9 | `lib/features/keuangan/providers/keuangan_providers.dart` | 300 |
| 10 | `lib/features/siswa/providers/siswa_providers.dart` | 119 |
| 11 | `lib/features/public/providers/public_providers.dart` | 44 |

---

## CRITICAL ISSUES

### CRITICAL-1: `.single()` on potentially empty results WILL crash at runtime
`.single()` throws a `PostgrestException` when zero rows are returned. Many providers use it on lookups where the student/profile may not exist.

**Files affected:**
- **admin_providers.dart:192,199** — `adminStudentDetailProvider` calls `.single()` on profile and student fetch
- **admin_providers.dart:233** — `adminParentDetailProvider` calls `.single()` on profile
- **admin_providers.dart:264,271** — `adminMerchantDetailProvider` calls `.single()` on profile and operator
- **admin_providers.dart:350,357** — `adminFinanceDetailProvider` calls `.single()` on profile and officer
- **parent_providers.dart:18,22** — `parentDashboardProvider` calls `.single()` on profile and student
- **keuangan_providers.dart:242,249** — `keuanganStudentDetailProvider` calls `.single()` on profile and student

These 12 calls will crash if the profile/student is deleted or ID is wrong. Use `.maybeSingle()` with explicit null checks.

### CRITICAL-2: Hardcoded fallback PIN bypasses admin security
**secure_entry_screen.dart:35,38,41**
```dart
_correctPin = data['value'] is String ? data['value'] as String : '123456';
```
If the `system_settings` table is empty, DB query fails, or the `admin_pin` key is missing, the PIN falls back to `'123456'`. An attacker who knows the app exists can:
1. Block the Supabase query (network issue)
2. The fallback activates
3. Enter `123456` → full admin access granted

### CRITICAL-3: Simulated "Face ID" is a mock with zero security
**secure_entry_screen.dart:92-116**
```dart
void _simulateBiometric() {
  showDialog(...);  // Fake dialog
  Future.delayed(const Duration(seconds: 1), () {
    Navigator.pop(context);
    context.go('/admin');  // Always succeeds after 1 second
  });
}
```
The biometric "scan" is a hardcoded 1-second delay that always succeeds. There is no actual biometric check, no platform channel call, no device-level authentication. Anyone can push the face icon and bypass all security.

### CRITICAL-4: No auth guards on ANY route — direct URL access bypasses login
**app_router.dart** has zero redirect logic. All routes accept direct navigation:
- `/admin` can be navigated to without admin PIN
- `/finance` can be navigated to without authentication  
- `/pos` can be navigated to directly

The only "guard" is in `SplashScreen` and `LoginScreen` which redirect based on profile, but there are no GoRouter redirects (`GoRouter.redirect`), no `ShellRoute` auth guards, and no middleware. A user who bookmarks `/admin` gets in without authentication.

### CRITICAL-5: Plaintext password storage and comparison
**auth_service.dart:156-158** and **siswa_profile_screen.dart:570-589**
```dart
final String storedPassword = profile['password']?.toString() ?? '';
if (storedPassword != password) {
  throw Exception('...');
}
```
Passwords are stored as plaintext in the `profiles.password` column and compared directly in-app. This violates OWASP Top 10 (A2:2021 - Cryptographic Failures) and every security best practice. Even with the "fallback" justification in comments, this is dangerous.

### CRITICAL-6: Missing `catch(e, st)` — stack traces swallowed
All catch blocks use `catch(e)` or `catch(_)` without the stack trace parameter `st`. Debugging production issues will be nearly impossible.
- **auth_provider.dart:70** `catch(e)` no stack
- **nfc_payment_provider.dart:170,225** `catch(e)` no stack
- **admin_providers.dart:102** `catch(e)` no stack
- **keuangan_providers.dart** 5x `catch (_)` empty
- **siswa_providers.dart:111** `catch(_)` empty
- **app_providers.dart:116,139** `catch(e)` no stack
- **auth_service.dart** multiple `catch(_)` empty

Every occurrence should be `catch(e, st)` and at minimum log `st` during development.

---

## HIGH-SEVERITY ISSUES

### HIGH-1: Missing `autoDispose` on 6 providers making network calls
All providers in `pos_providers.dart` (4 providers) and `auth_provider.dart` (2 providers) lack `.autoDispose`. They hold Supabase data in memory forever even when the screen is disposed.

- **auth_provider.dart:11** — `authServiceProvider` (Provider, no autoDispose)
- **auth_provider.dart:104** — `authNotifierProvider` (StateNotifierProvider, no autoDispose)
- **pos_providers.dart:6** — `posProductsProvider` (FutureProvider, no autoDispose)
- **pos_providers.dart:26** — `todayRevenueProvider` (FutureProvider, no autoDispose)
- **pos_providers.dart:64** — `manageProductsProvider` (FutureProvider, no autoDispose)
- **pos_providers.dart:83** — `operatorTransactionsProvider` (FutureProvider, no autoDispose)

Recommendation: add `.autoDispose` to all.

### HIGH-2: Duplicate Supabase queries — same data fetched separately
**admin_providers.dart:183-216** and **keuangan_providers.dart:233-266**
Both `adminStudentDetailProvider` and `keuanganStudentDetailProvider` execute identical queries:
```dart
from('profiles').select().eq('id', id).single()
from('students').select().eq('id', id).single()
from('transactions').select(...).eq('student_id', id).order(...).limit(10)
```
Same code, same table, same filters. Should be consolidated into a single shared provider family.

### HIGH-3: `operatorTransactionsProvider` re-fetches for any auth state change
**pos_providers.dart:83-101** — uses `ref.watch(authNotifierProvider)` which means every auth state change (even a `copyWith(isLoading: true)`) triggers a re-fetch of all transactions. Should use `ref.read` in the async function instead of `ref.watch` for the provider definition.

### HIGH-4: `adminDashboardProvider` silently returns incomplete data on error
**admin_providers.dart:102-111** — On catch, returns a `AdminDashboardData` with whatever partial values were computed before the error. The catch block should return a proper error state or rethrow, not silently serve stale partial data.

### HIGH-5: `adminFinanceDetailProvider` uses `.or()` with unvalidated profile name
**admin_providers.dart:363**
```dart
.or('actor_id.eq.$id,actor_name.eq.${profile['full_name']}')
```
At this point `profile` was fetched with `.single()` (which could have crashed). But SQL injection risk is low since Supabase's `.or()` is parameterized. However, if `full_name` contains special characters (e.g. `admin' --`), it could break the query syntax.

### HIGH-6: `globalRefreshKeyProvider` uses `ValueNotifier<int>` inside `StateProvider`
**app_providers.dart:187-188**
```dart
final globalRefreshKeyProvider = StateProvider<ValueNotifier<int>>((ref) => ValueNotifier(0));
```
This wraps a mutable `ValueNotifier` in an immutable `StateProvider`. `StateProvider` already provides change notification — wrapping `ValueNotifier` inside adds unnecessary complexity. If state is replaced (not mutated), it works; but the pattern is non-standard and error-prone.

### HIGH-7: Missing `Family` modifier on `todayRevenueProvider`
**pos_providers.dart:26** — `todayRevenueProvider` uses `ref.watch(authNotifierProvider)` to get `operatorId`. There's only ONE operator per session (the logged-in canteen cashier), so this is functional but fragile. If the app ever needs to show revenue for another operator, it must be refactored to a `.family` provider. This is a design limitation.

### HIGH-8: `posProductsProvider` watches auth state but doesn't invalidate on operator change
If the user logs out and a different operator logs in, the old cached product list persists until provider is disposed. Adding `.autoDispose` (HIGH-1) mitigates this.

---

## MEDIUM-SEVERITY ISSUES

### MEDIUM-1: `keuangan_providers.dart` uses `Map<String, dynamic>` returns instead of typed models
- **keuanganDashboardProvider** returns `Map<String, dynamic>` (line 12)
- **keuanganHistoryProvider** returns `List<Map<String, dynamic>>` (line 115)
- **keuanganReportProvider** returns `Map<String, dynamic>` (line 142)
- **keuanganParentsProvider** returns `List<Map<String, dynamic>>` (line 275)
- **keuanganStaffProvider** returns `List<Map<String, dynamic>>` (line 290)
- **adminSettingsProvider** returns `Map<String, dynamic>` (line 162)

These should return typed model classes for type safety and testability.

### MEDIUM-2: `nfc_payment_provider.dart` holds `Ref` reference (anti-pattern)
**nfc_payment_provider.dart:57**
```dart
class NfcPaymentNotifier extends StateNotifier<NfcPaymentState> {
  final Ref _ref;
```
Storing `Ref` in a StateNotifier is discouraged. The pattern works but couples the notifier to Riverpod's dependency injection. Using constructor injection for `SupabaseClient` is the idiomatic approach.

### MEDIUM-3: `siswaParentContactProvider` hardcodes fallback contact info
**siswa_providers.dart:106-107,115-117**
```dart
'email': parentProfile['email']?.toString() ?? 'budi.subarjo@gmail.com',
'phone': parentProfile['phone_number']?.toString() ?? '08123456789',
```
Returns fake/mock data when the DB query fails or parent record is missing. This could cause confusion (showing wrong phone/email in the UI).

### MEDIUM-4: No `ref.onDispose()` in stream providers
**app_providers.dart:168** — `networkStatusProvider` is a `StreamProvider` but has no `ref.onDispose()` call. While `StreamProvider` auto-closes streams when the provider is disposed (for autoDispose variants), this one is not `.autoDispose`.

### MEDIUM-5: `transactionTypesProvider` is hardcoded with no DB query
**shared_providers.dart:20-27** — Returns hardcoded list `['purchase', 'topup', 'refund']`. Not necessarily wrong, but the comment says "Hardcoded — DB only uses string types" which suggests DB types might change and this won't adapt.

### MEDIUM-6: Inconsistent `ref.read` vs `ref.watch` usage
- ✅ `pos_providers.dart` uses `ref.watch(authNotifierProvider)` for reactive refresh
- ❌ `shared_providers.dart:43` uses `ref.read(supabaseClientProvider)` instead of `ref.watch`
- ❌ `admin_providers.dart` uses `ref.read(supabaseClientProvider)` consistently (fine for client)
- ❌ `keuangan_providers.dart:15` uses `ref.read(authNotifierProvider).profile` instead of `ref.watch`

Using `ref.read` on auth state in providers means they won't re-fetch when the user logs out/in. This is intentional in some cases (dashboard fetches once) but inconsistent.

### MEDIUM-7: `appStateProvider` lacks `.autoDispose`
**app_providers.dart:158** — The `StateNotifierProvider` wrapping `AppStateNotifier` is not `.autoDispose`. The `_connectivitySub` stream subscription lives forever. While `dispose()` does cancel it, without `.autoDispose` the provider never gets disposed when all watchers are gone.

---

## LOW-SEVERITY ISSUES

### LOW-1: Weak `toString()` in `AuthState` — no meaningful representation
No `toString()` override on `AuthState` class — debugging state changes in logs requires inspecting each field separately.

### LOW-2: Missing `@immutable` on `CartState` and `NfcPaymentState`
`CartState` (cart_provider.dart:37) and `NfcPaymentState` (nfc_payment_provider.dart:20) are intended as immutable state but lack the `@immutable` annotation. `AppState` (app_providers.dart:12) does have it.

### LOW-3: `nfc_payment_provider.dart:153-168` — balance check happens in provider, not via RPC
The RPC `process_purchase` likely also checks balance server-side. Having the check in the provider is redundant and could cause UX inconsistency if the RPC has different logic.

### LOW-4: `currency_formatter.dart` imported but only used in one error message
**nfc_payment_provider.dart:143** — `CurrencyFormatter.format(dailyLimit)` — the import exists but `CurrencyFormatter` is only used in the daily limit error message.

---

## ROUTER AUDIT

### Route Heatmap

| Route | Constant | Navigated From | Count |
|-------|----------|----------------|-------|
| `/` (splash) | `AppRouter.splash` | — | 0 (initial) |
| `/login` | `AppRouter.login` | secure_entry_screen, admin_settings, splashes | 3 |
| `/welcome` | `AppRouter.studentWelcome` | splash, profile, login, parent_portal | 6 |
| `/student` | `AppRouter.studentHome` | splash, login, main_layout | 3 |
| `/student/history` | `AppRouter.studentHistory` | dashboard, main_layout | 2 |
| `/student/topup` | `AppRouter.studentTopUp` | dashboard | 1 |
| `/student/notifications` | `AppRouter.studentNotifications` | dashboard | 1 |
| `/parent` | `AppRouter.parentHome` | splash | 1 |
| `/parent/dashboard/:studentId` | `AppRouter.parentDashboard` | splash, login, portal | 3 |
| `/parent/topup/:studentId` | `AppRouter.parentTopUp` | dashboard | 1 |
| `/pos` | `AppRouter.posHome` | splash, login, main_layout, dashboard | 4 |
| `/pos/terminal` | `AppRouter.posTerminal` | home | 1 |
| `/pos/cart` | `AppRouter.posCart` | dashboard | 1 |
| `/pos/orders` | `AppRouter.posOrders` | home, main_layout | 2 |
| `/pos/products` | `AppRouter.posManageProducts` | main_layout | 1 |
| `/pos/products/form` | `AppRouter.posAddEditProduct` | manage_products | 2 |
| `/pos/sales` | `AppRouter.posHistorySales` | home, main_layout | 2 |
| `/admin` | `AppRouter.adminHome` | secure_entry, main_layout | 2 |
| `/admin/secure-entry` | `AppRouter.adminSecureEntry` | login, splash | 2 |
| `/admin/users` | `AppRouter.adminUsers` | main_layout | 1 |
| `/admin/users/student/:studentId` | (inline) | admin_users, admin_parent_detail | 2 |
| `/admin/users/merchant/:merchantId` | (inline) | admin_users | 1 |
| `/admin/users/finance/:officerId` | (inline) | admin_users | 1 |
| `/admin/users/parent/:parentId` | (inline) | admin_users | 1 |
| `/finance` | `AppRouter.financeHome` | splash, login, correction, topup | 4 |
| `/finance/students` | `AppRouter.studentWelcome` | users, main_layout | 2 |
| `/finance/students/:studentId` | (inline) | keuangan_students_screen, users_tabs | 2 |
| `/finance/users` | `AppRouter.financeUsers` | main_layout | 1 |
| `/finance/users/merchant/:merchantId` | (inline) | users_tabs | 1 |
| `/finance/users/parent/:parentId` | (inline) | users_tabs | 1 |
| `/finance/history` | `AppRouter.financeHistory` | dashboard, main_layout | 2 |
| `/finance/report` | `AppRouter.financeReport` | main_layout | 1 |
| `/finance/topup` | `AppRouter.financeTopUp` | (not found in search) | 0 |
| `/finance/correction` | `AppRouter.financeCorrection` | (not found in search) | 0 |
| `/finance/profile` | `AppRouter.financeProfile` | (not found in search) | 0 |
| `/finance/settings` | `AppRouter.financeSettings` | dashboard, main_layout | 2 |
| `/public` | `AppRouter.publicHome` | (not found in search) | 0 |
| `/public/menu` | `AppRouter.publicMenu` | public_home | 2 |
| `/public/info` | `AppRouter.publicInfo` | public_home | 1 |

**Most-frequently-navigated routes:**
1. `/welcome` — 6 navigation points
2. `/login` — 3 navigation points  
3. `/pos` — 4 navigation points
4. `/finance` — 4 navigation points
5. `/pos/sales` — 2, `/pos/orders` — 2, `/public/menu` — 2

### Router Issues

#### ROUTER-1 (HIGH): All navigation uses **hardcoded path strings** instead of route constants
**Every single** `context.go()` and `context.push()` call uses raw strings like `'/pos'`, `'/login'`, `'/admin/users'` instead of `AppRouter.posHome`, `AppRouter.login`, `AppRouter.adminUsers`.

If any route path changes, grep won't catch all occurrences. There are **86 hardcoded path strings** across 22 screen files.

#### ROUTER-2 (MEDIUM): Missing `StatefulShellRoute` — scroll position lost on tab switch
Uses `ShellRoute` for all tab-based layouts (siswa, kantin, admin, keuangan). `ShellRoute` recreates the child widget on every navigation, losing scroll position. Should use `StatefulShellRoute.indexedStack` or `StatefulShellRoute` to preserve state.

#### ROUTER-3 (MEDIUM): `parentReceipt` casts `state.extra` without null check
**app_router.dart:183**
```dart
ParentReceiptScreen(receiptData: state.extra as Map<String, dynamic>)
```
If `state.extra` is null, this crashes with a runtime type cast error.

#### ROUTER-4 (MEDIUM): `financeTopUp` and `financeCorrection` cast with nullable extra
**app_router.dart:385,392**
```dart
final student = state.extra as StudentWithProfile?;
return KeuanganTopupScreen(prefilledStudent: student);
```
Both accept nullable extra — this is correct in isolation, but there's no guard against navigating to these routes without the proper `extra` data, resulting in screens with null student info.

#### ROUTER-5 (LOW): `/pos/check-card` route is defined but no navigation found
`AppRouter.posCheckCard = '/pos/check-card'` is a fully defined route pointing to `CheckCardScreen`, but no `context.go()` or `context.push()` call to this path was found in any screen file. It's dead code unless navigated to from a widget not in the search scope.

---

## SECURITY CONCERNS

| # | Risk | Severity | Description |
|---|------|----------|-------------|
| S1 | **Hardcoded admin PIN fallback** | **CRITICAL** | `'123456'` PIN if DB query fails |
| S2 | **Simulated biometric bypass** | **CRITICAL** | Fake Face ID always succeeds |
| S3 | **No auth guards on routes** | **CRITICAL** | Direct URL access to any role |
| S4 | **Plaintext passwords** | **CRITICAL** | Stored and compared in plaintext |
| S5 | **No rate limiting on PIN entry** | **HIGH** | Infinite retries on admin PIN |
| S6 | **Profile-based fallback auth** | **HIGH** | By-passes Supabase Auth entirely, no JWT |
| S7 | **`.or()` filter with profile name** | **MEDIUM** | `adminFinanceDetailProvider` line 363, unescaped user input in filter |
| S8 | **No API key validation** | **LOW** | Supabase `anon key` is client-side, expected |
| S9 | **Fallback mock parent contact data** | **LOW** | Fake email/phone shown if DB error |

---

## CLEAN PROVIDERS (Zero Issues Found)

✅ **`cart_provider.dart`** — `CartNotifier`/`CartState` is clean, well-designed, uses proper Riverpod patterns, no leaks, no network calls, proper state immutability.

✅ **`public_providers.dart`** — Clean `.family` usage, proper error handling (no `.single()`), uses `.autoDispose`.

✅ **`shared_providers.dart`** — Well-structured, uses `.maybeSingle()` correctly (except in `currentUserProfileProvider` line 47 which fetches by auth user id which always exists). `studentByIdProvider` correctly uses `.maybeSingle()`.

---

## SUMMARY TABLE

| Severity | Count | Key Findings |
|----------|-------|-------------|
| **CRITICAL** | 6 | `.single()` crashes (12 spots), PIN fallback, fake biometric, no auth guards, plaintext passwords, missing stack traces |
| **HIGH** | 8 | Missing `autoDispose` (6 providers), duplicate queries, auth state re-fetch, silent partial data return, SQL-ish injection risk, ValueNotifier anti-pattern, missing Family, stale cache |
| **MEDIUM** | 7 | Untyped maps, Ref storage, hardcoded contact fallback, no onDispose, hardcoded types, inconsistent ref.read/watch, no autoDispose on appState |
| **LOW** | 4 | Missing toString, missing @immutable, redundant balance check, unused import |
| **ROUTER-MEDIUM** | 4 | Hardcoded strings (86), no StatefulShellRoute, extra null cast, nullable extra routes |
| **ROUTER-LOW** | 1 | Dead route `/pos/check-card` |

---

## RECOMMENDATIONS (Priority Order)

1. **P0** — Replace all `.single()` with `.maybeSingle()` + null checks in admin, parent, and keuangan providers.
2. **P0** — Implement real GoRouter auth redirect guards in `app_router.dart`.
3. **P0** — Remove plaintext password storage; use bcrypt or Supabase Auth exclusively.
4. **P0** — Remove hardcoded PIN fallback; fail closed (lock out) on DB error.
5. **P1** — Add `catch(e, st)` throughout with proper stack traces.
6. **P1** — Add `.autoDispose` to all FutureProvider and StateNotifierProvider declarations.
7. **P1** — Replace simulated biometric with `local_auth` package and platform biometric APIs.
8. **P2** — Add rate limiting / lockout on admin PIN entry.
9. **P2** — Consolidate duplicate `adminStudentDetailProvider` and `keuanganStudentDetailProvider`.
10. **P2** — Replace all hardcoded path strings with `AppRouter.*` constants.
