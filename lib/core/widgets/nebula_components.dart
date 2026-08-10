import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/theme/nebula_tokens.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';

/// NebulaCard — elevated card with standard elevation.
class NebulaCard extends StatelessWidget {
  const NebulaCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius,
    this.glowColor,
    this.glowIntensity = 0.15,
    this.elevation = 1,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? glowColor;
  final double glowIntensity;
  final int elevation;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? NebulaRadius.xxlAll;
    final shadows = <BoxShadow>[
      if (elevation >= 1) ...NebulaShadows.elevate1,
      if (elevation >= 2) ...NebulaShadows.elevate2,
    ];

    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: radius,
        border: Border.all(color: context.borderLight, width: 1.0),
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return PressScale(onTap: onTap, child: card);
    }

    return card;
  }
}

/// NebulaBadge — status badge with dot and semantic color.
class NebulaBadge extends StatelessWidget {
  const NebulaBadge({
    super.key,
    required this.label,
    this.variant = 'neutral',
    this.dot = false,
    this.size = 'sm',
  });

  final String label;
  final String variant;
  final bool dot;
  final String size;

  Color get _bgColor {
    switch (variant) {
      case 'success':
        return Nebula.tealSurface;
      case 'warning':
        return Nebula.amberSurface;
      case 'error':
        return Nebula.roseSurface;
      case 'info':
        return Nebula.blueSurface;
      default:
        return Colors.black.withValues(alpha: 0.04);
    }
  }

  Color get _textColor {
    switch (variant) {
      case 'success':
        return Nebula.teal;
      case 'warning':
        return Nebula.amber;
      case 'error':
        return Nebula.rose;
      case 'info':
        return Nebula.blue;
      default:
        return Starlight.dim;
    }
  }

  Color get _borderColor {
    switch (variant) {
      case 'success':
        return Nebula.teal.withValues(alpha: 0.25);
      case 'warning':
        return Nebula.amber.withValues(alpha: 0.25);
      case 'error':
        return Nebula.rose.withValues(alpha: 0.25);
      case 'info':
        return Nebula.blue.withValues(alpha: 0.25);
      default:
        return Colors.black.withValues(alpha: 0.08);
    }
  }

  double get _fontSize => size == 'lg' ? 13 : 11;
  EdgeInsets get _padding =>
      size == 'lg'
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 4);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(NebulaRadius.full),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _textColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: _fontSize,
              fontWeight: FontWeight.w600,
              color: _textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// NebulaEmptyState — centered empty state with icon, title, description, action.
class NebulaEmptyState extends StatelessWidget {
  const NebulaEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  final Widget icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? Nebula.blue;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: IconTheme(
                data: IconThemeData(color: color, size: 36),
                child: icon,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Starlight.bright : context.textPrimary,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: context.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              PressScale(
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: NebulaRadius.xlAll,
                    boxShadow: NebulaShadows.elevate1,
                  ),
                  child: Text(
                    actionLabel!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// NebulaSkeleton — shimmer loading placeholder.
class NebulaSkeleton extends StatefulWidget {
  const NebulaSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  final double? width;
  final double height;
  final double? borderRadius;

  @override
  State<NebulaSkeleton> createState() => _NebulaSkeletonState();
}

class _NebulaSkeletonState extends State<NebulaSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final highlightColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius ?? 8.0),
            gradient: LinearGradient(
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// NebulaAppBar — consistent app bar with bottom border and optional actions.
class NebulaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NebulaAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      leading: leading,
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: isDark ? Starlight.bright : context.textPrimary,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      actions: actions,
      shape: Border(
        bottom: BorderSide(
          color: isDark ? const Color(0x14FFFFFF) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
      ),
    );
  }
}

