import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';

class LoginAccountPreview extends StatelessWidget {
  final Widget child;
  final double? width;

  const LoginAccountPreview({super.key, required this.child, this.width});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    final primaryTeal = isDark ? AppColors.tealConst : AppColors.darkTealConst;
    final glassBorder = isDark ? AppColors.darkCardBorder : AppColors.lightInputFieldBorder;
    final glassBg = isDark ? AppColors.darkCardBg : AppColors.lightCardBg;
    final textMuted = isDark ? AppColors.darkTextSecondaryVal : AppColors.lightTextSecondaryVal;

    return Container(
      width: width ?? 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: glassBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glassBorder, width: 1),
        boxShadow: isDark
            ? []
            : [
                const BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: AKUN DEMO + info icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: primaryTeal.withValues(alpha: isDark ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.smart_toy_outlined,
                      size: 14,
                      color: primaryTeal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AKUN DEMO',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
              Tooltip(
                message: 'Gunakan akun ini untuk login',
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: primaryTeal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            height: 1,
            color: glassBorder,
          ),
          const SizedBox(height: 16),
          // Demo Account items
          child,
        ],
      ),
    );
  }
}



