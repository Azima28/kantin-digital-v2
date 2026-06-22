import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:google_fonts/google_fonts.dart';

class QrisCheckoutContent extends StatelessWidget {
  final double amount;
  final bool isLoading;
  final VoidCallback? onConfirm;
  final VoidCallback onCancel;

  const QrisCheckoutContent({
    super.key,
    required this.amount,
    required this.isLoading,
    this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // iOS grab handle
        Container(
          width: 36,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Simulasi QRIS Pembayaran',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          CurrencyFormatter.format(amount),
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 20),

        // Simulated QR Code Graphic Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight, width: 1),
          ),
          child: Column(
            children: [
              Container(
                width: 180,
                height: 180,
                color: AppColors.systemBackground,
                child: Center(
                  child: Icon(
                    Icons.qr_code_2,
                    size: 130,
                    color: AppColors.textDark.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'KANTIN DIGITAL COOPERATIVE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Pindai QRIS di atas menggunakan e-wallet atau Mobile Banking Anda.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textGray,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        // Action buttons
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: onConfirm,
            child: isLoading
                ? const CupertinoActivityIndicator(color: AppColors.white)
                : const Text(
                    'Simulasikan Pembayaran Berhasil',
                    style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onCancel,
            child: const Text(
              'Batalkan',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
