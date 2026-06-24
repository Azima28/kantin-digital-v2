import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kantin_digital/core/constants/app_colors.dart';

// ── Reusable Card ──

Widget buildProfileCard({required Widget child}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

// ── Section Header ──

Widget buildSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textGray,
        letterSpacing: 0.5,
      ),
    ),
  );
}

// ── Icon Row (label + value) ──

Widget buildIconRow({
  required IconData icon,
  required Color iconColor,
  required String label,
  required String value,
  bool showDivider = false,
}) {
  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
      if (showDivider)
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          child: Divider(
            height: 1,
            thickness: 0.5,
            color: AppColors.borderLight,
          ),
        ),
    ],
  );
}

// ── Icon Action Row (tappable) ──

Widget buildIconActionRow({
  required IconData icon,
  required Color iconColor,
  required String label,
  Color? textColor,
  required VoidCallback onTap,
  bool showDivider = false,
}) {
  return Column(
    children: [
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor ?? AppColors.textDark,
                  ),
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: AppColors.textGray,
              ),
            ],
          ),
        ),
      ),
      if (showDivider)
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          child: Divider(
            height: 1,
            thickness: 0.5,
            color: AppColors.borderLight,
          ),
        ),
    ],
  );
}
