import 'package:flutter/painting.dart';

/// Modern App Design System — Color Tokens (Standard Production Design)
///
/// Three-layer token architecture:
/// 1. [Cosmic] — Layered Surface Depths (Light & Dark Slate)
/// 2. [Starlight] — Typography & Interface Tokens
/// 3. [Nebula] — Palette & Semantic Accent Tokens
class Cosmic {
  Cosmic._();

  /// L0 — Main app background slate (#0F172A in Dark mode, #F8FAFC in Light)
  static const Color void_ = Color(0xFF0F172A);

  /// L0 alt — Base background surface (#1E293B)
  static const Color base = Color(0xFF1E293B);

  /// L1 — Card, panel, and container surface (#334155)
  static const Color surface = Color(0xFF334155);

  /// L2 — Elevated dropdowns, popovers, and dialogs (#475569)
  static const Color elevated = Color(0xFF475569);

  /// L3 — Modals and overlays (#64748B)
  static const Color overlay = Color(0xFF64748B);

  /// Input fields, search bars (#1E293B)
  static const Color field = Color(0xFF1E293B);

  /// Table row hover & active highlight (#334155)
  static const Color highlight = Color(0xFF334155);
}

class Starlight {
  Starlight._();

  /// Primary heading, high emphasis typography (#F8FAFC)
  static const Color bright = Color(0xFFF8FAFC);

  /// Body text, default content (#E2E8F0)
  static const Color default_ = Color(0xFFE2E8F0);

  /// Secondary text, descriptions (#94A3B8)
  static const Color dim = Color(0xFF94A3B8);

  /// Placeholder, disabled text, hints (#64748B)
  static const Color faint = Color(0xFF64748B);

  /// Disabled state text (#475569)
  static const Color disabled = Color(0xFF475569);
}

class Nebula {
  Nebula._();

  // ── Blue (Indigo / Royal) ─────────────────────────────────────────────
  static const Color blue = Color(0xFF2563EB);
  static const Color blueLight = Color(0xFF3B82F6);
  static const Color blueDark = Color(0xFF1D4ED8);
  static Color get blueGlow => blue.withValues(alpha: 0.15);
  static Color get blueSurface => blue.withValues(alpha: 0.08);

  // ── Purple / Violet ───────────────────────────────────────────────────
  static const Color purple = Color(0xFF4F46E5);
  static const Color purpleLight = Color(0xFF6366F1);
  static const Color purpleDark = Color(0xFF4338CA);
  static Color get purpleGlow => purple.withValues(alpha: 0.15);
  static Color get purpleSurface => purple.withValues(alpha: 0.08);

  // ── Teal / Emerald ────────────────────────────────────────────────────
  static const Color teal = Color(0xFF0D9488);
  static const Color tealLight = Color(0xFF14B8A6);
  static const Color tealDark = Color(0xFF0F766E);
  static Color get tealGlow => teal.withValues(alpha: 0.15);
  static Color get tealSurface => teal.withValues(alpha: 0.08);

  // ── Amber / Orange ────────────────────────────────────────────────────
  static const Color amber = Color(0xFFD97706);
  static const Color amberLight = Color(0xFFF59E0B);
  static const Color amberDark = Color(0xFFB45309);
  static Color get amberGlow => amber.withValues(alpha: 0.15);
  static Color get amberSurface => amber.withValues(alpha: 0.08);

  // ── Rose / Red ────────────────────────────────────────────────────────
  static const Color rose = Color(0xFFE11D48);
  static const Color roseLight = Color(0xFFF43F5E);
  static const Color roseDark = Color(0xFFBE123C);
  static Color get roseGlow => rose.withValues(alpha: 0.15);
  static Color get roseSurface => rose.withValues(alpha: 0.08);

  // ── Gold / Warm Yellow ────────────────────────────────────────────────
  static const Color gold = Color(0xFFD97706);
  static Color get goldGlow => gold.withValues(alpha: 0.15);

  // ── Semantic mapping ──────────────────────────────────────────────────
  static const Color primaryAction = teal;
  static const Color secondaryAction = blue;
  static const Color success = teal;
  static const Color warning = amber;
  static const Color error = rose;
  static const Color info = blueLight;
}

/// Professional role-specific visual identities for standard mobile & web applications.
class RoleColors {
  RoleColors._();

  /// Siswa: Friendly Emerald & Slate Teal — clean, welcoming cafeteria ordering
  static Color get siswaPrimary => const Color(0xFF0D9488);
  static Color get siswaSecondary => const Color(0xFF059669);
  static List<Color> get siswaGradient => const [Color(0xFF0D9488), Color(0xFF0F766E)];
  static Color get siswaGlow => const Color(0x1A0D9488);

  /// Petugas Kantin: High-contrast Operational Warm Amber & Orange — fast POS cashier tapping
  static Color get petugasPrimary => const Color(0xFFD97706);
  static Color get petugasSecondary => const Color(0xFFEA580C);
  static List<Color> get petugasGradient => const [Color(0xFFD97706), Color(0xFFB45309)];
  static Color get petugasGlow => const Color(0x1AD97706);

  /// Orang Tua: Trustworthy Financial Royal Blue & Indigo — clear wallet monitoring & controls
  static Color get orangTuaPrimary => const Color(0xFF2563EB);
  static Color get orangTuaSecondary => const Color(0xFF1D4ED8);
  static List<Color> get orangTuaGradient => const [Color(0xFF2563EB), Color(0xFF1E40AF)];
  static Color get orangTuaGlow => const Color(0x1A2563EB);

  /// Guru: Academic Deep Violet & Indigo — structured classroom management
  static Color get guruPrimary => const Color(0xFF4F46E5);
  static Color get guruSecondary => const Color(0xFF4338CA);
  static List<Color> get guruGradient => const [Color(0xFF4F46E5), Color(0xFF3730A3)];
  static Color get guruGlow => const Color(0x1A4F46E5);

  /// Keuangan: Enterprise Slate Cyan & Blue — audit-ready financial metrics & reports
  static Color get keuanganPrimary => const Color(0xFF0284C7);
  static Color get keuanganSecondary => const Color(0xFF0F766E);
  static List<Color> get keuanganGradient => const [Color(0xFF0284C7), Color(0xFF0369A1)];
  static Color get keuanganGlow => const Color(0x1A0284C7);

  /// Admin / Super Admin: Executive Slate & Zinc — clean administrative dashboard
  static Color get adminPrimary => const Color(0xFF1E293B);
  static Color get adminSecondary => const Color(0xFF3B82F6);
  static List<Color> get adminGradient => const [Color(0xFF1E293B), Color(0xFF334155)];
  static Color get adminGlow => const Color(0x1A3B82F6);

  /// Kepala Sekolah: Executive Deep Violet — leadership summary
  static Color get kepsekPrimary => const Color(0xFF6D28D9);
  static Color get kepsekSecondary => const Color(0xFF5B21B6);
  static List<Color> get kepsekGradient => const [Color(0xFF6D28D9), Color(0xFF4C1D95)];
  static Color get kepsekGlow => const Color(0x1A6D28D9);

  /// Dynamic role getter — resolves colors based on role string
  static ({Color primary, Color secondary, List<Color> gradient, Color glow}) forRole(
    String role,
  ) {
    switch (role.toLowerCase()) {
      case 'siswa':
      case 'student':
        return (
          primary: siswaPrimary,
          secondary: siswaSecondary,
          gradient: siswaGradient,
          glow: siswaGlow,
        );
      case 'petugas_kantin':
      case 'canteen_staff':
        return (
          primary: petugasPrimary,
          secondary: petugasSecondary,
          gradient: petugasGradient,
          glow: petugasGlow,
        );
      case 'orang_tua':
      case 'parent':
        return (
          primary: orangTuaPrimary,
          secondary: orangTuaSecondary,
          gradient: orangTuaGradient,
          glow: orangTuaGlow,
        );
      case 'guru':
      case 'teacher':
        return (
          primary: guruPrimary,
          secondary: guruSecondary,
          gradient: guruGradient,
          glow: guruGlow,
        );
      case 'keuangan':
      case 'finance':
        return (
          primary: keuanganPrimary,
          secondary: keuanganSecondary,
          gradient: keuanganGradient,
          glow: keuanganGlow,
        );
      case 'kepala_sekolah':
      case 'principal':
        return (
          primary: kepsekPrimary,
          secondary: kepsekSecondary,
          gradient: kepsekGradient,
          glow: kepsekGlow,
        );
      default:
        // Admin / Super Admin
        return (
          primary: adminPrimary,
          secondary: adminSecondary,
          gradient: adminGradient,
          glow: adminGlow,
        );
    }
  }
}

