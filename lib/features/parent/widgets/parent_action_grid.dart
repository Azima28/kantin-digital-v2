import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';

class ParentActionGrid extends StatelessWidget {
  final double totalSpending;
  final String selectedPeriod;

  const ParentActionGrid({
    super.key,
    required this.totalSpending,
    required this.selectedPeriod,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = AppColors.teal;
    const Color orangeAccent = AppColors.darkOrange;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Belanja',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textGray,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.format(totalSpending),
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: primaryTeal),
              ),
            ],
          ),
          Container(width: 1, height: 40, color: AppColors.borderGray),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Rata-rata Harian',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textGray,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.format(
                  totalSpending /
                      (selectedPeriod == 'Hari Ini'
                          ? 1
                          : (selectedPeriod == 'Minggu Ini' ? 7 : 30)),
                ),
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: orangeAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ParentCategoryProgressRow extends StatelessWidget {
  final String title;
  final double percentage;
  final double nominal;
  final Color barColor;

  const ParentCategoryProgressRow({
    super.key,
    required this.title,
    required this.percentage,
    required this.nominal,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$title (${percentage.toStringAsFixed(0)}%)',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark),
            ),
            Text(
              CurrencyFormatter.format(nominal),
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textGray),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: (percentage / 100).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.lightGray,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}

class ParentDailyLimitCard extends StatelessWidget {
  final double? dailyLimit;
  final double todaySpending;

  const ParentDailyLimitCard({
    super.key,
    this.dailyLimit,
    required this.todaySpending,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = AppColors.teal;

    if (dailyLimit == null || dailyLimit! <= 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderGray, width: 1),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Batas saku harian tidak diaktifkan.',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textGray,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),
      );
    }

    final double limit = dailyLimit!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Batas Pengeluaran',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textGray,
                    fontWeight: FontWeight.w500),
              ),
              Text(
                '${CurrencyFormatter.format(todaySpending)} / ${CurrencyFormatter.format(limit)}',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (todaySpending / limit).clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: AppColors.lightGray,
              valueColor: AlwaysStoppedAnimation<Color>(
                (todaySpending / limit) > 0.9
                    ? AppColors.errorRed2
                    : primaryTeal,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Terpakai ${((todaySpending / limit) * 100).toStringAsFixed(0)}% hari ini.',
            style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textGray,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
