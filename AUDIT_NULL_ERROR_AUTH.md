# Audit: Null Error + User Tidak Muncul

## Tanggal: 2026-06-21
## Investigator: researcher agent

---

## 📋 Ringkasan Temuan

| # | Issue | Severity | Root Cause |
|---|-------|----------|------------|
| 1 | `TypeError: null: type 'Null' is not a subtype of type 'String'` | **CRITICAL** | `UserProfile.fromJson` crash saat `json['id'] == null` |
| 2 | "Pengguna tidak tersedia semua" (user list kosong) | **CRITICAL** | Fallback auth path gagal bikin JWT session → query sebagai anon → ditolak RLS |
| 3 | "Signing out user" di log | **MEDIUM** | Efek samping dari fallback path; validasi gagal → signOut dipanggil |

---

## 🔍 Detail Root Cause #1: Null Error di UserProfile.fromJson

### Lokasi
**File:** `lib/core/models/user_profile.dart` — line 35

```dart
factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,    // ← CRASH: jika json['id'] == null
      ...
    );
}
```

### Skenario Crash

Beberapa detail provider (admin, keuangan) melakukan query `profiles` sebagai **anonymous user** (karena JWT session tidak ada). Query ditolak RLS, return `null`. Lalu code substitusi empty `{}`:

**File:** `lib/features/admin/providers/admin_providers.dart` — line 227
```dart
'profile': profile ?? <String, dynamic>{},    // ← empty map!
```

Lalu di `admin_student_detail.dart`:
```dart
profile: profileData is Map<String, dynamic>
    ? UserProfile.fromJson(profileData)    // ← {} diteruskan
    : const UserProfile(id: ''),
```

Karena `profileData` adalah `Map<String, dynamic>` (empty `{}`), ia masuk ke cabang `true` → `UserProfile.fromJson({})` → `json['id']` adalah `null` → **crash**.

### Affected Callers (ALL rentan)
| Caller | File | Risiko |
|--------|------|--------|
| `adminStudentDetailProvider` | admin_providers.dart:226 | `profile ?? {}` → crash |
| `adminParentDetailProvider` | admin_providers.dart:258 | `profile ?? {}` → crash |
| `adminFinanceDetailProvider` | admin_providers.dart:383 | `profile ?? {}` → crash |
| `adminMerchantDetailProvider` | admin_providers.dart:340 | `profile ?? {}` → crash |
| `adminUsersProvider` | admin_providers.dart:144 | Aman (empty list) |
| `keuanganStudentDetailProvider` | keuangan_providers.dart:275 | `profile ?? {}` → crash |
| `operator_list_tab.dart` | line 34 | Aman (empty list) |
| `parent_list_tab.dart` | line 29 | Aman (empty list) |
| `currentUserProfileProvider` | shared_providers.dart:56 | Aman (null check) |
| `siswa_dashboard_screen.dart` | line 339 | Aman (null check) |

---

## 🔍 Detail Root Cause #2: Fallback Auth → No JWT Session → RLS Block

### Lokasi
**File:** `lib/features/auth/services/auth_service.dart` — lines 104-172

### Alur

```
signIn() dipanggil
  │
  ├─ Step 2: Coba signInWithPassword() 
  │    └─ AuthException (password beda, server down, dll)
  │         └─ authSessionEstablished = FALSE  ← TIDAK ADA JWT SESSION
  │
  └─ Step 4: Fallback — verify_password RPC
       └─ Berhasil → profile didapat dari RPC response
            └─ TAPI authSessionEstablished tetap FALSE
                 └─ _client.auth.currentUser = null
                      └─ Semua query berikutnya berjalan sebagai ANON
```

### Dampak

Setelah login via fallback path, semua query `profiles` sebagai anon di-*block* oleh RLS:

```sql
-- Migration 0016: HAPUS anon SELECT dari profiles (line 35-36)
DROP POLICY IF EXISTS "Semua user anon dapat membaca data profil"
    ON public.profiles;

-- Hanya ada policy untuk authenticated:
CREATE POLICY "Semua user terautentikasi dapat membaca data profil"
    ON public.profiles FOR SELECT TO authenticated USING (true);
```

**Akibat:**
- `adminUsersProvider` → query profiles sebagai anon → return `[]` → "Tidak ada pengguna ditemukan."
- `keuanganStaffProvider` → query profiles sebagai anon → return `[]` → tampil kosong
- `keuanganParentsProvider` → query profiles sebagai anon → return `[]` → tampil kosong

### Verifikasi: Query yang bermasalah

Semua query di provider yang menggunakan `client.from('profiles').select(...)` akan gagal:

| Provider | Query | Role terpakai | RLS Result |
|----------|-------|--------------|------------|
| `adminUsersProvider` | `profiles.select('id,full_name,...')` | anon | ❌ empty list |
| `keuanganStaffProvider` | `profiles.select('...').eq('role','petugas_kantin')` | anon | ❌ empty list |
| `keuanganParentsProvider` | `profiles.select('...').eq('role','parent')` | anon | ❌ empty list |
| `keuanganStudentsProvider` | `profiles.select('...').eq('role','student')` | anon | ❌ empty list |
| `adminDashboardProvider` | `profiles.select('id')` | anon | ❌ userCount = 0 |

---

## 🔍 Detail Root Cause #3: Sign Out Log

### Lokasi — 3 titik signOut()

**1. `auth_service.dart` line 175, 183, 191:**
```dart
if (authSessionEstablished) await _client.auth.signOut();
```
Dipanggil saat validasi gagal (role mismatch, profile null) **HANYA JIKA** primary auth path sukses.

**2. `auth_service.dart` line 239-243:**
```dart
Future<void> signOut() async {
    _currentProfile = null;
    await SecureSessionService.clearSession();
    try { await _client.auth.signOut(); } catch (_) {}
}
```
Dipanggil saat user explicit logout.

**3. Supabase internal:** Jika ada session yang expired/tidak valid, Supabase bisa auto sign-out.

**Skenario paling mungkin untuk log error:** Saat fallback path sukses, aplikasi jalan dengan `isAuthenticated: true` tapi tanpa JWT. Kemudian:
- `adminUsersProvider` gagal (RLS block)
- Error ditangkap sebagai `error: (err, stack)` 
- User klik retry → invalidate → gagal lagi
- Mungkin ada bug di screen yang manggil `signOut()` sebagai error recovery

---

## 💡 Rekomendasi Fix

### Fix #1 (WAJIB — Paling Kritis)
**Buat JWT session setelah RPC fallback berhasil**

Di `auth_service.dart`, setelah fallback path sukses (line ~167), tambahkan:

```dart
if (!authSessionEstablished) {
    // Coba login via Auth setelah dapat email dari RPC
    try {
        await _client.auth.signInWithPassword(
            email: resolvedEmail,
            password: password,
        );
        authSessionEstablished = true;
    } catch (_) {
        // Jika Auth masih gagal, set session manual via admin API
        // atau lanjutkan dengan mode "limited" (hanya RPC queries)
    }
}
```

### Fix #2 (WAJIB — Safety Net)
**UserProfile.fromJson: null-safe id**

```dart
factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',   // ← null-safe
      ...
    );
}
```

### Fix #3 (SARAN)
**Detail providers: jangan pass empty map ke fromJson**

Di semua detail provider (`adminStudentDetailProvider`, dll), ubah:
```dart
'profile': profile ?? <String, dynamic>{},
```
Menjadi:
```dart
'profile': profile is Map<String, dynamic> && profile.isNotEmpty
    ? profile
    : null,
```
Dan di model (admin_student_detail.dart dll) pastikan null handling:
```dart
profile: profileData is Map<String, dynamic> && profileData.isNotEmpty
    ? UserProfile.fromJson(profileData)
    : const UserProfile(id: ''),
```

### Fix #4 (MITIGASI — Jika Fix #1 Tidak Memungkinkan)
**Tambah anon SELECT policy untuk profiles (terbatas)**

```sql
CREATE POLICY "Allow anon read limited profiles" ON public.profiles
    FOR SELECT TO anon
    USING (true)
    -- Hanya return kolom non-sensitif (fix kolom SELECT di query)
```
⚠️ Risiko: Ekspos data profil ke publik. Hanya sebagai opsi terakhir.

---

## 📊 Prioritas Eksekusi

1. **Fix #1** — Establish JWT session after fallback auth → **coder**
2. **Fix #2** — Null-safe UserProfile.fromJson → **coder**
3. **Fix #3** — Detail providers null handling → **coder**
4. Regression test → **tester**
5. Review → **reviewer**
