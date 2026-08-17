import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/theme/hallmark_color_scheme.dart';
import 'package:kantin_digital/core/theme/hallmark_typography.dart';

/// MASTER DARK MODE DESIGN SYSTEM — Applied 2026 (Hallmark Anti-AI-Slop Enhanced)
/// Premium dark theme: layered surfaces, soft teal accent, WCAG-AA typography.
class AppTheme {
  AppTheme._();

  // ─────────────────────────────────────────────────────────────────────────
  // LIGHT THEME (Hallmark Enhanced)
  // ─────────────────────────────────────────────────────────────────────────

  static ThemeData get lightTheme {
    final colors = HallmarkColorScheme.light();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: colors.surfaceBase,
      extensions: [colors],
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.brandPrimary,
        primary: colors.brandPrimary,
        secondary: colors.brandAccent,
        surface: colors.surfaceContainer,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: HallmarkTypography.displayL1(colors.textPrimary),
        titleLarge: HallmarkTypography.headingL2(colors.textPrimary),
        titleMedium: HallmarkTypography.titleL3(colors.textPrimary),
        titleSmall: HallmarkTypography.titleSmall(colors.textPrimary),
        bodyLarge: HallmarkTypography.bodyLarge(colors.textPrimary),
        bodyMedium: HallmarkTypography.bodyMain(colors.textPrimary),
        bodySmall: HallmarkTypography.bodySmall(colors.textMuted),
        labelLarge: HallmarkTypography.labelButton(colors.textPrimary),
        labelSmall: HallmarkTypography.bodySmall(colors.textMuted),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.borderLight, width: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerColor: AppColors.borderLight,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.mutedGray,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textDark,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.borderLight, width: 1.0),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.borderLight, width: 1.0),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: GoogleFonts.inter(color: AppColors.mutedGray, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: AppColors.mutedGray, fontSize: 14),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: Colors.white,
        headerForegroundColor: const Color(0xFF0F172A),
        headerHeadlineStyle: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A),
        ),
        headerHelpStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF64748B),
          letterSpacing: 0.5,
        ),
        weekdayStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF64748B),
        ),
        dayStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF0F172A),
        ),
        yearStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF0F172A),
        ),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          if (states.contains(WidgetState.disabled)) return const Color(0xFFCBD5E1);
          return const Color(0xFF0F172A);
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.primary;
        }),
        todayBorder: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: const Color(0xFF64748B),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CUPERTINO THEME (iOS characteristic widgets)
  // ─────────────────────────────────────────────────────────────────────────

  static CupertinoThemeData get cupertinoTheme {
    return const CupertinoThemeData(
      primaryColor: AppColors.primary,
      barBackgroundColor: Colors.transparent,
      scaffoldBackgroundColor: Colors.transparent,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DARK THEME — MASTER DARK MODE DESIGN SYSTEM
  // Layered surfaces, warm teal accent, bright WCAG-AA text.
  // ─────────────────────────────────────────────────────────────────────────

  static ThemeData get darkTheme {
    // ── Surface Depth System (Nebula #0B0F19 Base, #1A1F2E Card) ─────────
    const Color bgMain     = Color(0xFF0B0F19); // Scaffold dark navy
    const Color bgSecond   = Color(0xFF1A1F2E); // Surface blue-gray dark
    const Color surface    = Color(0xFF1A1F2E); // L1 — Surface Card
    const Color cardBg     = Color(0xFF1A1F2E); // L1b — Card Surface
    const Color elevated   = Color(0xFF2A3142); // L2 — Elevated Surface
    const Color popup      = Color(0xFF2A3142); // L3 — Overlay Modal
    const Color navigation = Color(0xFF0B0F19); // L4 — Navigation
    const Color inputBg    = Color(0xFF2A3142); // Field Input
    const Color hoverBg    = Color(0xFF3B4459); // Highlight

    // ── Borders & Dividers ────────────────────────────────────────────────
    const Color border  = Color(0xFF2A3142);
    const Color divider = Color(0x14FFFFFF);
    const Color borderElevated = Color(0xFF3B4459);

    // ── Text (BRIGHT_TEXT_DARK_MODE) ─────────────────────────────────────
    const Color textPrimary   = Color(0xFFF1F5F9); // White-blue
    const Color textSecondary = Color(0xFFCBD5E1); // Slate
    const Color textMuted     = Color(0xFF94A3B8); // Muted slate
    const Color textDisabled  = Color(0xFF64748B); // Faint slate

    // ── Accent ───────────────────────────────────────────────────────────
    const Color primary      = Color(0xFF0D9488); // Emerald Teal
    const Color primaryFocus = Color(0xFF14B8A6); // Primary Teal Bright

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgMain,
      extensions: [HallmarkColorScheme.darkPos()],

      // ── Color Scheme ───────────────────────────────────────────────────
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: primary,
        onPrimary: Colors.white,
        secondary: AppColors.accentAmber,
        onSecondary: Colors.white,
        error: AppColors.accentDanger,
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        surfaceContainerLowest: bgMain,
        surfaceContainerLow: bgSecond,
        surfaceContainer: cardBg,
        surfaceContainerHigh: elevated,
        surfaceContainerHighest: popup,
        onSurfaceVariant: textSecondary,
        outline: border,
        outlineVariant: divider,
        primaryContainer: Color(0xFF1A3A36),       // primary teal tinted surface
        onPrimaryContainer: primaryFocus,
        secondaryContainer: Color(0xFF2D2416),     // amber tinted
        onSecondaryContainer: AppColors.accentAmber,
        errorContainer: Color(0xFF3D1F1F),         // danger tinted
        onErrorContainer: AppColors.accentDanger,
        inverseSurface: textPrimary,
        onInverseSurface: bgMain,
        inversePrimary: primary,
        shadow: Colors.black,
        scrim: Colors.black,
      ),

      // ── Typography — Full Hierarchy ────────────────────────────────────
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        // Display — 28px Bold
        displayLarge: GoogleFonts.inter(
          fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary,
        ),
        // Page Title — 22px SemiBold
        titleLarge: GoogleFonts.inter(
          fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary,
        ),
        // Section Title — 18px SemiBold
        titleMedium: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary,
        ),
        // Card Title — 16px Medium
        titleSmall: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary,
        ),
        // Body — 15px Regular
        bodyLarge: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.normal, color: textSecondary,
        ),
        // Body — 14px Regular
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.normal, color: textSecondary,
        ),
        // Caption — 13px Regular
        bodySmall: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.normal, color: textMuted,
        ),
        // Label
        labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary,
        ),
        // Hint — 12px Regular
        labelSmall: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.normal, color: textMuted,
        ),
      ),

      // ── Card ───────────────────────────────────────────────────────────
      // Nebula card: cosmic-surface bg, thin border, diffuse shadow, ambient glow
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: border, width: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Divider ────────────────────────────────────────────────────────
      dividerColor: divider,
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 0.5,
        space: 0,
      ),

      // ── Card container-level shadow (via Material) ─────────────────────
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,

      // ── Bottom Navigation Bar ──────────────────────────────────────────
      // Active: teal — inactive: muted slate gray
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: navigation,
        selectedItemColor: primary,
        unselectedItemColor: textDisabled,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.normal,
        ),
      ),

      // ── Navigation Bar (Material 3) ────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navigation,
        indicatorColor: primary.withValues(alpha: 0.20),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600, color: primary,
            );
          }
          return GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.normal, color: textDisabled,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 24);
          }
          return const IconThemeData(color: textDisabled, size: 24);
        }),
      ),

      // ── App Bar ────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: primary, size: 24),
        actionsIconTheme: const IconThemeData(color: primary, size: 24),
      ),

      // ── Input Decoration ───────────────────────────────────────────────
      // Input: #334155 bg, 12px radius, 16px padding, teal focus glow
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: border, width: 1.0),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: border, width: 1.0),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: primary, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.accentDanger, width: 1.0),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.accentDanger, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: GoogleFonts.inter(color: textMuted, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: textDisabled, fontSize: 14),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
      ),

      // ── Elevated Button ────────────────────────────────────────────────
      // Primary Button: teal bg, white text, pill shape (999), hover lift
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: textDisabled.withValues(alpha: 0.30),
          disabledForegroundColor: textDisabled,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          minimumSize: const Size(0, 52),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Outlined Button ────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          minimumSize: const Size(0, 52),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Text Button ────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Chip ───────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: elevated,
        selectedColor: primary.withValues(alpha: 0.20),
        labelStyle: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w500, color: textSecondary,
        ),
        side: const BorderSide(color: border, width: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ── Dialog ────────────────────────────────────────────────────────
      // Nebula modal: cosmic-overlay bg, thin border, glow shadow
      dialogTheme: DialogThemeData(
        backgroundColor: popup,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: borderElevated, width: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.normal, color: textSecondary,
        ),
      ),

      // ── Date Picker ───────────────────────────────────────────────────
      datePickerTheme: DatePickerThemeData(
        backgroundColor: popup,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: popup,
        headerForegroundColor: textPrimary,
        headerHeadlineStyle: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headerHelpStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textMuted,
          letterSpacing: 0.5,
        ),
        weekdayStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textMuted,
        ),
        dayStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        yearStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          if (states.contains(WidgetState.disabled)) return textDisabled;
          return textPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return primary;
        }),
        todayBorder: const BorderSide(color: primary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: borderElevated, width: 0.5),
        ),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: textMuted,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),

      // ── Bottom Sheet ──────────────────────────────────────────────────
      // Nebula sheet: popup bg with elevated border + ambient glow
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: popup,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
        dragHandleColor: Color(0xFF475569),
        dragHandleSize: Size(40, 4),
      ),

      // ── Floating Action Button ─────────────────────────────────────────
      // Nebula FAB: teal bg with glow shadow
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 8,
        focusElevation: 10,
        hoverElevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),

      // ── List Tile ─────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: primary.withValues(alpha: 0.12),
        iconColor: textMuted,
        textColor: textPrimary,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w500, color: textPrimary,
        ),
        subtitleTextStyle: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.normal, color: textSecondary,
        ),
        leadingAndTrailingTextStyle: GoogleFonts.inter(
          fontSize: 13, color: textMuted,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),

      // ── Switch ────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return textDisabled;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return hoverBg;
        }),
      ),

      // ── Checkbox ──────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // ── ProgressIndicator ─────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: Color(0xFF273449),
      ),

      // ── Tooltip ───────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: popup,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 0.5),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 13, color: textPrimary,
        ),
      ),

      // ── SnackBar ─────────────────────────────────────────────────────
      // Nebula snackbar: elevated bg, floating, subtle border
      snackBarTheme: SnackBarThemeData(
        backgroundColor: elevated,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14, color: textPrimary,
        ),
        actionTextColor: primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderElevated, width: 0.5),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Popup Menu ────────────────────────────────────────────────────
      // Nebula popup: overlay bg, elevated border, glow shadow
      popupMenuTheme: PopupMenuThemeData(
        color: popup,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderElevated, width: 0.5),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14, color: textPrimary,
        ),
      ),

      // ── Tab Bar ───────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textDisabled,
        indicatorColor: primary,
        dividerColor: divider,
        labelStyle: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.normal,
        ),
      ),
    );
  }
}
