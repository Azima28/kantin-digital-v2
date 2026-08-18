import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/models/models.dart';

/// User card for the admin user list screen.
/// Styled according to the 2-column card design in the user screenshot.
class AdminUserListTile extends StatelessWidget {
  final UserProfile user;
  final String Function(String) getRoleLabel;
  final void Function(String, String, bool) onToggleStatus;
  final void Function(String, String) onNavigateToDetail;

  const AdminUserListTile({
    super.key,
    required this.user,
    required this.getRoleLabel,
    required this.onToggleStatus,
    required this.onNavigateToDetail,
  });

  @override
  Widget build(BuildContext context) {
    final String id = user.id;
    final String fullName = user.fullName ?? 'User Baru';
    final String role = user.role ?? 'student';
    final String email = user.email ?? '';
    final String username = user.username ?? '';
    final String nisn = user.nisn ?? '';
    final bool isActive = user.isActive ?? true;

    // Build descriptive subtitle matching screenshot
    String subText = '';
    if (role == 'student') {
      subText = 'NISN: ${nisn.isNotEmpty ? nisn : "-"} • USN: $username';
    } else if (role == 'petugas_kantin') {
      subText = 'USN: $username';
    } else if (role == 'petugas_keuangan') {
      subText = 'USN: $username';
    } else if (role == 'parent') {
      subText = 'USN: $username';
    } else {
      subText = 'Email: $email';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.dividerCol.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Avatar, Name & Subtitle, Role Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grey Circle Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: context.surfaceBg,
                child: Icon(
                  Icons.person,
                  color: context.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Name & Subtext
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: context.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Role Badge Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Nebula.teal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  getRoleLabel(role),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Nebula.teal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 0.5, color: context.dividerCol.withValues(alpha: 0.6)),
          const SizedBox(height: 10),

          // Bottom Row: Status Toggle & Detail Link
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status Label & Toggle
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Status: ',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: context.textSecondary,
                      ),
                    ),
                    Text(
                      isActive ? 'AKTIF' : 'DIBLOKIR',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isActive ? Nebula.teal : Nebula.rose,
                      ),
                    ),
                    const SizedBox(width: 3),
                    SizedBox(
                      width: 32,
                      height: 20,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: CupertinoSwitch(
                          value: isActive,
                          activeTrackColor: Nebula.teal,
                          onChanged: (val) => onToggleStatus(id, role, isActive),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 4),

              // Detail > Link
              InkWell(
                onTap: () => onNavigateToDetail(id, role),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Detail',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Nebula.teal,
                        ),
                      ),
                      const SizedBox(width: 1),
                      const Icon(
                        CupertinoIcons.chevron_right,
                        size: 11,
                        color: Nebula.teal,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
