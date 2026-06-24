import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/widgets/logout_confirmation_dialog.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

/// Dashboard header with logout button, title, and notification bell.
class ParentDashboardHeader extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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
            onPressed: () async {
              final confirmed = await showLogoutConfirmationDialog(context);
              if (confirmed == true && context.mounted) {
                await ref.read(authNotifierProvider.notifier).logout();
              }
            },
            icon: const Icon(Icons.logout,
                size: 16, color: AppColors.primary),
            label: Text(
              'Keluar',
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
