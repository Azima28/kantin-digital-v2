import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/kantin/providers/nfc_payment_provider.dart';
import 'package:kantin_digital/features/kantin/widgets/nfc_data_row.dart';

class NfcVerifyingStudentUi extends StatelessWidget {
  const NfcVerifyingStudentUi({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: 40),
        CupertinoActivityIndicator(radius: 16, color: AppColors.primary),
        SizedBox(height: 20),
        Text(
          'Sedang Memverifikasi Kartu...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
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
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.systemBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight, width: 0.5),
          ),
          child: Column(
            children: [
              NfcDataRow('Nama Siswa', paymentState.studentName ?? '-'),
              const Divider(color: AppColors.borderLight, height: 24, thickness: 0.5),
              NfcDataRow('Kelas', paymentState.studentClass ?? '-'),
              const Divider(color: AppColors.borderLight, height: 24, thickness: 0.5),
              NfcDataRow(
                'Saldo Kartu',
                CurrencyFormatter.format(paymentState.studentBalance),
                valueColor: AppColors.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Recipient Totals Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 0.5),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Belanja', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark)),
                  Text(CurrencyFormatter.format(totalAmount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sisa Saldo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  Text(
                    CurrencyFormatter.format(paymentState.studentBalance - totalAmount),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary),
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
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
            ),
            onPressed: isConfirming ? null : onConfirm,
            child: const Text(
              'KONFIRMASI BAYAR',
              style: TextStyle(
                color: AppColors.white,
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
        const Icon(CupertinoIcons.clear_circled_solid, size: 54, color: AppColors.error),
        const SizedBox(height: 12),
        const Text(
          '${AppStrings.labelTransaction} Ditolak',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.error,
          ),
        ),
        const Text(
          'Saldo Kartu Siswa Tidak Mencukupi',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.systemBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight, width: 0.5),
          ),
          child: Column(
            children: [
              NfcDataRow('Nama Siswa', paymentState.studentName ?? '-'),
              const Divider(color: AppColors.borderLight, height: 24, thickness: 0.5),
              NfcDataRow('Kelas', paymentState.studentClass ?? '-'),
              const Divider(color: AppColors.borderLight, height: 24, thickness: 0.5),
              NfcDataRow(
                'Saldo Tersedia',
                CurrencyFormatter.format(paymentState.studentBalance),
              ),
              const Divider(color: AppColors.borderLight, height: 24, thickness: 0.5),
              NfcDataRow(
                'Wajib Bayar',
                CurrencyFormatter.format(totalAmount),
              ),
              const Divider(color: AppColors.borderLight, height: 24, thickness: 0.5),
              NfcDataRow(
                'Kurang',
                '- ${CurrencyFormatter.format(totalAmount - paymentState.studentBalance)}',
                valueColor: AppColors.error,
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textGray.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
            ),
            onPressed: null, // Disabled
            child: const Text(
              'SALDO TIDAK CUKUP',
              style: TextStyle(
                color: AppColors.white,
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
    return const Column(
      children: [
        SizedBox(height: 40),
        CupertinoActivityIndicator(radius: 16, color: AppColors.primary),
        SizedBox(height: 20),
        Text(
          'Sedang Memotong Saldo...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
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
    return const Column(
      children: [
        SizedBox(height: 20),
        SizedBox(
          width: 80,
          height: 80,
          child: CircleAvatar(
            backgroundColor: AppColors.successLight,
            child: Icon(CupertinoIcons.checkmark_alt, size: 64, color: AppColors.success),
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Jajan Berhasil!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Saldo berhasil dipotong, transaksi telah dicatat.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textGray,
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
        const Icon(CupertinoIcons.exclamationmark_triangle_fill, size: 54, color: AppColors.error),
        const SizedBox(height: 12),
        const Text(
          '${AppStrings.labelTransaction} ${AppStrings.labelFailed}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.error,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.errorLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.2), width: 0.5),
          ),
          child: Text(
            paymentState.errorMessage ?? 'Terjadi kesalahan tidak dikenal.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.error,
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
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
            ),
            onPressed: onRetry,
            child: const Text(
              'KEMBALI SCAN',
              style: TextStyle(
                color: AppColors.white,
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
