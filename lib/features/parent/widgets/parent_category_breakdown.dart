import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

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
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderLight, width: 0.5),
      ),
      child: Column(
        children: [
          _buildRow(context, 'Makanan', foodPct, foodNominal, Nebula.teal),
          const SizedBox(height: 16),
          _buildRow(context, 'Minuman', drinkPct, drinkNominal, Nebula.amber),
          const SizedBox(height: 16),
          _buildRow(context, 'Camilan', snackPct, snackNominal, Nebula.amber),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, String title, double percentage, double nominal, Color barColor) {
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
                color: context.textPrimary,
              ),
            ),
            Text(
              CurrencyFormatter.format(nominal),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: context.textSecondary,
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
            backgroundColor: context.surfaceBg,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}
