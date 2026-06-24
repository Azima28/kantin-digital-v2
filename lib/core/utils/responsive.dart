import 'package:flutter/material.dart';

/// Utility helper for responsive breakpoints across the app.
///
/// Breakpoints:
///   - mobile  : width < 600
///   - tablet  : 600 <= width < 900
///   - desktop : width >= 900
class Responsive {
  // ── Breakpoints ────────────────────────────────────────────────
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;

  // ── Device type checks ─────────────────────────────────────────
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= mobileBreakpoint && w < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  // ── Padding ────────────────────────────────────────────────────
  /// Returns horizontal padding suitable for the current screen width.
  static double horizontalPadding(BuildContext context) {
    if (isMobile(context)) return 16;
    if (isTablet(context)) return 24;
    return 32;
  }

  /// Returns symmetric EdgeInsets for horizontal padding.
  static EdgeInsets horizontalPaddingInsets(BuildContext context) =>
      EdgeInsets.symmetric(horizontal: horizontalPadding(context));

  // ── Grid ───────────────────────────────────────────────────────
  /// Returns the number of product grid columns for the current screen width.
  static int productGridColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1200) return 6;
    if (w >= 900) return 4;
    if (w >= 600) return 3;
    return 2;
  }

  /// Returns the childAspectRatio for the product grid.
  static double productGridAspectRatio(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 900) return 0.72;
    if (w >= 600) return 0.68;
    // Mobile: extra height for name + price + button
    return 0.63;
  }

  // ── Font Size ──────────────────────────────────────────────────
  /// Responsive heading font size.
  static double headingFontSize(BuildContext context) {
    if (isMobile(context)) return 18;
    return 20;
  }

  // ── Max Width ─────────────────────────────────────────────────-
  /// Max width constraint for centered content.
  static double contentMaxWidth(BuildContext context) {
    if (isMobile(context)) return double.infinity;
    if (isTablet(context)) return 800;
    return 1000;
  }

  // ── Sidebar ────────────────────────────────────────────────────
  /// Whether the sidebar should be shown (desktop layout).
  static bool showSidebar(BuildContext context) => isDesktop(context);

  /// Sidebar width based on screen size.
  static double sidebarWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1100) return 260;
    return 220; // narrower on smaller desktops / large tablets
  }
}
