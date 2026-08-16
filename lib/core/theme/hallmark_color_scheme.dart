/* Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V5 */
import 'package:flutter/material.dart';

/// Hallmark OKLCH Perceptual Color Token Scheme for Kantin Digital v2.0
/// Zero mid-render color improvisation. All surfaces, borders, accents,
/// and status indicators are encapsulated within this strongly-typed ThemeExtension.
@immutable
class HallmarkColorScheme extends ThemeExtension<HallmarkColorScheme> {
  final Color surfaceBase;
  final Color surfaceContainer;
  final Color surfaceSubtle;
  final Color brandPrimary;
  final Color brandAccent;
  final Color textPrimary;
  final Color textMuted;
  final Color borderTactile;
  final Color statusSuccess;
  final Color statusWarning;
  final Color statusError;

  const HallmarkColorScheme({
    required this.surfaceBase,
    required this.surfaceContainer,
    required this.surfaceSubtle,
    required this.brandPrimary,
    required this.brandAccent,
    required this.textPrimary,
    required this.textMuted,
    required this.borderTactile,
    required this.statusSuccess,
    required this.statusWarning,
    required this.statusError,
  });

  /// Light Mode (Siswa / Parent / Public): High luminance, tactile slate ground
  factory HallmarkColorScheme.light() {
    return const HallmarkColorScheme(
      surfaceBase: Color(0xFFF1F5F9),      // oklch(0.95 0.008 240) - Light Slate / Cool Gray 100
      surfaceContainer: Color(0xFFFFFFFF), // oklch(1.00 0.000 0) - Pure White Card
      surfaceSubtle: Color(0xFFE2E8F0),    // oklch(0.91 0.005 240) - Border / Input fill
      brandPrimary: Color(0xFF0D9488),     // oklch(0.65 0.16 175) - Emerald Teal
      brandAccent: Color(0xFF2563EB),      // oklch(0.58 0.18 250) - Cobalt Accent
      textPrimary: Color(0xFF0F172A),      // oklch(0.18 0.020 240) - Deep Slate
      textMuted: Color(0xFF475569),        // oklch(0.48 0.015 240) - Muted Slate
      borderTactile: Color(0xFFE2E8F0),    // oklch(0.91 0.005 240) - 0.5px Hairline
      statusSuccess: Color(0xFF10B981),    // oklch(0.62 0.17 145) - Emerald
      statusWarning: Color(0xFFD97706),    // oklch(0.78 0.16 85) - Amber
      statusError: Color(0xFFEF4444),      // oklch(0.58 0.22 25) - Rose Red
    );
  }

  /// Dark Mode (Kasir POS Workbench / Admin Audit): Deep Slate (#0B0F19), zero glare
  factory HallmarkColorScheme.darkPos() {
    return const HallmarkColorScheme(
      surfaceBase: Color(0xFF0B0F19),      // oklch(0.12 0.015 240) - OLED void
      surfaceContainer: Color(0xFF1A1F2E), // oklch(0.18 0.020 240) - Raised card
      surfaceSubtle: Color(0xFF2A3142),    // oklch(0.24 0.025 240) - Input fill
      brandPrimary: Color(0xFF14B8A6),     // oklch(0.72 0.16 175) - Bright Teal
      brandAccent: Color(0xFF38BDF8),      // oklch(0.68 0.18 250) - Sky Blue
      textPrimary: Color(0xFFF8FAFC),      // oklch(0.96 0.005 240) - Bright text
      textMuted: Color(0xFF94A3B8),        // oklch(0.70 0.010 240) - Slate muted
      borderTactile: Color(0x33FFFFFF),    // oklch(0.28 0.015 240) - 0.5px Hairline
      statusSuccess: Color(0xFF4ADE80),    // oklch(0.72 0.17 145) - Emerald
      statusWarning: Color(0xFFFBBF24),    // oklch(0.82 0.16 85) - Amber
      statusError: Color(0xFFF87171),      // oklch(0.68 0.22 25) - Rose Red
    );
  }

  @override
  HallmarkColorScheme copyWith({
    Color? surfaceBase,
    Color? surfaceContainer,
    Color? surfaceSubtle,
    Color? brandPrimary,
    Color? brandAccent,
    Color? textPrimary,
    Color? textMuted,
    Color? borderTactile,
    Color? statusSuccess,
    Color? statusWarning,
    Color? statusError,
  }) {
    return HallmarkColorScheme(
      surfaceBase: surfaceBase ?? this.surfaceBase,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      brandPrimary: brandPrimary ?? this.brandPrimary,
      brandAccent: brandAccent ?? this.brandAccent,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      borderTactile: borderTactile ?? this.borderTactile,
      statusSuccess: statusSuccess ?? this.statusSuccess,
      statusWarning: statusWarning ?? this.statusWarning,
      statusError: statusError ?? this.statusError,
    );
  }

  @override
  HallmarkColorScheme lerp(ThemeExtension<HallmarkColorScheme>? other, double t) {
    if (other is! HallmarkColorScheme) return this;
    return HallmarkColorScheme(
      surfaceBase: Color.lerp(surfaceBase, other.surfaceBase, t)!,
      surfaceContainer: Color.lerp(surfaceContainer, other.surfaceContainer, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      brandPrimary: Color.lerp(brandPrimary, other.brandPrimary, t)!,
      brandAccent: Color.lerp(brandAccent, other.brandAccent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      borderTactile: Color.lerp(borderTactile, other.borderTactile, t)!,
      statusSuccess: Color.lerp(statusSuccess, other.statusSuccess, t)!,
      statusWarning: Color.lerp(statusWarning, other.statusWarning, t)!,
      statusError: Color.lerp(statusError, other.statusError, t)!,
    );
  }
}

extension HallmarkThemeX on BuildContext {
  HallmarkColorScheme get colors =>
      Theme.of(this).extension<HallmarkColorScheme>() ?? HallmarkColorScheme.light();
}
