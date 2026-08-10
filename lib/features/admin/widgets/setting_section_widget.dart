import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

/// A reusable section card used in admin settings screens.
///
/// Wraps [children] inside a white rounded container with an optional header
/// consisting of an [icon] inside a [CircleAvatar] and a [title].
class SettingSectionWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  final double horizontalPadding;
  final double verticalPadding;
  final double iconRadius;
  final Color? iconBackgroundColor;
  final Color? iconColor;
  final Color? titleColor;
  final double shadowBlurRadius;
  final double borderRadius;

  const SettingSectionWidget({
    required this.icon,
    required this.title,
    required this.children,
    this.horizontalPadding = 20,
    this.verticalPadding = 20,
    this.iconRadius = 18,
    this.iconBackgroundColor,
    this.iconColor,
    this.titleColor,
    this.shadowBlurRadius = 20,
    this.borderRadius = 24,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: shadowBlurRadius,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: iconRadius,
                backgroundColor: iconBackgroundColor ??
                    Nebula.teal.withValues(alpha: 0.1),
                child: Icon(icon, color: iconColor ?? Nebula.teal, size: iconRadius),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: iconRadius > 16 ? 17 : 15,
                  fontWeight: FontWeight.bold,
                  color: titleColor ?? Nebula.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
