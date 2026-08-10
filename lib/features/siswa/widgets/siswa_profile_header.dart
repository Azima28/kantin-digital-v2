import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

class SiswaProfileHeader extends StatelessWidget {
  final String fullName;
  final String nis;
  final String studentClass;
  final String? avatarUrl;
  final VoidCallback onAvatarTap;

  const SiswaProfileHeader({
    super.key,
    required this.fullName,
    required this.nis,
    required this.studentClass,
    this.avatarUrl,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.cardBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: onAvatarTap,
                  child: Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.borderLight,
                        ),
                        child: ClipOval(
                          child: avatarUrl != null && avatarUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: avatarUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const Center(child: CupertinoActivityIndicator()),
                                  errorWidget: (_, __, ___) => const Icon(
                                    CupertinoIcons.person,
                                    color: Nebula.teal,
                                    size: 40,
                                  ),
                                )
                              : const Icon(
                                  CupertinoIcons.person,
                                  color: Nebula.teal,
                                  size: 40,
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Nebula.teal,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.camera,
                            color: context.cardBg,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  fullName,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'NIS: $nis \u2022 Kelas $studentClass',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}