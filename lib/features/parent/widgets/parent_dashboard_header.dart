import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

/// Dashboard header with back button, title, and notification bell.
class ParentDashboardHeader extends StatelessWidget {
  final int currentIndex;

  const ParentDashboardHeader({
    super.key,
    required this.currentIndex,
  });

  String _getTitle() {
    switch (currentIndex) {
      case 0:
        return 'Beranda Wali';
      case 1:
        return 'Analisis Jajan';
      case 2:
        return 'Riwayat Saku';
      case 3:
        return 'Pengaturan';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
            bottom: BorderSide(color: AppColors.borderGray, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => context.go('/parent'),
            icon: const Icon(CupertinoIcons.left_chevron,
                size: 14, color: AppColors.primary),
            label: Text(
              'Ganti NISN',
              style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                _getTitle(),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark),
              ),
            ),
          ),
          const Icon(CupertinoIcons.bell,
              color: AppColors.primary, size: 20),
        ],
      ),
    );
  }
}
