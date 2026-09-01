import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/features/admin/widgets/setting_section_widget.dart';
import 'package:kantin_digital/features/admin/widgets/setting_tile_widget.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/app_avatar.dart';

/// Account & Security section used inside [AdminSettingsScreen].
///
/// Displays profile card and logout button.
class AdminSettingsAccountSection extends StatelessWidget {
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String? gender;
  final VoidCallback onLogout;

  const AdminSettingsAccountSection({
    super.key,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    this.gender,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SettingSectionWidget(
      icon: CupertinoIcons.person_solid,
      title: 'Akun & Keamanan',
      children: [
        SettingTileWidget(
          leading: AppAvatar(
            radius: 20,
            photoUrl: avatarUrl,
            role: 'admin',
            name: fullName,
            gender: gender,
          ),
          title: fullName,
          subtitle: email,
          trailing: Container(
            padding:
                EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Nebula.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              'Super Admin',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Nebula.teal,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Logout Button
        ElevatedButton.icon(
          onPressed: onLogout,
          style: ElevatedButton.styleFrom(
            backgroundColor: Nebula.rose.withValues(alpha: 0.1),
            foregroundColor: Nebula.rose,
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
