import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/providers/theme_provider.dart';

/// MASTER DARK MODE DESIGN SYSTEM — Full Typographic Hierarchy
///
/// Typography Scale (8-pt grid):
/// ┌──────────────┬────────┬──────────┬──────────────────────────────┐
/// │ Style         │  Size  │  Weight  │  Dark Color                  │
/// ├──────────────┼────────┼──────────┼──────────────────────────────┤
/// │ display       │  28px  │  Bold    │  #F8FAFC                     │
/// │ pageTitle     │  22px  │  600     │  #F8FAFC                     │
/// │ sectionTitle  │  18px  │  600     │  #F8FAFC                     │
/// │ cardTitle     │  16px  │  500     │  #F8FAFC                     │
/// │ body          │  15px  │  400     │  #E8E8E8                     │
/// │ bodyMedium    │  14px  │  400     │  #CBD5E1                     │
/// │ caption       │  13px  │  400     │  #94A3B8                     │
/// │ hint          │  12px  │  400     │  #94A3B8                     │
/// └──────────────┴────────┴──────────┴──────────────────────────────┘
class AppTextStyles {
  AppTextStyles._();

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  static bool get _dark => ThemeNotifier.isDark;

  // ─────────────────────────────────────────────────────────────────────────
  // DISPLAY — 28px Bold
  // Biggest heading. Used for welcome screens, hero sections.
  // ─────────────────────────────────────────────────────────────────────────

  static TextStyle get display => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: _dark ? const Color(0xFFF8FAFC) : AppColors.textDark,
        letterSpacing: -0.5,
        height: 1.2,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // PAGE TITLE — 22px SemiBold
  // Used for screen/page titles in the AppBar or top of each screen.
  // ─────────────────────────────────────────────────────────────────────────

  static TextStyle get pageTitle => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: _dark ? const Color(0xFFF8FAFC) : AppColors.textDark,
        letterSpacing: -0.3,
        height: 1.3,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION TITLE — 18px SemiBold
  // Used for section headers within a page.
  // ─────────────────────────────────────────────────────────────────────────

  static TextStyle get sectionTitle => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _dark ? const Color(0xFFF8FAFC) : AppColors.textDark,
        height: 1.4,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // CARD TITLE — 16px Medium
  // Used inside cards, list tile titles, modal headings.
  // ─────────────────────────────────────────────────────────────────────────

  static TextStyle get cardTitle => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: _dark ? const Color(0xFFF8FAFC) : AppColors.textDark,
        height: 1.4,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // BODY — 15px Regular
  // Primary body text. Bright in dark (#E8E8E8), dark in light.
  // ─────────────────────────────────────────────────────────────────────────

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        color: _dark ? const Color(0xFFE8E8E8) : AppColors.textDark,
        height: 1.6,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // BODY MEDIUM — 14px Regular
  // Secondary body, descriptions, supporting information.
  // ─────────────────────────────────────────────────────────────────────────

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: _dark ? const Color(0xFFCBD5E1) : AppColors.textSecondary,
        height: 1.6,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // CAPTION — 13px Regular
  // Used for captions, table content, secondary metadata.
  // ─────────────────────────────────────────────────────────────────────────

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.normal,
        color: _dark ? const Color(0xFF94A3B8) : AppColors.mutedGray,
        height: 1.5,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // HINT — 12px Regular
  // Smallest readable size. Used for hints, helper text, micro-labels.
  // ─────────────────────────────────────────────────────────────────────────

  static TextStyle get hint => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: _dark ? const Color(0xFF94A3B8) : AppColors.mutedGray,
        height: 1.5,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // LABEL — 14px SemiBold
  // Used for form labels, navigation labels, tags.
  // ─────────────────────────────────────────────────────────────────────────

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _dark ? const Color(0xFFF2F2F2) : AppColors.textDark,
        letterSpacing: 0.1,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // FORM LABEL — 14px SemiBold (slightly brighter in dark)
  // ─────────────────────────────────────────────────────────────────────────

  static TextStyle get formLabel => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _dark ? const Color(0xFFF2F2F2) : AppColors.textDark,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // BUTTON — 16px SemiBold
  // Always white (buttons always have a colored background).
  // ─────────────────────────────────────────────────────────────────────────

  static TextStyle get button => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFFFFFFF),
        letterSpacing: 0.1,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // CURRENCY / AMOUNT — 18px Bold
  // Used for prices, balances, financial figures.
  // ─────────────────────────────────────────────────────────────────────────

  static TextStyle get currency => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: _dark ? const Color(0xFFF8FAFC) : AppColors.textDark,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // ─────────────────────────────────────────────────────────────────────────
  // OVERLINE / BADGE LABEL — 11px Bold, uppercase
  // Used for status chips, badges, overline text.
  // ─────────────────────────────────────────────────────────────────────────

  static TextStyle get overline => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _dark ? const Color(0xFFCBD5E1) : AppColors.textSecondary,
        letterSpacing: 0.8,
        height: 1.2,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // DISABLED — Muted, lower contrast (meets WCAG AA for non-essential)
  // ─────────────────────────────────────────────────────────────────────────

  static TextStyle get disabled => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: _dark ? const Color(0xFF64748B) : AppColors.mutedGray,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // GRADIENT TEXT HELPER (Nebula Design System)
  // Apply with ShaderMask or use gradientText() for inline use.
  // ─────────────────────────────────────────────────────────────────────────

  /// Creates a gradient [TextStyle] for hero titles / KPIs.
  /// Apply as: `Text('title', style: AppTextStyles.gradientText())`
  static TextStyle gradientText({
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.bold,
    List<Color>? colors,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: Colors.white,
      letterSpacing: -0.5,
      height: 1.2,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STATUS STYLES (with color baked in for clear semantic meaning)
  // ─────────────────────────────────────────────────────────────────────────

  /// Success text — #4ADE80 in dark (BRIGHT_TEXT_DARK_MODE: #7DFF9A)
  static TextStyle get success => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _dark ? const Color(0xFF7DFF9A) : const Color(0xFF16A34A),
      );

  /// Warning text — #FFD76A in dark (BRIGHT_TEXT_DARK_MODE)
  static TextStyle get warning => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _dark ? const Color(0xFFFFD76A) : const Color(0xFFD97706),
      );

  /// Error text — #FF8A8A in dark (BRIGHT_TEXT_DARK_MODE)
  static TextStyle get error => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _dark ? const Color(0xFFFF8A8A) : const Color(0xFFDC2626),
      );

  /// Info text — #7DB8FF in dark (BRIGHT_TEXT_DARK_MODE)
  static TextStyle get info => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _dark ? const Color(0xFF7DB8FF) : const Color(0xFF2563EB),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // LEGACY ALIASES (backward compatibility — map to new hierarchy)
  // ─────────────────────────────────────────────────────────────────────────

  /// Alias → display
  static TextStyle get h1 => display;

  /// Alias → pageTitle
  static TextStyle get h2 => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: _dark ? const Color(0xFFF8FAFC) : AppColors.textDark,
      );

  /// Alias → sectionTitle
  static TextStyle get h3 => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: _dark ? const Color(0xFFF8FAFC) : AppColors.textDark,
      );

  /// Alias → body
  static TextStyle get bodyLarge => body;

  /// Alias → bodyMedium (14px)
  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: _dark ? const Color(0xFF94A3B8) : AppColors.mutedGray,
      );
}
