# Final Polish — Kantin Digital Production Grade

> **For Hermes:** Execute fase demi fase via delegate_task batch (3 paralel per batch).
>
> **Goal:** Bawa Kantin Digital dari 85/100 → 98/100 production-ready. Fokus ke stabilitas, konsistensi tipe data, dan error handling.
>
> **Prinsip:** Kerjakan per task, `flutter analyze` setelah tiap fase. Tidak ada skip YOLO.

---

## Fase 1: 🔴 Fix `double → int` untuk Semua Price/Amount

**Akar masalah:** DB udah BIGINT via migrasi 0019, tapi 4 model Dart masih `double`. Floating-point berbahaya buat duit.

### Task 1.1: Refactor `Product.price` → int

**Files:**
- Modify: `lib/models/product.dart`

**Action:**
- `price: double` → `int`
- Ubah konstruktor accept `int` (dari `double`)
- Ubah `double.tryParse(...)` → `int.tryParse(...)` di factory `fromJson`
- Hapus `.replaceAll('.00', '')` — gak perlu lagi

```dart
// Before
final double price;

// After
final int price;

// fromJson
price: int.tryParse(json['price']?.toString() ?? '0') ?? 0,
```

### Task 1.2: Refactor `Transaction.totalAmount` → int

**Files:**
- Modify: `lib/models/transaction.dart`

- `totalAmount: double` → `int`
- Update `fromJson`
- Update getter `formattedTotalAmount`
- Update `formattedTotalAmount` di display (kalau panggil CurrencyFormatter udah aman — dia accept `num`)

### Task 1.3: Refactor `TransactionItem.unitPrice` dan `totalPrice` → int

**Files:**
- Modify: `lib/models/transaction_item.dart`

- `unitPrice: double` → `int`
- `totalPrice` getter: `quantity * unitPrice` — hasilnya `int` otomatis
- Update `fromJson`

### Task 1.4: Refactor `OperatorTransaction.totalAmount` → int

**Files:**
- Modify: `lib/models/operator_transaction.dart`

- `totalAmount: double` → `int`
- Update `fromJson`

### Task 1.5: Fix semua call site (provider, screen)

**Files likely affected:**
- `lib/providers/transaction_providers.dart`
- `lib/features/keuangan/screens/sales_history_screen.dart`
- `lib/features/kantin/screens/cart_screen.dart`
- `lib/features/kantin/screens/product_form_screen.dart`
- `lib/features/siswa/screens/siswa_dashboard_screen.dart`
- `lib/features/parent/screens/parent_dashboard_screen.dart`

**Action:** Cari semua reference ke `price`, `totalAmount`, `unitPrice` yang dulu `double` sekarang jadi `int`. Pastikan gak ada casting `as double` atau operasi yang expect `double`.

### Task 1.6: Audit `process_purchase`, `process_refund` — pastikan call site kirim int

**Files:**
- Cek call ke RPC `process_purchase` dan `process_refund` di provider/screen
- Pastikan argumen `p_amount` dikirim sebagai `int`, bukan `double`

### Task 1.7: flutter analyze — verifikasi

```bash
cd ~/projects/kantin-digital
flutter analyze
```

Expected: 0 error, 0 warning.

---

## Fase 2: 🔴 Error Boundary + Graceful Error Handling

### Task 2.1: Custom ErrorWidget di main.dart

**Files:**
- Modify: `lib/main.dart`

**Action:** Pasang `ErrorWidget.builder` kustom di `main()` agar error gak nampilin red screen of death ke user.

```dart
ErrorWidget.builder = (FlutterErrorDetails details) {
  return Material(
    color: Colors.white,
    child: Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            SizedBox(height: 16),
            Text(
              'Terjadi kesalahan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Silakan tutup dan buka kembali aplikasi',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    ),
  );
};
```

### Task 2.2: runZonedGuarded untuk global catch

**Files:**
- Modify: `lib/main.dart`

**Action:** Bungkus `runApp` dengan `runZonedGuarded` + log ke debug console (gak bocorin stack ke prod).

```dart
runZonedGuarded(() {
  runApp(const KantinDigitalApp());
}, (Object error, StackTrace stack) {
  debugPrint('Unhandled error: $error');
  // Di production: kirim ke Supabase audit_log nanti
});
```

### Task 2.3: Safe API call wrapper (opsional)

**Files:**
- Create: `lib/core/utils/safe_api_call.dart` (kalo mau reusable)

Atau cukup pastikan tiap provider punya `error` state yang di-render sebagai UI friendly (udah ada pattern `AsyncValue.error` di Riverpod).

---

## Fase 3: 🟡 AppStrings — Bulk Migrate 15 String Paling Sering

### Task 3.1: Tambah konstanta baru ke AppStrings

**Files:**
- Modify: `lib/core/constants/app_strings.dart`

Tambah konstanta yang paling sering dipakai tapi belum ada:

```dart
// ===== DIALOG =====
static const String titleDetail = 'Detail';
static const String titleConfirmation = 'Konfirmasi';
static const String labelYes = 'Ya';
static const String labelNo = 'Tidak';

// ===== TRANSACTION =====
static const String labelTransaction = 'Transaksi';
static const String labelFullName = 'Nama Lengkap';

// ===== ACTION =====
static const String buttonAdd = 'Tambah';
static const String buttonSelect = 'Pilih';
static const String buttonEdit = 'Edit';

// ===== STATUS =====
static const String labelFailed = 'Gagal';
static const String labelLoadingData = 'Memuat data...';
```

### Task 3.2: Replace 5 string terbanyak via sub-agent

**String target (by frequency):**
1. `'Gagal'` → `AppStrings.labelFailed` (81 occurrences)
2. `'Memuat'` / `'Memuat data'` → `AppStrings.labelLoadingData` (36)
3. `'Tambah'` → `AppStrings.buttonAdd` (19)
4. `'Detail'` → `AppStrings.titleDetail` (16)
5. `'Pilih'` → `AppStrings.buttonSelect` (15)

**Approach:** Gunakan 2 sub-agent paralel:
- Agent A: ganti 'Gagal' + 'Memuat' di semua file
- Agent B: ganti 'Tambah' + 'Detail' + 'Pilih' di semua file

**Catatan:** Hati-hati dengan case-sensitive dan konteks — jangan replace string yang ada di dalam komentar, debugPrint, atau SQL.

### Task 3.3: Replace sisa string (konfirmasi, Ya, Tidak, Transaksi)

String secondary:
- `'Konfirmasi'` (4) → `AppStrings.titleConfirmation`
- `'Ya'` (0 — tapi sering di dialog) → `AppStrings.labelYes`
- `'Tidak'` (3) → `AppStrings.labelNo`
- `'Transaksi'` → `AppStrings.labelTransaction`

1 sub-agent.

### Task 3.4: Verifikasi — tidak ada string baru yang corrupt

```bash
cd ~/projects/kantin-digital && flutter analyze
```

Expected: 0 error, 0 warning.

---

## Fase 4: 🟢 Production Readiness — Missing Patterns

### Task 4.1: Connectivity handling

**Files:**
- Create: `lib/core/services/connectivity_service.dart`

**Approach:** Bikin service sederhana tanpa package pihak ketiga — cukup wrapper yang nge-trigger state Riverpod pas offline.

Implementation minimal:
```dart
// connectivity_service.dart
// Observasi: Flutter default connectivity detection butuh package 'connectivity_plus'
// Alternatif: wrap fetch API dengan try-catch + timeout, render offline state di UI
```

**Lebih praktis:** Pastikan semua fetch di provider Riverpod punya `AsyncValue.error` handler yang nampilin "Tidak ada koneksi internet" daripada crash. Ini sudah sebagian besar terpenuhi karena Riverpod + AsyncValue.

Yang kurang: khusus screen tanpa state (static data dari lokal) — tambah try-catch manual.

### Task 4.2: Reusable EmptyStateWidget

**Files:**
- Create: `lib/core/widgets/empty_state_widget.dart`

```dart
class EmptyStateWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final Widget? action;

  // Standard empty state yang bisa dipakai di semua screen
}
```

- Replace 6+ inline empty state yang ada dengan `EmptyStateWidget`

### Task 4.3: Loading skeleton (Shimmer)

**Files:**
- Tidak perlu buat dari nol — cari package `shimmer` di pubspec.yaml atau flutter_cached

Alternatif: ganti beberapa `CupertinoActivityIndicator` kritis dengan skeleton sederhana (Container abu-abu animated). Fokus ke screen utama: siswa dashboard, admin dashboard, POS screen.

### Task 4.4: Pagination untuk list data besar

**Files yang perlu:**

Untuk data yang bisa besar:
- `keuangan_students_screen.dart` — hundreds of students
- `admin_audit_log_screen.dart` — audit log grows unbounded
- `siswa_history_screen.dart` — transaction history

**Approach:** ScrollController + load more di data providers. Tapi **skip for now** — ini refactor besar yang perlu arsitektur pagination di provider layer. Save untuk v2.

---

## Fase 5: 🟡 Split 2 File >800 Lines

### Task 5.1: Split `keuangan_users_tabs.dart` (829 lines)

**Approach:** Ekstrak widget-widget yang berdiri sendiri:
- `UserListTab` (tab siswa)
- `OperatorListTab` (tab operator)
- `ParentListTab` (tab orang tua)

Ekstrak ke file terpisah di `lib/features/keuangan/widgets/`.

### Task 5.2: Split `admin_settings_screen.dart` (804 lines)

**Approach:** Ekstrak:
- `SettingSectionWidget` — grup setting per kategori
- `SettingTileWidget` — tile individual
- Masing-masing ke `lib/features/admin/widgets/`

---

## Fase 6: 🟢 Minor Fixes

### Task 6.1: Fix `student_welcome_screen.dart:87` — guard _welcomeMessages[0]

```dart
// Before
_welcomeMessages[0]

// After
_welcomeMessages.isNotEmpty ? _welcomeMessages[0] : 'Halo!'
```

### Task 6.2: Fix manual Rupiah formatting

**Files:**
- `lib/features/admin/screens/admin_merchant_detail_screen.dart` (lines 68-72)
- `lib/features/kantin/screens/product_form_screen.dart` (line 41)

Ganti dengan `CurrencyFormatter.format()`.

### Task 6.3: Hapus hardcoded placeholder dashboard

**Files:**
- `lib/features/admin/screens/admin_dashboard_screen.dart` (line 217, 531-535)

Ganti `'42.5K'`, `'42ms'`, `'12%'`, `'99.8%'` dengan `0` atau null state yang jelas.

---

## Timeline Estimasi

| Fase | Tasks | Estimasi | Via |
|------|-------|----------|-----|
| **Fase 1** — double → int | 7 tasks | ~30 menit | 3 agent paralel + verify |
| **Fase 2** — Error boundary | 3 tasks | ~15 menit | 1 agent |
| **Fase 3** — AppStrings bulk | 4 tasks | ~45 menit | 3 agent paralel (batch 1) + verify |
| **Fase 4** — Production readiness | 4 tasks | ~40 menit | 2 agent + manual |
| **Fase 5** — Split files | 2 tasks | ~20 menit | 2 agent paralel |
| **Fase 6** — Minor fixes | 3 tasks | ~15 menit | 1 agent |

**Total: ~2.5 jam** — dengan multi-agent, real-time bisa **<1 jam**.

---

## Risiko & Catatan

1. **Fase 1 (double→int):** Pastikan gak ada screen yang submit `double` ke RPC — RPC udah expect BIGINT. Kalau salah kirim `double`, Supabase reject dengan error.
2. **Fase 3 (AppStrings):** Hati-hati dengan string di komentar, log, atau SQL literal — jangan di-replace. Agent perlu konteks file.
3. **Fase 4 (Pagination):** SKIP untuk sekarang — ini refactor provider arsitektur yang gak bisa setengah-setengah.
4. **Connectivity:** Tidak perlu `connectivity_plus` package — cukup try-catch dengan timeout + asyncValue error state yang udah ada.
5. **`flutter analyze` WAJIB** setelah tiap fase — jangan lanjut ke fase berikutnya kalau masih ada error.

---

## Execution Strategy

```
Batch 1 (paralel): Fase 1.1–1.4 (4 model → int) 
        + Task 2.1 (ErrorWidget di main)
        
Verify: flutter analyze

Batch 2: Fase 1.5 (call site) + Task 6.1 (welcome guard)
        + Task 6.2 (manual formatting)

Verify: flutter analyze

Batch 3: Fase 3.1 + 3.2 (AppStrings — 2 agent paralel)

Verify: flutter analyze

Batch 4: Fase 3.3 (sisa AppStrings) + Fase 4.1 (connectivity)
        + Fase 4.2 (EmptyStateWidget)

Verify: flutter analyze

Batch 5: Fase 5.1 + 5.2 (split files — 2 agent paralel)

Verify: flutter analyze

Batch 6: Fase 4.3 (shimmer) + Fase 6.3 (hardcoded placeholder)

Verify: flutter analyze FINAL
```

**Total:** 6 batch × ~3 agent paralel = **cepat banget**. Siap? 🚀
