import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/kantin/providers/nfc_payment_provider.dart';
import 'package:kantin_digital/features/kantin/widgets/nfc_data_row.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

class NfcVerifyingStudentUi extends StatelessWidget {
  const NfcVerifyingStudentUi({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 40),
        CupertinoActivityIndicator(radius: 16, color: Nebula.teal),
        SizedBox(height: 20),
        Text(
          'Sedang Memverifikasi Kartu...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        SizedBox(height: 40),
      ],
    );
  }
}

class NfcConfirmingPaymentUi extends ConsumerWidget {
  final int totalAmount;
  final bool isConfirming;
  final VoidCallback? onConfirm;

  const NfcConfirmingPaymentUi({
    super.key,
    required this.totalAmount,
    required this.isConfirming,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentState = ref.watch(nfcPaymentProvider);

    return Column(
      children: [
        Text(
          '${AppStrings.titleConfirmation} Pembayaran',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.surfaceBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.borderLight, width: 0.5),
          ),
          child: Column(
            children: [
              NfcDataRow('Nama Siswa', paymentState.studentName ?? '-'),
              Divider(color: context.borderLight, height: 24, thickness: 0.5),
              NfcDataRow('Kelas', paymentState.studentClass ?? '-'),
              Divider(color: context.borderLight, height: 24, thickness: 0.5),
              NfcDataRow(
                'Saldo Kartu',
                CurrencyFormatter.format(paymentState.studentBalance),
                valueColor: Nebula.teal,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Recipient Totals Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Nebula.teal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Nebula.teal.withValues(alpha: 0.15), width: 0.5),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Belanja', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.textPrimary)),
                  Text(CurrencyFormatter.format(totalAmount), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.textPrimary)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sisa Saldo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Nebula.teal)),
                  Text(
                    CurrencyFormatter.format(paymentState.studentBalance - totalAmount),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Nebula.teal),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Confirm Pay Action button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Nebula.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
            ),
            onPressed: isConfirming ? null : onConfirm,
            child: Text(
              'KONFIRMASI BAYAR',
              style: TextStyle(
                color: context.cardBg,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class NfcInsufficientBalanceUi extends ConsumerWidget {
  final int totalAmount;

  const NfcInsufficientBalanceUi({super.key, required this.totalAmount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentState = ref.watch(nfcPaymentProvider);

    return Column(
      children: [
        const Icon(CupertinoIcons.clear_circled_solid, size: 54, color: Nebula.rose),
        const SizedBox(height: 12),
        Text(
          '${AppStrings.labelTransaction} Ditolak',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Nebula.rose,
          ),
        ),
        Text(
          'Saldo Kartu Siswa Tidak Mencukupi',
          style: TextStyle(
            fontSize: 12,
            color: context.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.surfaceBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.borderLight, width: 0.5),
          ),
          child: Column(
            children: [
              NfcDataRow('Nama Siswa', paymentState.studentName ?? '-'),
              Divider(color: context.borderLight, height: 24, thickness: 0.5),
              NfcDataRow('Kelas', paymentState.studentClass ?? '-'),
              Divider(color: context.borderLight, height: 24, thickness: 0.5),
              NfcDataRow(
                'Saldo Tersedia',
                CurrencyFormatter.format(paymentState.studentBalance),
              ),
              Divider(color: context.borderLight, height: 24, thickness: 0.5),
              NfcDataRow(
                'Wajib Bayar',
                CurrencyFormatter.format(totalAmount),
              ),
              Divider(color: context.borderLight, height: 24, thickness: 0.5),
              NfcDataRow(
                'Kurang',
                '- ${CurrencyFormatter.format(totalAmount - paymentState.studentBalance)}',
                valueColor: Nebula.rose,
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.textSecondary.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
            ),
            onPressed: null, // Disabled
            child: Text(
              'SALDO TIDAK CUKUP',
              style: TextStyle(
                color: context.cardBg,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class NfcProcessingUi extends StatelessWidget {
  final String message;

  const NfcProcessingUi({super.key, this.message = 'Sedang Memotong Saldo...'});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 40),
        CupertinoActivityIndicator(radius: 16, color: Nebula.teal),
        SizedBox(height: 20),
        Text(
          'Sedang Memotong Saldo...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        SizedBox(height: 40),
      ],
    );
  }
}

class NfcSuccessUi extends StatelessWidget {
  const NfcSuccessUi({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 20),
        SizedBox(
          width: 80,
          height: 80,
          child: CircleAvatar(
            backgroundColor: Nebula.teal.withValues(alpha: 0.1),
            child: Icon(CupertinoIcons.checkmark_alt, size: 64, color: Nebula.teal),
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Jajan Berhasil!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Nebula.teal,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Saldo berhasil dipotong, transaksi telah dicatat.',
          style: TextStyle(
            fontSize: 13,
            color: context.textSecondary,
          ),
        ),
        SizedBox(height: 40),
      ],
    );
  }
}

class NfcErrorUi extends ConsumerWidget {
  final VoidCallback onRetry;

  const NfcErrorUi({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentState = ref.watch(nfcPaymentProvider);

    return Column(
      children: [
        const Icon(CupertinoIcons.exclamationmark_triangle_fill, size: 54, color: Nebula.rose),
        const SizedBox(height: 12),
        Text(
          '${AppStrings.labelTransaction} ${AppStrings.labelFailed}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Nebula.rose,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Nebula.rose.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Nebula.rose.withValues(alpha: 0.2), width: 0.5),
          ),
          child: Text(
            paymentState.errorMessage ?? 'Terjadi kesalahan tidak dikenal.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Nebula.rose,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Retry / Reset Scan Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Nebula.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
            ),
            onPressed: onRetry,
            child: Text(
              'KEMBALI SCAN',
              style: TextStyle(
                color: context.cardBg,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}