import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

/// Step 3 of the keuangan correction flow — confirmation.
///
/// Displays a summary card with correction details and a "Proses Koreksi" button.
class KeuanganCorrectionStepConfirm extends StatelessWidget {
  final NumberFormat fmt;
  final String studentName;
  final String studentClass;
  final int studentBalance;
  final int amount;
  final bool isAddition;
  final String reason;
  final bool isLoading;
  final VoidCallback onProcess;

  const KeuanganCorrectionStepConfirm({
    super.key,
    required this.fmt,
    required this.studentName,
    required this.studentClass,
    required this.studentBalance,
    required this.amount,
    required this.isAddition,
    required this.reason,
    required this.isLoading,
    required this.onProcess,
  });

  @override
  Widget build(BuildContext context) {
    final int newBalance =
        isAddition ? studentBalance + amount : studentBalance - amount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Confirm Bento Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.04),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⚠️ RINGKASAN KOREKSI SALDO',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: AppColors.errorRed2,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Nama Siswa', studentName),
              const Divider(
                height: 16,
                thickness: 0.5,
                color: AppColors.borderGray,
              ),
              _buildInfoRow('Kelas', 'Kelas $studentClass'),
              const Divider(
                height: 16,
                thickness: 0.5,
                color: AppColors.borderGray,
              ),
              _buildInfoRow('Saldo Lama', fmt.format(studentBalance)),
              const Divider(
                height: 16,
                thickness: 0.5,
                color: AppColors.borderGray,
              ),
              _buildInfoRow(
                'Koreksi',
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
              _buildInfoRow(
                'Saldo Baru',
                fmt.format(newBalance),
                isBold: true,
                valueColor: AppColors.darkTeal,
              ),
              const Divider(
                height: 16,
                thickness: 0.5,
                color: AppColors.borderGray,
              ),
              _buildInfoRow('Alasan Koreksi', reason),
            ],
          ),
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : onProcess,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed2,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const CupertinoActivityIndicator(color: AppColors.white)
                : Text(
                    '✔ KUNCI & PROSES KOREKSI',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Aksi ini memerlukan konfirmasi keamanan tambahan.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.mutedGray,
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
