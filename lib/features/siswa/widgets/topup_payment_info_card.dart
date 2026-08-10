import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

class TopupPaymentInfoCard extends StatelessWidget {
  const TopupPaymentInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Nebula.teal.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Nebula.teal.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.qrcode_viewfinder,
              color: Nebula.teal,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Metode Pembayaran',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'QRIS / Virtual Account (Instan)',
                  style: TextStyle(
                    fontSize: 13,
                    color: Nebula.teal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mendukung pembayaran dari semua e-wallet (GoPay, OVO, Dana) dan mobile banking.',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textSecondary,
                    height: 1.35,
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