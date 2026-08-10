import 'package:flutter/material.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/theme/nebula_tokens.dart';

/// Subtle ambient highlight token (kept for backward compatibility).
class AmbientOrb extends StatelessWidget {
  const AmbientOrb({
    super.key,
    this.size = 300,
    this.color,
    this.top,
    this.left,
    this.right,
    this.bottom,
    this.blur = 100,
    this.opacity = 0.05,
  });

  final double size;
  final Color? color;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double blur;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: const SizedBox.shrink(),
    );
  }
}

/// Clean Application Background widget.
class NebulaBackground extends StatelessWidget {
  const NebulaBackground({
    super.key,
    required this.child,
    this.orbs = const [],
    this.showGrid = false,
  });

  final Widget child;
  final List<Widget> orbs;
  final bool showGrid;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppColors.darkBgPrimary : AppColors.scaffoldBackground,
      child: child,
    );
  }
}

/// Gradient line divider — clean horizontal rule.
class GradientLine extends StatelessWidget {
  const GradientLine({
    super.key,
    this.color,
    this.height = 1,
    this.margin,
  });

  final Color? color;
  final double height;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 24),
      height: height,
      color: color ?? (isDark ? AppColors.darkBorder : AppColors.grayLight),
    );
  }
}

/// Standard Surface Card — modern, clean card layout.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.margin,
    this.borderRadius,
    this.glowColor,
    this.blur = 24,
    this.opacity = 0.05,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? glowColor;
  final double blur;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? NebulaRadius.xxlAll;

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceL1 : Colors.white,
        borderRadius: radius,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderLight,
          width: 1.0,
        ),
        boxShadow: NebulaShadows.elevate1,
      ),
      child: child,
    );
  }
}

/// Gradient card — clean hero / KPI card with modern solid/subtle gradient background.
class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.child,
    this.colors,
    this.padding = const EdgeInsets.all(24),
    this.margin,
    this.borderRadius,
    this.glowColor,
  });

  final Widget child;
  final List<Color>? colors;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? NebulaRadius.xxlAll;
    final defaultColors = isDark
        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
        : [const Color(0xFFFFFFFF), const Color(0xFFF8FAFC)];

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors ?? defaultColors,
        ),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderLight,
          width: 1.0,
        ),
        boxShadow: NebulaShadows.elevate1,
      ),
      child: child,
    );
  }
}

