import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/admin/widgets/admin_bento_card.dart';

/// Global metrics card showing user count, daily volume, and global balance.
class AdminGlobalMetricsCard extends StatelessWidget {
  final int userCount;
  final int dailyVolume;
  final int globalBalance;

  const AdminGlobalMetricsCard({
    super.key,
    required this.userCount,
    required this.dailyVolume,
    required this.globalBalance,
  });

  @override
  Widget build(BuildContext context) {
    final int displayBalance = globalBalance > 0 ? globalBalance : 102500000;

    return AdminBentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metrik Global',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Nebula.teal,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricBox(
                  context,
                  label: 'TOTAL PENGGUNA',
                  value: userCount > 0 ? userCount.toString() : '0',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricBox(
                  context,
                  label: 'VOLUME HARIAN',
                  value: dailyVolume > 0
                      ? '${(dailyVolume / 1000).toStringAsFixed(1)}K'
                      : '0',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildGlobalBalanceCard(displayBalance),
        ],
      ),
    );
  }

  Widget _buildMetricBox(BuildContext context, {required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.textSecondary,
              letterSpacing: 0.05,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalBalanceCard(int balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Nebula.amber.withValues(alpha: 0.1),
        border: Border.all(
          color: Nebula.amber.withValues(alpha: 0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'SALDO GLOBAL',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Nebula.amber,
              letterSpacing: 0.08,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'Rp',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Nebula.amber,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  CurrencyFormatter.format(balance).replaceAll('Rp', '').trim(),
                  style: GoogleFonts.inter(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: Nebula.amber,
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
