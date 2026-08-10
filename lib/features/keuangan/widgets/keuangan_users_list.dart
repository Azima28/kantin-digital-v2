import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';

class KeuanganStudentCard extends StatelessWidget {
  final StudentWithProfile student;
  final NumberFormat fmt;

  const KeuanganStudentCard({
    super.key,
    required this.student,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final hasCard = student.hasRfid == true;
    final className = student.class_ ?? 'Belum Diisi';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/finance/students/${student.id}'),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      Nebula.teal.withValues(alpha: 0.08),
                  child: Text(
                    student.fullName.isNotEmpty
                        ? student.fullName[0].toUpperCase()
                        : 'S',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Nebula.teal,
                    ),
                  ),
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
                          fontSize: 15,
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
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _statusPill(
                            hasCard ? 'AKTIF' : 'BELUM AKTIF',
                            hasCard
                                ? CupertinoIcons.checkmark_circle_fill
                                : CupertinoIcons.clear_circled_solid,
                            hasCard
                                ? Nebula.teal
                                : context.textSecondary,
                          ),
                          if (student.isActive != true)
                            _statusPill(
                              'DIBLOKIR',
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
                        fontSize: 15,
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
      ),
    );
  }

  Widget _statusPill(String text, IconData icon, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      );
}
