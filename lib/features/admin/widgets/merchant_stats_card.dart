import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';

class MerchantDailySalesCard extends StatelessWidget {
  final double dailySales;

  const MerchantDailySalesCard({super.key, required this.dailySales});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DAILY SALES',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: context.textSecondary,
              letterSpacing: 0.05,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            CurrencyFormatter.format(dailySales),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '+12% from yesterday',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Nebula.teal,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class MerchantMonthlySalesCard extends StatelessWidget {
  final double monthlySales;

  const MerchantMonthlySalesCard({super.key, required this.monthlySales});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MONTHLY SALES',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: context.textSecondary,
              letterSpacing: 0.05,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            CurrencyFormatter.format(monthlySales),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'On track for target',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Nebula.teal,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
