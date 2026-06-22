import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

/// Success screen displayed after a successful balance correction.
class KeuanganCorrectionSuccessScreen extends StatelessWidget {
  final NumberFormat fmt;
  final String studentName;
  final int studentBalance;
  final int amount;
  final bool isAddition;
  final String successTime;
  final String refCode;

  const KeuanganCorrectionSuccessScreen({
    super.key,
    required this.fmt,
    required this.studentName,
    required this.studentBalance,
    required this.amount,
    required this.isAddition,
    required this.successTime,
    required this.refCode,
  });

  @override
  Widget build(BuildContext context) {
    final int newBalance =
        isAddition ? studentBalance + amount : studentBalance - amount;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        // Success Icon
        Container(
          height: 80,
          width: 80,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.errorLight,
          ),
          child: const Center(
            child: Icon(
              CupertinoIcons.checkmark_shield_fill,
              color: AppColors.errorRed2,
              size: 56,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Koreksi Berhasil!',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.darkTeal,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Saldo $studentName berhasil disesuaikan.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.mutedGray,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),

        // Detail Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: Column(
            children: [
              _buildInfoRow('Saldo Sebelum', fmt.format(studentBalance)),
              const Divider(
                height: 16,
                thickness: 0.5,
                color: AppColors.borderGray,
              ),
              _buildInfoRow(
                'Penyesuaian',
                '${isAddition ? "+" : "-"}${fmt.format(amount)}',
                valueColor:
                    isAddition ? AppColors.successGreen : AppColors.errorRed2,
                isBold: true,
              ),
              const Divider(
                height: 16,
                thickness: 0.5,
                color: AppColors.borderGray,
              ),
              _buildInfoRow('Saldo Baru', fmt.format(newBalance), isBold: true),
              const Divider(
                height: 16,
                thickness: 0.5,
                color: AppColors.borderGray,
              ),
              _buildInfoRow('Waktu Transaksi', successTime),
              const Divider(
                height: 16,
                thickness: 0.5,
                color: AppColors.borderGray,
              ),
              _buildInfoRow('Kode Koreksi', refCode),
            ],
          ),
        ),

        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              context.go('/finance');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkTeal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'KEMBALI KE BERANDA',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.mutedGray,
            fontSize: 13,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? AppColors.nearBlack,
              fontSize: 13,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
