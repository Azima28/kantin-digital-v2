import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

/// Success screen widget displayed after a successful top-up by keuangan staff.
class KeuanganTopupSuccessScreen extends StatelessWidget {
  final String studentName;
  final int amount;
  final int newBalance;
  final String successTime;
  final String refCode;
  final NumberFormat fmt;

  const KeuanganTopupSuccessScreen({
    super.key,
    required this.studentName,
    required this.amount,
    required this.newBalance,
    required this.successTime,
    required this.refCode,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
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
            color: AppColors.successLight,
          ),
          child: const Center(
            child: Icon(
              CupertinoIcons.checkmark_alt_circle_fill,
              color: AppColors.successGreen,
              size: 56,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Top-Up Berhasil!',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.darkTeal,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Saldo $studentName berhasil ditambah.',
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
              _buildInfoRow(
                'Nominal Pengisian',
                fmt.format(amount),
                valueColor: AppColors.successGreen,
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
              _buildInfoRow('Kode Referensi', refCode),
            ],
          ),
        ),

        const SizedBox(height: 40),
        // Action Buttons
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Simulasi Cetak Struk: Struk dikirim ke printer thermal.',
                  ),
                  backgroundColor: AppColors.successGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(CupertinoIcons.printer_fill, size: 18),
            label: Text(
              'CETAK STRUK / BAGIKAN',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.darkTeal,
              side: const BorderSide(color: AppColors.darkTeal),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
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
                fontSize: 14,
                color: AppColors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.mutedGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: valueColor ?? AppColors.nearBlack,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
