import 'package:flutter/material.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';

/// A theme-aware Shimmer animation wrapper.
class Shimmer extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final Color? baseColor;
  final Color? highlightColor;

  const Shimmer({
    super.key,
    required this.child,
    this.enabled = true,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBaseColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF1F5F9);
    final defaultHighlightColor = isDark
        ? const Color(0xFF334155)
        : Colors.white;

    final base = widget.baseColor ?? defaultBaseColor;
    final highlight = widget.highlightColor ?? defaultHighlightColor;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                base,
                highlight,
                base,
              ],
              stops: const [0.15, 0.5, 0.85],
              transform: _SlidingGradientTransform(slidePercent: _controller.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent - 0.5) * 2, 0.0, 0.0);
  }
}

/// A sleek white/light rectangular shimmer animation box designed for image and card placeholders.
class ShimmerRect extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;
  final EdgeInsetsGeometry? margin;

  const ShimmerRect({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.baseColor,
    this.highlightColor,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBase = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final defaultHighlight = isDark ? const Color(0xFF334155) : Colors.white;

    final base = baseColor ?? defaultBase;
    final highlight = highlightColor ?? defaultHighlight;

    return Container(
      margin: margin,
      child: Shimmer(
        baseColor: base,
        highlightColor: highlight,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}

/// A basic rectangular or rounded skeleton placeholder box.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
    this.color,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? defaultColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// A circular skeleton placeholder (for avatars, icon badges, etc.).
class SkeletonCircle extends StatelessWidget {
  final double size;
  final Color? color;

  const SkeletonCircle({
    super.key,
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? defaultColor,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// A card skeleton container with border and background matching Hallmark style.
class SkeletonCardContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double? height;
  final double? width;

  const SkeletonCardContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.borderRadius = 16,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: context.borderLight,
          width: 0.8,
        ),
      ),
      child: child,
    );
  }
}

/// A standard list tile skeleton (Icon/Avatar + Title + Subtitle + Trailing Badge).
class SkeletonListTile extends StatelessWidget {
  final bool hasLeading;
  final double leadingSize;
  final bool isCircleLeading;
  final bool hasTrailing;
  final EdgeInsetsGeometry? margin;

  const SkeletonListTile({
    super.key,
    this.hasLeading = true,
    this.leadingSize = 40,
    this.isCircleLeading = true,
    this.hasTrailing = true,
    this.margin = const EdgeInsets.only(bottom: 10),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SkeletonCardContainer(
        margin: margin,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (hasLeading) ...[
              if (isCircleLeading)
                SkeletonCircle(size: leadingSize)
              else
                SkeletonBox(width: leadingSize, height: leadingSize, borderRadius: 10),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SkeletonBox(width: 130, height: 14, borderRadius: 4),
                  const SizedBox(height: 8),
                  const SkeletonBox(width: 80, height: 11, borderRadius: 4),
                ],
              ),
            ),
            if (hasTrailing) ...[
              const SizedBox(width: 12),
              const SkeletonBox(width: 64, height: 22, borderRadius: 8),
            ],
          ],
        ),
      ),
    );
  }
}

/// Order item card skeleton tailored to match OrderItemCard in POS.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.borderLight, width: 0.8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: context.borderLight,
                  width: 6,
                ),
              ),
            ),
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header: Name + Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    SkeletonBox(width: 130, height: 16, borderRadius: 4),
                    SkeletonBox(width: 80, height: 24, borderRadius: 8),
                  ],
                ),
                const SizedBox(height: 8),
                // Time & code
                Row(
                  children: const [
                    SkeletonBox(width: 50, height: 12, borderRadius: 4),
                    SizedBox(width: 10),
                    SkeletonBox(width: 60, height: 16, borderRadius: 4),
                  ],
                ),
                const SizedBox(height: 16),
                // Item rows
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    SkeletonBox(width: 140, height: 14, borderRadius: 4),
                    SkeletonBox(width: 60, height: 14, borderRadius: 4),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    SkeletonBox(width: 100, height: 14, borderRadius: 4),
                    SkeletonBox(width: 50, height: 14, borderRadius: 4),
                  ],
                ),
                const SizedBox(height: 14),
                // Divider
                Container(
                  height: 0.8,
                  color: context.borderLight,
                ),
                const SizedBox(height: 12),
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    SkeletonBox(width: 45, height: 15, borderRadius: 4),
                    SkeletonBox(width: 85, height: 16, borderRadius: 4),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A product grid card skeleton matching POS product grid & public menu catalog.
class SkeletonProductGridCard extends StatelessWidget {
  const SkeletonProductGridCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderLight, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area - sleek white rectangular shimmer placeholder
            Padding(
              padding: const EdgeInsets.all(6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 96,
                  width: double.infinity,
                  color: context.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonBox(width: 100, height: 14, borderRadius: 4),
                        SizedBox(height: 5),
                        SkeletonBox(width: 50, height: 10, borderRadius: 4),
                        SizedBox(height: 6),
                        SkeletonBox(width: 70, height: 14, borderRadius: 4),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        SkeletonBox(width: 38, height: 20, borderRadius: 10),
                        SkeletonBox(width: 48, height: 16, borderRadius: 4),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
