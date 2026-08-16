import 'package:flutter/painting.dart';
import 'package:kantin_digital/core/providers/theme_provider.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

/// MASTER DARK MODE DESIGN SYSTEM (Nebula) — Applied 2026
/// Design tokens for the entire application.
/// References [Cosmic], [Starlight], [Nebula], [RoleColors] for full tokens.
class AppColors {
  AppColors._();

  // ─────────────────────────────────────────────────────────────────────────
  // NEBULA TOKENS (re-exports for convenience)
  // ─────────────────────────────────────────────────────────────────────────

  /// Cosmic void — deepest background (#070B14)
  static const Color cosmicVoid = Cosmic.void_;
  static const Color cosmicBase = Cosmic.base;
  static const Color cosmicSurface = Cosmic.surface;
  static const Color cosmicElevated = Cosmic.elevated;
  static const Color cosmicOverlay = Cosmic.overlay;

  static const Color starlightBright = Starlight.bright;
  static const Color starlightDefault = Starlight.default_;
  static const Color starlightDim = Starlight.dim;
  static const Color starlightFaint = Starlight.faint;

  static const Color nebulaBlue = Nebula.blue;
  static const Color nebulaPurple = Nebula.purple;
  static const Color nebulaTeal = Nebula.teal;
  static const Color nebulaAmber = Nebula.amber;
  static const Color nebulaRose = Nebula.rose;
  static const Color nebulaGold = Nebula.gold;

  // ─────────────────────────────────────────────────────────────────────────
  // NEBULA SPEC TOKENS (UNIFIED EMERALD / TEAL PALETTE)
  // ─────────────────────────────────────────────────────────────────────────

  /// Primary Emerald / Teal Accent (#0D9488 / #14B8A6)
  static const Color primaryIndigo = Color(0xFF14B8A6);
  static const Color primaryIndigoHover = Color(0xFF0D9488);

  /// Dark Mode Specific Colors (#0B0F19 Scaffold, #1A1F2E Card, #2A3142 Border)
  static const Color darkScaffoldBg = Color(0xFF0B0F19);
  static const Color darkCardBg = Color(0xFF1A1F2E);
  static const Color darkCardBorder = Color(0xFF2A3142);
  static const Color darkInputFieldBg = Color(0xFF2A3142);
  static const Color darkInputFieldBorder = Color(0xFF3B4459);
  static const Color darkTextPrimaryVal = Color(0xFFF1F5F9);
  static const Color darkTextSecondaryVal = Color(0xFF94A3B8);

  /// Light Mode Specific Colors (#F1F5F9 Scaffold, #FFFFFF Card)
  static const Color lightScaffoldBg = Color(0xFFF1F5F9);
  static const Color lightCardBg = Color(0xFFFFFFFF);
  static const Color lightInputFieldBg = Color(0xFFF1F5F9);
  static const Color lightInputFieldBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimaryVal = Color(0xFF0F172A);
  static const Color lightTextSecondaryVal = Color(0xFF475569);

  // ─────────────────────────────────────────────────────────────────────────
  // PRIMARY ACCENT — Emerald / Teal (#0D9488 / #14B8A6)
  // ─────────────────────────────────────────────────────────────────────────

  /// Primary Teal accent (#14B8A6)
  static const Color primary = Color(0xFF14B8A6);

  /// Primary hover state (#0D9488)
  static const Color primaryHover = Color(0xFF0D9488);

  /// Primary focus state (#2DD4BF)
  static const Color primaryFocus = Color(0xFF2DD4BF);

  /// Light mode primary (deep teal)
  static const Color primaryLight = Color(0xFFE6F2F2);
  static const Color primaryDark = Color(0xFF0A5E5E);
  static const Color darkTeal2 = Color(0xFF004D4D);
  static const Color softTeal = Color(0xFFB2DFDF);

  /// Static fallbacks (used in const contexts)
  static const Color tealConst = Color(0xFF14B8A6);
  static const Color darkTealConst = Color(0xFF0D9488);

  /// Dynamic primary — #14B8A6 in dark, deep teal in light
  static Color get teal =>
      ThemeNotifier.isDark ? const Color(0xFF14B8A6) : const Color(0xFF006767);

  /// Dynamic dark teal — focus teal in dark, deep dark teal in light
  static Color get darkTeal =>
      ThemeNotifier.isDark ? const Color(0xFF2DD4BF) : const Color(0xFF003434);

  // ─────────────────────────────────────────────────────────────────────────
  // ACCENT COLORS — Use sparingly to guide attention only
  // ─────────────────────────────────────────────────────────────────────────

  /// Blue accent (#38BDF8)
  static const Color accentBlue = Color(0xFF38BDF8);

  /// Purple accent (#8B5CF6)
  static const Color accentPurple = Color(0xFF8B5CF6);

  /// Amber / Warning (#F59E0B)
  static const Color accentAmber = Color(0xFFF59E0B);

  /// Green / Success (#22C55E)
  static const Color accentGreen = Color(0xFF22C55E);

  /// Danger / Error (#F87171)
  static const Color accentDanger = Color(0xFFF87171);

  /// Information (#60A5FA)
  static const Color accentInfo = Color(0xFF60A5FA);

  // Legacy accent names (kept for backward compatibility)
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color darkOrange = Color(0xFF904D00);
  static const Color softOrange = Color(0xFFFFE0B2);
  static const Color accentOrangeLight = Color(0xFFFFF3E0);
  static const Color accentOrange2 = Color(0xFFFF8C00);

  // ─────────────────────────────────────────────────────────────────────────
  // NEBULA ACCENT EXTENSIONS (Nebula Design System)
  // ─────────────────────────────────────────────────────────────────────────

  /// Rose — error/urgent (#F43F5E)
  static const Color rose = Nebula.rose;
  static const Color roseLight = Nebula.roseLight;
  static const Color roseDark = Nebula.roseDark;

  /// Gold — premium / super admin (#FBBF24)
  static const Color gold = Nebula.gold;

  /// Blue primary — #3B82F6
  static const Color blue = Nebula.blue;
  static const Color blueLight = Nebula.blueLight;

  // ─────────────────────────────────────────────────────────────────────────
  // DARK MODE SURFACE DEPTH SYSTEM (Slate Depths)
  // Base Slate → Surface → Elevated → Overlay
  // ─────────────────────────────────────────────────────────────────────────

  /// L0 — Main Background (#0F172A Slate Void)
  static const Color darkBgPrimary = Color(0xFF0F172A);

  /// L0 alt — Base Background (#1E293B)
  static const Color darkBgAlt = Color(0xFF1E293B);

  /// L1 — Secondary Background / Surface (#1E293B)
  static const Color darkBgSecondary = Color(0xFF1E293B);

  /// L1 — Surface (#1E293B)
  static const Color darkSurfaceL1 = Color(0xFF1E293B);

  /// L2 — Elevated Surface (#334155)
  static const Color darkSurfaceL2 = Color(0xFF334155);

  /// L3a — Card (#334155)
  static const Color darkSurfaceL3 = Color(0xFF334155);

  /// L3 — Overlay (#475569)
  static const Color darkElevatedSurface = Color(0xFF475569);

  /// L2 — Field / Input (#1E293B)
  static const Color darkInputBg = Color(0xFF1E293B);

  /// L4 — Navigation Bar (#0F172A)
  static const Color darkNavigation = Color(0xFF0F172A);

  /// L4 — Sidebar (#0F172A)
  static const Color darkSidebar = Color(0xFF0F172A);

  /// Hover Surface (#334155)
  static const Color darkHoverSurface = Color(0xFF334155);

  /// Pressed Surface (#475569)
  static const Color darkPressedSurface = Color(0xFF475569);

  /// Divider — rgba(255,255,255,0.08)
  static const Color darkDivider = Color(0x14FFFFFF);

  /// Border — rgba(255,255,255,0.12)
  static const Color darkBorder = Color(0x1FFFFFFF);

  /// Input Border
  static const Color darkInputBorder = Color(0xFF334155);

  // ─────────────────────────────────────────────────────────────────────────
  // LIGHT MODE BACKGROUNDS (Standard App Style)
  // ─────────────────────────────────────────────────────────────────────────

  static const Color systemBackground = Color(0xFFF1F5F9);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color scaffoldBackground = Color(0xFFF1F5F9);
  static const Color surfaceContainer = Color(0xFFF1F5F9);
  static const Color surfaceContainerLow = Color(0xFFF1F5F9);
  static const Color surfaceContainerHigh = Color(0xFFFFFFFF);

  // ─────────────────────────────────────────────────────────────────────────
  // DARK MODE TEXT — BRIGHT_TEXT_DARK_MODE RULES
  // Never use dark text on dark backgrounds.
  // ─────────────────────────────────────────────────────────────────────────

  /// Primary text — white in dark (#F8FAFC), near-black in light
  static const Color darkTextPrimary = Color(0xFFF8FAFC);

  /// Secondary text — cool gray (#CBD5E1)
  static const Color darkTextSecondary = Color(0xFFCBD5E1);

  /// Muted text (#94A3B8)
  static const Color darkTextMuted = Color(0xFF94A3B8);

  /// Disabled text (#64748B)
  static const Color darkTextDisabled = Color(0xFF64748B);

  /// Error text (#F87171)
  static const Color darkTextError = Color(0xFFF87171);

  /// Success text (#4ADE80)
  static const Color darkTextSuccess = Color(0xFF4ADE80);

  // ─────────────────────────────────────────────────────────────────────────
  // DYNAMIC TEXT TOKENS (context-aware getters)
  // ─────────────────────────────────────────────────────────────────────────

  /// Primary text: #F8FAFC in dark, #0F172A in light
  static Color get textPrimary =>
      ThemeNotifier.isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

  /// Secondary text: #CBD5E1 in dark, #475569 in light
  static Color get textSecondary =>
      ThemeNotifier.isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);

  /// Dark text: white in dark, near-black in light
  static Color get textDark =>
      ThemeNotifier.isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

  /// Gray text: muted slate in dark, system gray in light
  static Color get textGray =>
      ThemeNotifier.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  /// Muted gray: #94A3B8 in dark, muted in light
  static Color get mutedGray =>
      ThemeNotifier.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  /// Border light
  static Color get borderLight =>
      ThemeNotifier.isDark ? const Color(0x1FFFFFFF) : const Color(0xFFE2E8F0);

  /// Border gray
  static Color get borderGray =>
      ThemeNotifier.isDark ? const Color(0x1FFFFFFF) : const Color(0xFFCBD5E1);

  /// Near-black / white toggle
  static Color get nearBlack =>
      ThemeNotifier.isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

  /// Dark gray / light gray
  static Color get darkGray =>
      ThemeNotifier.isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);

  /// Canteen primary text
  static Color get canteenText =>
      ThemeNotifier.isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

  /// Canteen secondary text
  static Color get canteenSecondaryText =>
      ThemeNotifier.isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);

  // ─────────────────────────────────────────────────────────────────────────
  // STATE COLORS (Static — prevents compile errors in const contexts)
  // ─────────────────────────────────────────────────────────────────────────

  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successGreen = Color(0xFF047857);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color errorRed2 = Color(0xFFB91C1C);
  static const Color errorDark = Color(0xFF991B1B);
  static const Color errorLightColor = Color(0xFFFEE2E2);
  static const Color successGreenLight = Color(0xFFD1FAE5);
  static const Color errorRedLight = Color(0xFFFEE2E2);

  // ─────────────────────────────────────────────────────────────────────────
  // NEUTRAL (Light Defaults)
  // ─────────────────────────────────────────────────────────────────────────

  static const Color gray = Color(0xFF94A3B8);
  static const Color grayLight = Color(0xFFE2E8F0);
  static const Color gray400 = Color(0xFF94A3B8);
  static const Color inputBorder = Color(0xFFCBD5E1);
  static const Color grayLighter = Color(0xFFF1F5F9);
  static const Color lightGray = Color(0xFFF1F5F9);
  static const Color offWhite = Color(0xFFF1F5F9);
  static const Color offWhite2 = Color(0xFFF1F5F9);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // ─────────────────────────────────────────────────────────────────────────
  // MISC / LEGACY TOKENS (kept for backward compat)
  // ─────────────────────────────────────────────────────────────────────────

  static const Color borderFocus = Color(0xFF0D9488);
  static const Color outlineVariant = Color(0xFFCBD5E1);
  static const Color onSurfaceVariant = Color(0xFF475569);
  static const Color darkGreen = Color(0xFF047857);
  static const Color successDark = Color(0xFF065F46);
  static const Color warningYellow = Color(0xFFD97706);
  static const Color warningYellowLight = Color(0xFFFEF3C7);

  // ─────────────────────────────────────────────────────────────────────────
  // CANTEEN VISUAL TOKENS (Light Defaults)
  // ─────────────────────────────────────────────────────────────────────────

  static const Color canteenPrimary = Color(0xFF0D9488);
  static const Color canteenSecondary = Color(0xFF14B8A6);
  static const Color canteenBackground = Color(0xFFF1F5F9);
  static const Color canteenBorder = Color(0xFFE2E8F0);
  static const Color canteenDanger = Color(0xFFEF4444);
  static const Color canteenWarning = Color(0xFFD97706);
  static Color canteenSuccess = Color(0xFF10B981);

  // ─────────────────────────────────────────────────────────────────────────
  // SHADOW TOKENS (Standard Production Elevation)
  // ─────────────────────────────────────────────────────────────────────────

  /// Card shadow: soft ambient drop shadow
  static List<BoxShadow> get shadowCard => const [
        BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ];

  /// Popup shadow: modal & popover elevation
  static List<BoxShadow> get shadowPopup => const [
        BoxShadow(
          color: Color(0x1F000000),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ];

  /// Floating button shadow
  static List<BoxShadow> get shadowFAB => const [
        BoxShadow(
          color: Color(0x200D9488),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ];

  // ─────────────────────────────────────────────────────────────────────────
  // ELEVATION SHADOW TOKENS (Clean production app shadows — replaces neon glow)
  // ─────────────────────────────────────────────────────────────────────────

  /// Small subtle elevation (replaces glowSm)
  static List<BoxShadow> glowSm(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.12),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];

  /// Medium subtle elevation (replaces glowMd)
  static List<BoxShadow> glowMd(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.15),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  /// Large dialog elevation (replaces glowLg)
  static List<BoxShadow> glowLg(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.20),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  // ─────────────────────────────────────────────────────────────────────────
  // ROLE-AWARE COLORS
  // ─────────────────────────────────────────────────────────────────────────

  /// Resolve role-specific colors
  static ({Color primary, Color secondary, List<Color> gradient, Color glow})
      colorsForRole(String role) => RoleColors.forRole(role);
}

