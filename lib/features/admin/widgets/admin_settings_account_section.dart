import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/features/admin/widgets/setting_section_widget.dart';
import 'package:kantin_digital/features/admin/widgets/setting_tile_widget.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

/// Account & Security section used inside [AdminSettingsScreen].
///
/// Displays profile card and logout button.
class AdminSettingsAccountSection extends StatelessWidget {
  final String fullName;
  final String email;
  final VoidCallback onLogout;

  const AdminSettingsAccountSection({
    super.key,
    required this.fullName,
    required this.email,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SettingSectionWidget(
      icon: CupertinoIcons.person_solid,
      title: 'Akun & Keamanan',
      children: [
        SettingTileWidget(
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.darkTeal.withValues(alpha: 0.1),
            child: Text(
              fullName.isNotEmpty ? fullName[0].toUpperCase() : 'S',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkTeal,
              ),
            ),
          ),
          title: fullName,
          subtitle: email,
          trailing: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.darkTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              'Super Admin',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: AppColors.darkTeal,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Logout Button
        ElevatedButton.icon(
          onPressed: onLogout,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.errorLightColor,
            foregroundColor: AppColors.errorRed2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            elevation: 0,
          ),
          icon: const Icon(CupertinoIcons.square_arrow_right, size: 18),
          label: const Text(
            'KELUAR DARI AKUN',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
