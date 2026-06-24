import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/kantin/providers/cart_provider.dart';
import 'package:kantin_digital/features/kantin/providers/nfc_payment_provider.dart';
import 'package:kantin_digital/features/kantin/widgets/nfc_scanning_ui.dart';
import 'package:kantin_digital/features/kantin/widgets/nfc_simulation_input.dart';
import 'package:kantin_digital/features/kantin/widgets/nfc_status_uis.dart';

class NfcPaymentModal extends ConsumerStatefulWidget {
  final int totalAmount;
  const NfcPaymentModal({super.key, required this.totalAmount});

  @override
  ConsumerState<NfcPaymentModal> createState() => _NfcPaymentModalState();
}

class _NfcPaymentModalState extends ConsumerState<NfcPaymentModal> {
  final TextEditingController _simUidController = TextEditingController();
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    // Start NFC payment session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nfcPaymentProvider.notifier).startPaymentSession(widget.totalAmount);
    });
  }

  @override
  void dispose() {
    _simUidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(nfcPaymentProvider);
    final authState = ref.watch(authNotifierProvider);
    final cartState = ref.watch(cartProvider);
    final String? sessionToken = authState.sessionToken;

    // Auto-close modal on success after 2 seconds
    if (paymentState.status == NfcPaymentStatus.success) {
      Future.delayed(const Duration(seconds: 2), () {
        if (context.mounted) {
          ref.read(nfcPaymentProvider.notifier).resetState();
          Navigator.pop(context);
        }
      });
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // iOS Grab Handle
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 24),

          // Render layout based on NFC Payment Status
          if (paymentState.status == NfcPaymentStatus.scanning) ...[
            NfcScanningUi(totalAmount: widget.totalAmount),
            const SizedBox(height: 20),

            // Mode Simulasi untuk Testing
            NfcSimulationInput(controller: _simUidController, totalAmount: widget.totalAmount),
          ] else if (paymentState.status == NfcPaymentStatus.verifyingStudent) ...[
            const NfcVerifyingStudentUi(),
          ] else if (paymentState.status == NfcPaymentStatus.confirmingPayment) ...[
            NfcConfirmingPaymentUi(
              totalAmount: widget.totalAmount,
              isConfirming: _isConfirming,
              onConfirm: sessionToken == null || sessionToken.isEmpty || _isConfirming
                  ? null
                  : () {
                      setState(() => _isConfirming = true);
                      ref.read(nfcPaymentProvider.notifier).confirmPurchase(
                        sessionToken: sessionToken,
                        items: cartState.items,
                        totalAmount: widget.totalAmount,
                      );
                    },
            ),
          ] else if (paymentState.status == NfcPaymentStatus.insufficientBalance) ...[
            NfcInsufficientBalanceUi(totalAmount: widget.totalAmount),
          ] else if (paymentState.status == NfcPaymentStatus.processingPurchase) ...[
            const NfcProcessingUi(),
          ] else if (paymentState.status == NfcPaymentStatus.success) ...[
            const NfcSuccessUi(),
          ] else if (paymentState.status == NfcPaymentStatus.error) ...[
            NfcErrorUi(
              onRetry: () {
                ref.read(nfcPaymentProvider.notifier).startPaymentSession(widget.totalAmount);
              },
            ),
          ],

          const SizedBox(height: 16),

          // Cancel Action button
          if (paymentState.status != NfcPaymentStatus.success &&
              paymentState.status != NfcPaymentStatus.processingPurchase)
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  ref.read(nfcPaymentProvider.notifier).resetState();
                  Navigator.pop(context);
                },
                child: const Text(
                  AppStrings.buttonCancel,
                  style: TextStyle(
                    color: AppColors.textGray,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
