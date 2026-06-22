import 'package:flutter/cupertino.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

class TopupPaymentInfoCard extends StatelessWidget {
  const TopupPaymentInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.qrcode_viewfinder,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Metode Pembayaran',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'QRIS / Virtual Account (Instan)',
                  style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  'Mendukung pembayaran dari semua e-wallet (GoPay, OVO, Dana) dan mobile banking.',
                  style: TextStyle(fontSize: 11, color: AppColors.textGray, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
