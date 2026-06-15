import 'package:flutter/painting.dart';

class AppColors {
  AppColors._();

  // Primary Colors (Minimalist Teal)
  static const Color primary = Color(0xFF0E8A8A);
  static const Color primaryLight = Color(0xFFE6F2F2);
  static const Color primaryDark = Color(0xFF0A5E5E);

  // Background Colors (iOS Style System Background)
  static const Color systemBackground = Color(0xFFF2F2F7);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Accent Colors
  static const Color accentOrange = Color(0xFFFF9500); // iOS style orange
  static const Color accentOrangeLight = Color(0xFFFFF2E0);

  // Status & Semantic Colors
  static const Color success = Color(0xFF34C759); // iOS green
  static const Color successLight = Color(0xFFEAF9EE);
  static const Color error = Color(0xFFFF3B30); // iOS red
  static const Color errorLight = Color(0xFFFEECEB);

  // Neutral Colors (Text & Borders)
  static const Color textDark = Color(0xFF1C1C1E);
  static const Color textGray = Color(0xFF8E8E93);
  static const Color borderLight = Color(0xFFE5E5EA);
  static const Color borderFocus = Color(0xFF0E8A8A);
}
