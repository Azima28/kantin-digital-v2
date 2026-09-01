import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/core/widgets/app_avatar.dart';

class KeuanganStudentCard extends StatelessWidget {
  final StudentWithProfile student;
  final AppNumberFormat fmt;
  final bool isFirst;
  final bool isLast;

  const KeuanganStudentCard({
    super.key,
    required this.student,
    required this.fmt,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasCard = student.hasRfid == true;
    final className = student.class_ ?? 'Belum Diisi';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/finance/students/${student.id}'),
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(16) : Radius.zero,
          bottom: isLast ? const Radius.circular(16) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              AppAvatar(
                radius: 22,
                photoUrl: student.avatarUrl,
                role: 'student',
                name: student.fullName,
                gender: student.gender,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'NISN: ${student.nisn ?? '-'} - Kelas $className',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (!hasCard)
                          _statusPill(
                            'BELUM TERDAFTAR',
                            CupertinoIcons.clear_circled_solid,
                            context.textSecondary,
                          )
                        else if (student.cardIsActive != true)
                          _statusPill(
                            'KARTU DIBLOKIR',
                            CupertinoIcons.lock_circle_fill,
                            Nebula.amber,
                          )
                        else
                          _statusPill(
                            'KARTU AKTIF',
                            CupertinoIcons.checkmark_circle_fill,
                            Nebula.teal,
                          ),
                        if (student.isActive != true)
                          _statusPill(
                            'AKUN DIBLOKIR',
                            CupertinoIcons.exclamationmark_circle_fill,
                            Nebula.rose,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Saldo',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fmt.format(student.balance),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: student.balance < 5000
                          ? Nebula.rose
                          : context.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusPill(String text, IconData icon, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      );
}
