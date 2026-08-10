import 'package:flutter/material.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

/// BuildContext extension providing semantic, theme-aware colors.
/// Use these instead of hardcoded AppColors.* in all screens.
///
/// Usage: `context.cardBg`, `context.textPrimary`, etc.
extension AppThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // ─── Surface / Card backgrounds ────────────────────────────────────────
  /// Main card / container background
  Color get cardBg => isDark ? AppColors.darkSurfaceL1 : AppColors.white;

  /// Slightly elevated surface (for nested cards)
  Color get surfaceBg => isDark ? AppColors.darkSurfaceL2 : AppColors.surfaceContainer;

  /// Scaffold / page background (transparent — handled by PremiumBackground)
  Color get scaffoldBg => Colors.transparent;

  // ─── Text (Stitch Dark Mode Specs) ───────────────────────────────────────
  /// Primary text: pure white in dark, near-black in light
  Color get textPrimary => isDark ? const Color(0xFFFFFFFF) : AppColors.textDark;

  /// Same as textPrimary — alias used in some screens
  Color get textOnCard => isDark ? const Color(0xFFFFFFFF) : AppColors.nearBlack;

  /// Secondary text: cool slate gray in dark (#CDD5E0), medium gray in light
  Color get textSecondary => isDark ? const Color(0xFFCDD5E0) : AppColors.mutedGray;

  /// Hint / placeholder text
  Color get textHint => isDark ? const Color(0xFF64748B) : AppColors.textGray;

  // ─── Borders / Dividers ─────────────────────────────────────────────────
  /// Divider and border color
  Color get dividerCol => isDark ? AppColors.darkBorder : AppColors.borderGray;

  /// Light border (cards edges)
  Color get borderLight => isDark ? AppColors.darkBorder : AppColors.borderLight;

  /// Card border color
  Color get cardBorder => isDark ? Colors.transparent : borderLight;

  // ─── Icon colors ──────────────────────────────────────────────────────────
  /// Primary Icon: teal in dark, primary teal in light
  Color get iconPrimary => isDark ? const Color(0xFF00C4B4) : AppColors.primary;

  /// Secondary Icon
  Color get iconSecondary => isDark ? const Color(0xFFCDD5E0) : AppColors.mutedGray;

  /// Inactive Icon: slate gray in dark
  Color get iconInactive => isDark ? const Color(0xFF64748B) : AppColors.gray;

  /// Disabled Icon
  Color get iconDisabled => isDark ? const Color(0xFF374151) : AppColors.grayLight;

  // ─── Icon / accent tints ────────────────────────────────────────────────
  /// Teal icon bg tint
  Color get tealIconBg => isDark
      ? const Color(0xFF00C4B4).withValues(alpha: 0.15)
      : AppColors.primaryLight;

  /// Shadow color for elevation effects
  Color get shadowColor => isDark
      ? Colors.black.withValues(alpha: 0.4)
      : AppColors.black.withValues(alpha: 0.04);

  /// Section header text color
  Color get sectionHeader => isDark ? const Color(0xFF94A3B8) : AppColors.textGray;

  // ─── State / Semantic ─────────────────────────────────────────────────────
  Color get errorColor => AppColors.error;
  Color get errorBg => isDark
      ? AppColors.errorRed2.withValues(alpha: 0.15)
      : AppColors.errorLightColor;
  Color get successColor => AppColors.success;
  Color get successBg => isDark
      ? AppColors.successGreen.withValues(alpha: 0.15)
      : AppColors.successLight;
}
