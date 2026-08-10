import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
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
      iconBackgroundColor: Nebula.rose.withValues(alpha: 0.1),
      iconColor: Nebula.rose,
      titleColor: Nebula.rose,
      shadowBlurRadius: 15,
      children: [
        Text(
          'Mode pemeliharaan memblokir semua akses login non-admin.',
          style: GoogleFonts.inter(
            fontSize: 10,
            color: context.textSecondary,
          ),
        ),
        SizedBox(height: 16),
        SettingTileWidget(
          title: 'Maintenance',
          trailing: SizedBox(
            width: 44,
            height: 28,
            child: FittedBox(
              fit: BoxFit.contain,
              child: CupertinoSwitch(
                value: isMaintenanceMode,
                activeTrackColor: Nebula.teal,
                onChanged: onMaintenanceChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
