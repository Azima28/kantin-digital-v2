import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  // Headings
  static TextStyle get h1 => GoogleFonts.inter(
    fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF1A1D1E),
  );
  static TextStyle get h2 => GoogleFonts.inter(
    fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1A1D1E),
  );
  static TextStyle get h3 => GoogleFonts.inter(
    fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1A1D1E),
  );
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w400, color: const Color(0xFF1A1D1E),
  );
  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFF1A1D1E),
  );
  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w400, color: const Color(0xFF6F7978),
  );
  static TextStyle get label => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1A1D1E),
  );
  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6F7978),
    letterSpacing: 0.5,
  );
  static TextStyle get button => GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFFFFFFFF),
  );
  static TextStyle get currency => GoogleFonts.inter(
    fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A1D1E),
  );
}
