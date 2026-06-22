# Batch 4 — Final Polish Implementation Plan

> **Execution:** Parallel subagent batches (3 agents per batch, sequential batches)

**Goal:** Clean up remaining low-priority polish items — unused colors, Colors.white→AppColors, dart:io import, unused imports, commented debugPrint, duplicate GoogleFonts consolidation start.

**Status:** flutter analyze = 0 production errors. This is pure code quality & maintainability.

---

## Batch 4a — Quick Wins (3 agents parallel, ~5 min each)

### Task 4a.1: Remove 14 unused AppColors constants

**Objective:** Remove color constants from `app_colors.dart` that have 0 references across `lib/`

**Files:**
- Modify: `lib/core/constants/app_colors.dart`

**Unused colors to remove:**
- `primaryDark` (#0A5E5E) — 0 refs
- `darkTeal2` (#004D4D) — 0 refs
- `surfaceContainerHigh` (#FFFFFF) — 0 refs  
- `successGreenLight` (#E8F5E9) — 0 refs
- `errorRedLight` (#FFEBEE) — 0 refs
- `errorRed2` (#BA1A1A) — 0 refs
- `errorDark` (#93000A) — 0 refs
- `errorLightColor` (#FFDAD6) — 0 refs
- `warningYellow` (#FFA000) — 0 refs
- `warningYellowLight` (#FFF8E1) — 0 refs
- `grayLighter` (#F5F5F5) — 0 refs
- `textPrimary` (#1A1D1E) — 0 refs
- `textSecondary` (#6F7978) — 0 refs
- `outlineVariant` (#CAC4D0) — 0 refs

**Step 1:** Search `grep -rn "AppColors\.primaryDark\|AppColors\.darkTeal2\|..." lib/` to confirm zero refs  
**Step 2:** Remove each unused line from `app_colors.dart`  
**Step 3:** Run `flutter analyze` — expect 0 new issues

**Verification:** `flutter analyze` passes. File shrinks from 69→55 lines.

---

### Task 4a.2: Fix ~20 `Colors.white` → `AppColors.white`

**Objective:** Replace remaining direct `Colors.white` references with `AppColors.white`

**Files:**
- `lib/features/public/screens/public_home_screen.dart`
- `lib/features/public/screens/public_menu_screen.dart`
- `lib/features/public/screens/public_school_info_screen.dart`
- `lib/features/auth/screens/login_screen.dart`
- `lib/core/theme/app_theme.dart`
- `lib/features/kantin/screens/cart_screen.dart`
- `lib/features/admin/screens/secure_entry_screen.dart`

**Step per file:** `Colors.white` → `AppColors.white` (keep `Colors.transparent` as-is)

**Verification:** `flutter analyze` passes.

---

### Task 4a.3: Fix dart:io import + remove self-referential barrel comment + remove unused dart:async

**Objective:** Fix web-incompatible import and clean up barrel file noise

**Files:**
- `lib/features/kantin/screens/product_form_screen.dart:1` — `import 'dart:io' show File;` should be conditionally imported or removed if File is unused
- `lib/core/models/models.dart:5` — commented-out self-import
- `lib/features/keuangan/screens/keuangan_correction_screen.dart:1` — unused `dart:async`
- `lib/features/keuangan/screens/keuangan_topup_screen.dart:1` — unused `dart:async`

**Step 1:** Check if `File` is actually used in product_form_screen.dart — if not, remove import  
**Step 2:** Remove commented self-import from models.dart  
**Step 3:** Check if `dart:async` is actually used in correction + topup screens

**Verification:** `flutter analyze` passes.

---

## Batch 4b — Code Quality (3 agents parallel, ~10 min each)

### Task 4b.1: Remove commented-out debugPrint statements

**Objective:** Clean up ~25 lines of dead commented-out debug code

**Files:**
- `lib/features/auth/providers/auth_provider.dart` (lines ~92, 96)
- `lib/core/services/storage_service.dart` (lines ~26, 85)
- `lib/core/providers/shared_providers.dart` (commented debugPrint)
- `lib/features/kantin/providers/pos_providers.dart` (commented debugPrint)
- `lib/features/siswa/screens/siswa_notifications_screen.dart` (~line 23)
- `lib/core/providers/app_providers.dart` — already deleted, skip

**Step per file:** Remove lines matching `// debugPrint(`

**Verification:** `flutter analyze` passes.

---

### Task 4b.2: Fix `.single()` → `.maybeSingle()` remaining instances

**Objective:** Find and fix any remaining `.single()` calls that should be `.maybeSingle()`

**Step 1:** `grep -rn '\.single()' lib/ --include="*.dart"` to find all usages  
**Step 2:** For each, check if the query might return null. If so, change to `.maybeSingle()` with null handling

**Verification:** `flutter analyze` passes. All `.single()` calls are either safe (guaranteed record) or converted.

---

### Task 4b.3: Create `AppTextStyles` for GoogleFonts consolidation (start)

**Objective:** Create foundation file for consolidating duplicate GoogleFonts.beVietnamPro styles

**Create:** `lib/core/theme/app_text_styles.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Headings
  static TextStyle get h1 => GoogleFonts.beVietnamPro(
    fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary,
  );
  static TextStyle get h2 => GoogleFonts.beVietnamPro(
    fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary,
  );
  static TextStyle get h3 => GoogleFonts.beVietnamPro(
    fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary,
  );

  // Body
  static TextStyle get bodyLarge => GoogleFonts.beVietnamPro(
    fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary,
  );
  static TextStyle get bodyMedium => GoogleFonts.beVietnamPro(
    fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary,
  );
  static TextStyle get bodySmall => GoogleFonts.beVietnamPro(
    fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
  );

  // Labels
  static TextStyle get labelLarge => GoogleFonts.beVietnamPro(
    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static TextStyle get labelSmall => GoogleFonts.beVietnamPro(
    fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  // Buttons
  static TextStyle get button => GoogleFonts.beVietnamPro(
    fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.white,
  );

  // Numbers (monospace for currency)
  static TextStyle get currency => GoogleFonts.beVietnamPro(
    fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary,
  );
}
```

DO NOT migrate existing files — just create the file so future work can reference it.

**Verification:** `flutter analyze` passes (file is created but not yet referenced).

---

## Execution Flow

```
Batch 4a ─┬─ Agent 1: Remove unused AppColors
          ├─ Agent 2: Colors.white → AppColors.white  
          └─ Agent 3: dart:io + barrel + unused imports
               ↓
Batch 4b ─┬─ Agent 1: Remove commented debugPrint
          ├─ Agent 2: Fix remaining .single() calls
          └─ Agent 3: Create AppTextStyles foundation
               ↓
         flutter analyze → VERIFY 0 errors
               ↓
         DONE ✅
```
