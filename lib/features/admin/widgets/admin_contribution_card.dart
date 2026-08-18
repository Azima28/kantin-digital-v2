import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/features/admin/widgets/admin_bento_card.dart';

class _RoleSegment {
  final String label;
  final int count;
  final Color color;

  const _RoleSegment({
    required this.label,
    required this.count,
    required this.color,
  });
}

/// Role contribution card showing student/canteen/parent/finance activity with real segmented donut chart.
class AdminContributionCard extends StatelessWidget {
  final Map<String, int> roleCounts;
  final int totalUsers;

  const AdminContributionCard({
    super.key,
    this.roleCounts = const {},
    this.totalUsers = 0,
  });

  @override
  Widget build(BuildContext context) {
    final int studentCount = roleCounts['student'] ?? 0;
    final int canteenCount = roleCounts['petugas_kantin'] ?? 0;
    final int parentCount = roleCounts['parent'] ?? 0;
    final int financeCount = roleCounts['petugas_keuangan'] ?? 0;
    final int adminCount = (roleCounts['super_admin'] ?? 0) + (roleCounts['admin'] ?? 0);
    final int computedTotal = totalUsers > 0
        ? totalUsers
        : (studentCount + canteenCount + parentCount + financeCount + adminCount);

    final segments = [
      _RoleSegment(label: 'Siswa', count: studentCount, color: Nebula.teal),
      _RoleSegment(label: 'Petugas Kantin', count: canteenCount, color: Nebula.amber),
      _RoleSegment(label: 'Orang Tua', count: parentCount, color: const Color(0xFF06B6D4)),
      if (financeCount > 0)
        _RoleSegment(label: 'Keuangan', count: financeCount, color: const Color(0xFF10B981)),
      if (adminCount > 0)
        _RoleSegment(label: 'Admin', count: adminCount, color: const Color(0xFF6366F1)),
    ];

    return AdminBentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Role Activity',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Nebula.teal,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Nebula.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$computedTotal User',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Nebula.teal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Segmented Donut Chart
          Center(
            child: SizedBox(
              width: 90,
              height: 90,
              child: CustomPaint(
                painter: _DonutChartPainter(
                  segments: segments,
                  total: computedTotal,
                  bgColor: context.dividerCol.withValues(alpha: 0.2),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$computedTotal',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Role Legends with Counts
          ...segments.map((seg) {
            final double pct = computedTotal > 0 ? (seg.count / computedTotal * 100) : 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: seg.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      seg.label,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: context.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '${seg.count} (${pct.toStringAsFixed(0)}%)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<_RoleSegment> segments;
  final int total;
  final Color bgColor;

  _DonutChartPainter({
    required this.segments,
    required this.total,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 5;
    const strokeWidth = 10.0;

    // Background track circle
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    if (total <= 0) return;

    double startAngle = -pi / 2;
    for (final seg in segments) {
      if (seg.count <= 0) continue;
      final sweepAngle = (seg.count / total) * 2 * pi;

      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      // Draw segment arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.total != total || oldDelegate.segments != segments;
  }
}
