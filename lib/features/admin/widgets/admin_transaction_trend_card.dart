import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/features/admin/widgets/admin_bento_card.dart';
import 'package:kantin_digital/features/admin/widgets/admin_trend_chart_painter.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';

/// Transaction trend card with a trend line chart.
class AdminTransactionTrendCard extends StatelessWidget {
  final List<num> dailyTrend;

  const AdminTransactionTrendCard({super.key, required this.dailyTrend});

  @override
  Widget build(BuildContext context) {
    return AdminBentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tren Transaksi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Nebula.teal,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: context.dividerCol,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '30 Hari',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.textSecondary,
                    letterSpacing: 0.05,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: TrendChartPainter(Nebula.teal, dailyTrend),
            ),
          ),
        ],
      ),
    );
  }
}
