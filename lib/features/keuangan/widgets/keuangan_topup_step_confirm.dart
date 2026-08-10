import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';

/// Step 3 of the keuangan top-up flow — confirmation.
///
/// Displays a summary card with student details, old balance, top-up amount,
/// and new balance, plus a "Proses Top-Up" button.
class KeuanganTopupStepConfirm extends StatelessWidget {
  final NumberFormat fmt;
  final String studentName;
  final String studentNisn;
  final String studentClass;
  final int studentBalance;
  final int amount;
  final bool isLoading;
  final VoidCallback onProcess;

  const KeuanganTopupStepConfirm({
    super.key,
    required this.fmt,
    required this.studentName,
    required this.studentNisn,
    required this.studentClass,
    required this.studentBalance,
    required this.amount,
    required this.isLoading,
    required this.onProcess,
  });

  @override
  Widget build(BuildContext context) {
    final int newBalance = studentBalance + amount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Bento Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: context.shadowColor,
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📋 RINGKASAN TOP-UP TUNAI',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: Nebula.teal,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 16),
              _buildInfoRow(context, 'Nama Siswa', studentName),
              Divider(
                height: 16,
                thickness: 0.5,
                color: context.dividerCol,
              ),
              _buildInfoRow(context, 'NISN', studentNisn),
              Divider(
                height: 16,
                thickness: 0.5,
                color: context.dividerCol,
              ),
              _buildInfoRow(context, 'Kelas', 'Kelas $studentClass'),
              Divider(
                height: 16,
                thickness: 0.5,
                color: context.dividerCol,
              ),
              _buildInfoRow(context, 'Saldo Lama', fmt.format(studentBalance)),
              Divider(
                height: 16,
                thickness: 0.5,
                color: context.dividerCol,
              ),
              _buildInfoRow(
                context,
                'Nominal Top-Up',
                '+ ${fmt.format(amount)}',
                valueColor: Nebula.teal,
              ),
              Divider(
                height: 16,
                thickness: 0.5,
                color: context.dividerCol,
              ),
              _buildInfoRow(
                context,
                'Saldo Baru',
                fmt.format(newBalance),
                isBold: true,
                valueColor: Nebula.teal,
              ),
              Divider(
                height: 16,
                thickness: 0.5,
                color: context.dividerCol,
              ),
              _buildInfoRow(context, 'Metode', 'Tunai (Cash)'),
            ],
          ),
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : onProcess,
            style: ElevatedButton.styleFrom(
              backgroundColor: Nebula.amber,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const CupertinoActivityIndicator(color: Colors.white)
                : Text(
                    '✔ PROSES TOP-UP',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Aksi ini akan dicatat dalam audit log.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: context.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
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
            color: context.textSecondary,
            fontSize: 13,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? context.textPrimary,
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
