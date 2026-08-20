import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';

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
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Nebula.teal.withValues(alpha: 0.1),
          ),
          child: const Center(
            child: Icon(
              CupertinoIcons.checkmark_alt_circle_fill,
              color: Nebula.teal,
              size: 56,
            ),
          ),
        ),
        SizedBox(height: 24),
        Text(
          'Top-Up Berhasil!',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Nebula.teal,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Saldo $studentName berhasil ditambah.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: context.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),

        // Detail Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.dividerCol),
          ),
          child: Column(
            children: [
              _buildInfoRow(
                context,
                'Nominal Pengisian',
                fmt.format(amount),
                valueColor: Nebula.teal,
                isBold: true,
              ),
              Divider(
                height: 16,
                thickness: 0.5,
                color: context.dividerCol,
              ),
              _buildInfoRow(context, 'Saldo Baru', fmt.format(newBalance), isBold: true),
              Divider(
                height: 16,
                thickness: 0.5,
                color: context.dividerCol,
              ),
              _buildInfoRow(context, 'Waktu Transaksi', successTime),
              Divider(
                height: 16,
                thickness: 0.5,
                color: context.dividerCol,
              ),
              _buildInfoRow(context, 'Kode Referensi', refCode),
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
                  backgroundColor: Nebula.teal,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: Icon(CupertinoIcons.printer_fill, size: 18),
            label: Text(
              'CETAK STRUK / BAGIKAN',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Nebula.teal,
              side: BorderSide(color: Nebula.teal),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              context.go('/finance');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Nebula.teal,
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
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
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
            fontSize: 12.5,
            color: context.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: valueColor ?? context.textPrimary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
