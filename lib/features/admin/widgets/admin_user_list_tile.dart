import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/models/models.dart';

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

    // Build descriptive subtitle
    String subText = '';
    if (role == 'student') {
      subText = 'NISN: ${nisn.isNotEmpty ? nisn : "-"} • USN: $username';
    } else if (role == 'petugas_kantin') {
      subText = 'USN: $username';
    } else if (role == 'petugas_keuangan') {
      subText = 'TU • USN: $username';
    } else if (role == 'parent') {
      subText = 'Email: $email';
    } else {
      subText = 'Email: $email';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Avatar profile picture
              CircleAvatar(
                radius: 20,
                backgroundColor: Nebula.teal.withValues(alpha: 0.1),
                child: Icon(
                  role == 'student'
                      ? CupertinoIcons.person
                      : (role == 'petugas_kantin'
                          ? Icons.shopping_bag
                          : CupertinoIcons.person_solid),
                  color: Nebula.teal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        // Role badge chip
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Nebula.teal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            getRoleLabel(role),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Nebula.teal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subText,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 0.5, color: context.dividerCol),
          const SizedBox(height: 12),

          // Cupertino Switch & Action button
          LayoutBuilder(
            builder: (context, constraints) {
              final statusControl = Row(
                children: [
                  Text(
                    'Status: ',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: context.textSecondary,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      isActive ? 'AKTIF' : 'DIBLOKIR',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color:
                            isActive ? Nebula.teal : Nebula.rose,
                      ),
                    ),
                  ),
                  SizedBox(width: 6),
                  SizedBox(
                    width: 44,
                    height: 28,
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
              );

              final detailLink = InkWell(
                onTap: () => onNavigateToDetail(id, role),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${AppStrings.titleDetail} & Riwayat',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Nebula.teal,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 14,
                        color: Nebula.teal,
                      ),
                    ],
                  ),
                ),
              );

              if (constraints.maxWidth < 330) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    statusControl,
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: detailLink,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: statusControl),
                  const SizedBox(width: 12),
                  detailLink,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
