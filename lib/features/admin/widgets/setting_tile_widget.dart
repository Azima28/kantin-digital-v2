import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

/// A reusable setting tile used inside admin setting sections.
///
/// Displays an optional [leading] widget, a [title], an optional [subtitle],
/// an optional [trailing] widget, and responds to [onTap].
class SettingTileWidget extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? backgroundColor;

  const SettingTileWidget({
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
    this.borderRadius = 14,
    this.backgroundColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.offWhite2,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: subtitle != null ? 14 : 13,
                    fontWeight: subtitle != null ? FontWeight.w700 : FontWeight.w600,
                    color: AppColors.nearBlack,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: tile);
    }
    return tile;
  }
}
