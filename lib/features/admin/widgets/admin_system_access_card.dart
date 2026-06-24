import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/features/admin/widgets/setting_section_widget.dart';
import 'package:kantin_digital/features/admin/widgets/setting_tile_widget.dart';

/// System Access / Maintenance mode card.
class AdminSystemAccessCard extends StatelessWidget {
  final bool isMaintenanceMode;
  final ValueChanged<bool> onMaintenanceChanged;

  const AdminSystemAccessCard({
    super.key,
    required this.isMaintenanceMode,
    required this.onMaintenanceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingSectionWidget(
      icon: CupertinoIcons.hammer,
      title: 'System Access',
      horizontalPadding: 16,
      verticalPadding: 16,
      iconRadius: 16,
      iconBackgroundColor: AppColors.errorLightColor,
      iconColor: AppColors.errorRed2,
      titleColor: AppColors.errorRed2,
      shadowBlurRadius: 15,
      children: [
        Text(
          'Mode pemeliharaan memblokir semua akses login non-admin.',
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AppColors.textGray,
          ),
        ),
        const SizedBox(height: 16),
        SettingTileWidget(
          title: 'Maintenance',
          trailing: SizedBox(
            width: 44,
            height: 28,
            child: FittedBox(
              fit: BoxFit.contain,
              child: CupertinoSwitch(
                value: isMaintenanceMode,
                activeTrackColor: AppColors.darkTeal,
                onChanged: onMaintenanceChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
