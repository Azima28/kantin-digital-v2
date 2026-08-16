/* Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V5 */
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Hallmark Typography Purity Engine for Kantin Digital v2.0
/// Disiplin 2+1 Font:
/// 1. Plus Jakarta Sans (Headings, Display — STRICTLY 0 Italic)
/// 2. Inter (Body, Inputs, Buttons, Controls)
/// 3. Inter Tabular Figures 'tnum' (Financial amounts, balances, prices, RFID UIDs)
class HallmarkTypography {
  HallmarkTypography._();

  /// Display Large (28px Bold) — Page Master Titles
  static TextStyle displayL1(Color color) => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.5,
        fontStyle: FontStyle.normal, // Hallmark Gate 38a: 0 italic headers
        color: color,
      );

  /// Heading Large (22px SemiBold) — Section Headers
  static TextStyle headingL2(Color color) => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.30,
        letterSpacing: -0.3,
        fontStyle: FontStyle.normal, // Hallmark Gate 38a: 0 italic headers
        color: color,
      );

  /// Title Medium (18px SemiBold) — Card & Modal Titles
  static TextStyle titleL3(Color color) => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.35,
        fontStyle: FontStyle.normal, // Hallmark Gate 38a: 0 italic headers
        color: color,
      );

  /// Title Small (16px Medium) — Sub-headers & List Section Labels
  static TextStyle titleSmall(Color color) => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.normal,
        color: color,
      );

  /// Body Large (15px Regular) — Running paragraphs
  static TextStyle bodyLarge(Color color) => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: color,
      );

  /// Body Medium (14px Regular) — Default body copy
  static TextStyle bodyMain(Color color) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: color,
      );

  /// Body Small / Caption (13px Regular) — Subtitles & Footnotes
  static TextStyle bodySmall(Color color) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.40,
        color: color,
      );

  /// Button & Control Label (14px SemiBold)
  static TextStyle labelButton(Color color) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.20,
        color: color,
      );

  /// Financial Numeral (Inter with 'tnum' Tabular Figures & Slashed Zero)
  /// Prevents digit jitter when currency values change in real-time.
  static TextStyle financialNumeral({
    required Color color,
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFeatures: const [
        FontFeature.tabularFigures(), // 'tnum' fixed digit width alignment
        FontFeature.slashedZero(),
      ],
    );
  }
}
