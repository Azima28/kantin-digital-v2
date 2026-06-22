import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';

/// Category breakdown bars showing spending by category.
class ParentCategoryBreakdown extends StatelessWidget {
  final double foodPct;
  final double drinkPct;
  final double snackPct;
  final double foodNominal;
  final double drinkNominal;
  final double snackNominal;

  const ParentCategoryBreakdown({
    super.key,
    required this.foodPct,
    required this.drinkPct,
    required this.snackPct,
    required this.foodNominal,
    required this.drinkNominal,
    required this.snackNominal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray, width: 1),
      ),
      child: Column(
        children: [
          _buildRow('Makanan', foodPct, foodNominal, AppColors.primary),
          const SizedBox(height: 16),
          _buildRow('Minuman', drinkPct, drinkNominal, AppColors.darkOrange),
          const SizedBox(height: 16),
          _buildRow('Camilan', snackPct, snackNominal, AppColors.darkOrange),
        ],
      ),
    );
  }

  Widget _buildRow(String title, double percentage, double nominal, Color barColor) {
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
                color: AppColors.textDark,
              ),
            ),
            Text(
              CurrencyFormatter.format(nominal),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textGray,
              ),
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
