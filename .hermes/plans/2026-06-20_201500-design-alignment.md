# Design Alignment Plan — Clone → Original (100% Visual Match)

> **For Hermes:** Execute fase demi fase via delegate_task batch. Tiap batch verify `flutter analyze`.
>
> **Goal:** Samakan 100% design visual, layout, font, dan animasi clone dengan original di `C:\Work\Project PKL\sistem kantin digital`.
>
> **Constraint KRITIS:** Jangan revert improvement keamanan (auth guards, RBAC, RPC, RLS, AppStrings, type safety). Hanya ubah VISUAL.
>
> **Prinsip:** Original sebagai reference. Clone sudah banyak improvement (keamanan, error handling, caching). Kita hanya "cat ulang" visualnya, jangan bongkar arsitektur.

---

## Ringkasan Audit — Perbedaan Visual yang Harus Diperbaiki

| # | Area | Original | Clone | Prioritas |
|---|------|----------|-------|-----------|
| 1 | **Font** | `Inter` | `Be Vietnam Pro` | 🔴 **High** — paling kelihatan |
| 2 | **Kantin bottom nav** | `BottomNavigationBar` standar | Custom chip-style nav | 🔴 **High** — beda total |
| 3 | **Gray400 hex** | `0xFFBDC9C8` | `0xFFBFC8C8` (beda 2pt) | 🟡 Medium |
| 4 | **Extra colors** | 30 colors | 69 colors (35 extra) | 🟢 Low — gak ganggu visual |
| 5 | **Kantin nav route** | `/pos/check-card` | `/pos/orders` | 🟡 Medium — functional diff |
| 6 | **Error states** | Plain `Text` | Column + icon + retry | 🟢 **JANGAN revert** (improvement) |
| 7 | **Caching** | `Image.network` | `CachedNetworkImage` | 🟢 **JANGAN revert** (improvement) |
| 8 | **Locale** | No locale | `'id_ID'` di DateFormat | 🟢 **JANGAN revert** (improvement) |
| 9 | **Auth guards** | None | Full RBAC | 🟢 **JANGAN revert** (security) |
| 10 | **Animasi** | Tidak ada animasi khusus | Sama — tidak ada | 🟢 Sama |

**Sebagian besar screen sudah identik secara layout.** Perubahan antara original dan clone mayoritas adalah:
- Refaktor `Color(0x...)` → `AppColors.*` (visual sama)
- Refaktor string hardcoded → `AppStrings.*` (visual sama)
- Penambahan error handling, caching, locale (improvement, jangan di-revert)

---

## Fase 1: 🔴 Font — Inter → Be Vietnam Pro

### Task 1.1: Ganti font di app_theme.dart

**File:** `lib/core/theme/app_theme.dart`

**Aksi:**
- `GoogleFonts.beVietnamProTextTheme()` → `GoogleFonts.interTextTheme()`
- Semua `GoogleFonts.beVietnamPro(...)` → `GoogleFonts.inter(...)`
- `labelStyle`, `hintStyle`, `textStyle` di button: Be Vietnam Pro → Inter

```dart
// Before
textTheme: GoogleFonts.beVietnamProTextTheme().copyWith(
  titleLarge: GoogleFonts.beVietnamPro(...)
)

// After
textTheme: GoogleFonts.interTextTheme().copyWith(
  titleLarge: GoogleFonts.inter(...)
)
```

### Task 1.2: Cek Google Fonts import di pubspec

**File:** `pubspec.yaml`

Pastikan `google_fonts` masih support `Inter`. Inter adalah font default pub.dev — gak perlu asset tambahan.

### Task 1.3: flutter analyze

```bash
cd ~/projects/kantin-digital && flutter analyze
```
Expected: 0 error, 0 warning.

---

## Fase 2: 🔴 Kantin Bottom Nav — Revert ke Standard BottomNavigationBar

### Task 2.1: Analisis original bottom nav

**File original:** `C:\Work\Project PKL\sistem kantin digital\lib\features\kantin\widgets\kantin_main_layout.dart`

Original menggunakan `BottomNavigationBar` standar Flutter:
```dart
BottomNavigationBar(
  currentIndex: _selectedIndex,
  onTap: _onItemTapped,
  type: BottomNavigationBarType.fixed,
  backgroundColor: AppColors.cardBackground,
  selectedItemColor: AppColors.primary,
  unselectedItemColor: AppColors.textGray,
  items: const [
    BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: 'Beranda'),
    BottomNavigationBarItem(icon: Icon(CupertinoIcons.creditcard), label: 'Cek Kartu'),
    BottomNavigationBarItem(icon: Icon(CupertinoIcons.tray_full), label: 'Pesanan'),
    BottomNavigationBarItem(icon: Icon(CupertinoIcons.time), label: 'Riwayat'),
  ],
)
```

### Task 2.2: Ubah clone nav

**File clone:** `lib/features/kantin/widgets/kantin_main_layout.dart`

**Aksi:**
- Hapus `_buildBottomNavItem()` custom widget
- Ganti `Row(...)` dengan `BottomNavigationBar` standar
- Ikon: pakai `CupertinoIcons` (seperti original)
- Item: `Beranda`, `Cek Kartu`, `Pesanan`, `Riwayat`
- Warna: `selectedItemColor: AppColors.primary`, `unselectedItemColor: AppColors.textGray`
- Route mapping: sesuai original (`/pos/check-card` → index 1, `/pos/orders` → index 2)

### Task 2.3: Test & verify

```bash
flutter analyze
```
Expected: 0 error.

---

## Fase 3: 🟡 Minor Fixes

### Task 3.1: Gray400 hex color

**File:** `lib/core/constants/app_colors.dart`

Original menggunakan `Color(0xFFBDC9C8)` untuk input border/hint di login screen.

Lihat apakah `gray400` (`0xFFBFC8C8`) dipakai DI LUAR login screen. Kalau cuma di login:
- Hapus `gray400` atau
- Tambah constant baru: `static const Color inputBorder = Color(0xFFBDC9C8);`

Atau alternatif: ubah `gray400` jadi `0xFFBDC9C8` — sama-sama gray, beda 2px gak kelihatan.

### Task 3.2: Cek perbedaan route super admin

**File:** `lib/features/auth/screens/login_screen.dart`

Original: `context.go('/admin/secure-entry')`
Clone: `context.go('/admin')`

Ini kemungkinan functional change dari route restructuring. Clarify dengan user.

---

## Agent Breakdown

### Batch 1 — Font (3 agent paralel)

| Agent | Task | File Target |
|-------|------|-------------|
| **A1** | Ganti font di `app_theme.dart` | `lib/core/theme/app_theme.dart` |
| **A2** | Cari semua `GoogleFonts.beVietnamPro` di file LAIN | `lib/**/*.dart` — scan + ganti ke `GoogleFonts.inter` |
| **A3** | Cek pubspec.yaml + verify font tersedia | `pubspec.yaml` |

```
A1 ─── app_theme.dart (font theme)
A2 ─── scan & replace beVietnamPro → inter di semua file
A3 ─── pubspec.yaml check

    ─── all parallel ───
           ▼
    flutter analyze ✅
```

### Batch 2 — Bottom Nav (1 agent)

| Agent | Task | File Target |
|-------|------|-------------|
| **B1** | Revert kantin bottom nav ke standard BottomNavigationBar | `features/kantin/widgets/kantin_main_layout.dart` |

```
B1 ─── kantin_main_layout.dart
           ▼
    flutter analyze ✅
```

### Batch 3 — Minor (1 agent)

| Agent | Task | File Target |
|-------|------|-------------|
| **C1** | Gray400 fix + route check | `app_colors.dart`, `login_screen.dart` |

---

## Timeline

| Batch | Tasks | Estimasi |
|-------|-------|----------|
| B1 — Font | 3 agent paralel | ~10 menit |
| B2 — Bottom Nav | 1 agent | ~8 menit |
| B3 — Minor | 1 agent | ~5 menit |

**Total: <30 menit** dengan multi-agent.

---

## Hal yang TIDAK Perlu Diubah (JANGAN DI-SENTUH)

| Improvement | Alasan |
|-------------|--------|
| Auth guards + RBAC router | Keamanan |
| RPC + RLS system | Keamanan |
| Password bcrypt | Keamanan |
| AppStrings migration | Maintainability |
| flutter_secure_storage | Keamanan |
| Error boundary | UX |
| EmptyStateWidget | UX |
| CachedNetworkImage | Performance |
| Error states (icon + retry) | UX |
| Locale 'id_ID' | UX |
| Split files <800 lines | Maintainability |
| double→int refactor | Correctness |
