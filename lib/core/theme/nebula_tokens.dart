import 'package:flutter/material.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

/// Nebula Design System — Spacing tokens (8-pt grid, golden ratio)
class NebulaSpacing {
  NebulaSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double xxxxl = 40;
  static const double section = 48;
  static const double sectionLg = 64;
}

/// Nebula Design System — Border radius tokens
class NebulaRadius {
  NebulaRadius._();

  static const double sm = 6;
  static const double md = 8;
  static const double lg = 10;
  static const double xl = 12;
  static const double xxl = 16;
  static const double xxxl = 20;
  static const double xxxxl = 24;
  static const double full = 9999;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get xxlAll => BorderRadius.circular(xxl);
  static BorderRadius get xxxlAll => BorderRadius.circular(xxxl);
  static BorderRadius get xxxxlAll => BorderRadius.circular(xxxxl);

  static BorderRadius get topXxl => const BorderRadius.vertical(top: Radius.circular(xxl));
  static BorderRadius get topXxxl => const BorderRadius.vertical(top: Radius.circular(xxxl));
}

/// App Design System — Elevation shadow tokens
class NebulaShadows {
  NebulaShadows._();

  /// Level 1: card default
  static List<BoxShadow> get elevate1 => const [
        BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ];

  /// Level 2: dropdown, hovered card
  static List<BoxShadow> get elevate2 => const [
        BoxShadow(
          color: Color(0x19000000),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ];

  /// Level 3: modal, dialog
  static List<BoxShadow> get elevate3 => const [
        BoxShadow(
          color: Color(0x26000000),
          blurRadius: 24,
          offset: Offset(0, 12),
        ),
      ];

  /// Subtle elevation highlight (replaces glowXs)
  static List<BoxShadow> glowXs(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.10),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  /// Subtle elevation highlight (replaces glowSm)
  static List<BoxShadow> glowSm(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.12),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];

  /// Medium elevation highlight (replaces glowMd)
  static List<BoxShadow> glowMd(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.15),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  /// Large elevation highlight (replaces glowLg)
  static List<BoxShadow> glowLg(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.20),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];


  /// Inner glow for inputs
  static List<BoxShadow> innerGlow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.3),
          blurRadius: 20,
          offset: const Offset(0, 0),
        ),
      ];

  /// Card shadow with ambient glow
  static List<BoxShadow> get card => const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 20,
          offset: Offset(0, 4),
        ),
      ];

  /// Card hover shadow with accent glow
  static List<BoxShadow> cardHover(Color accent) => [
        ...elevate2,
        BoxShadow(
          color: accent.withValues(alpha: 0.3),
          blurRadius: 20,
          offset: const Offset(0, 0),
        ),
      ];

  /// FAB shadow with teal glow
  static List<BoxShadow> get fab => const [
        BoxShadow(
          color: Color(0x4014B8A6),
          blurRadius: 28,
          offset: Offset(0, 12),
        ),
      ];
}

/// Nebula Design System — Animation durations and curves
class NebulaAnimation {
  NebulaAnimation._();

  static const Duration instant = Duration(milliseconds: 100);
  static const Duration quick = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration smooth = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static Curve get bounceIn => const Cubic(0.68, -0.55, 0.265, 1.55);
  static const Curve spring = Curves.elasticOut;
}

/// Nebula Design System — Border tokens
class NebulaBorder {
  NebulaBorder._();

  static BorderSide get standard => const BorderSide(color: Color(0x0DFFFFFF), width: 0.5);
  static BorderSide get elevated => const BorderSide(color: Color(0x1AFFFFFF), width: 0.5);
  static BorderSide get active => const BorderSide(color: Nebula.blue, width: 1.0);
  static BorderSide get error => const BorderSide(color: Nebula.rose, width: 1.0);
}
