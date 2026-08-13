import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';

class LoginPreviewItem extends StatelessWidget {
  final String roleName;
  final String identifier;
  final String password;
  final VoidCallback onTap;

  const LoginPreviewItem({
    super.key,
    required this.roleName,
    required this.identifier,
    required this.password,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    final primaryTeal = isDark ? AppColors.tealConst : AppColors.darkTealConst;
    final textMuted = isDark ? AppColors.darkTextSecondaryVal : AppColors.lightTextSecondaryVal;
    final textCred = isDark ? AppColors.darkTextPrimaryVal : AppColors.lightTextPrimaryVal;
    final itemBg = isDark ? AppColors.darkInputFieldBg : AppColors.lightInputFieldBg;
    final itemBorder = isDark ? AppColors.darkInputFieldBorder : AppColors.lightInputFieldBorder;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: itemBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: itemBorder, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  roleName,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryTeal,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: textMuted,
                      fontWeight: FontWeight.w400,
                    ),
                    children: [
                      const TextSpan(text: 'user: '),
                      TextSpan(
                        text: identifier,
                        style: GoogleFonts.poppins(
                          color: textCred,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: ' | pass: '),
                      TextSpan(
                        text: password,
                        style: GoogleFonts.poppins(
                          color: textCred,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryTeal.withValues(alpha: isDark ? 0.15 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: primaryTeal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


