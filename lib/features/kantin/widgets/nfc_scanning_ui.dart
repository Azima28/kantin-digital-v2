import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/core/widgets/nfc_pulse_animator.dart';
import 'package:kantin_digital/features/kantin/providers/nfc_payment_provider.dart';

class NfcScanningUi extends ConsumerWidget {
  final int totalAmount;

  const NfcScanningUi({super.key, required this.totalAmount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentState = ref.watch(nfcPaymentProvider);

    return Column(
      children: [
        const Text(
          'Total Pembayaran',
          style: TextStyle(
            color: AppColors.textGray,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          CurrencyFormatter.format(totalAmount),
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 32,
          ),
        ),
        const SizedBox(height: 20),

        // Scanning Indicator
        const NfcPulseAnimator(
          size: 100,
          color: AppColors.primary,
          child: Icon(
            CupertinoIcons.antenna_radiowaves_left_right,
            color: AppColors.primary,
            size: 44,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          AppStrings.nfcReadyToScan,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          AppStrings.nfcTapInstruction,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textGray,
          ),
        ),

        // Warning if NFC hardware is missing
        if (paymentState.errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.accentOrangeLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.2), width: 0.5),
            ),
            child: Text(
              paymentState.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.accentOrange,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
