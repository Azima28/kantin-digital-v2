import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

/// Weekly spending trend chart bar widget.
class ParentWeeklyTrendChart extends StatelessWidget {
  final List<double> weeklySpending;
  final double maxWeeklySpend;

  const ParentWeeklyTrendChart({
    super.key,
    required this.weeklySpending,
    required this.maxWeeklySpend,
  });

  @override
  Widget build(BuildContext context) {
    final daysOfWeek = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];

    return Container(
      height: 190,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final double value = weeklySpending[index];
          final double heightPct = maxWeeklySpend > 0 ? (value / maxWeeklySpend) : 0.0;
          final double barHeight = heightPct * 110;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                value > 0 ? '${(value / 1000).toStringAsFixed(0)}k' : '',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 18,
                height: barHeight < 4 ? 4 : barHeight,
                decoration: BoxDecoration(
                  color: value > 0 ? AppColors.primary : AppColors.offWhite2,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                daysOfWeek[index],
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
