import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/parent/widgets/midtrans_cstore_detail_form.dart';
import 'package:kantin_digital/features/parent/widgets/midtrans_payment_method_item.dart';
import 'package:kantin_digital/features/parent/widgets/midtrans_qris_detail_form.dart';
import 'package:kantin_digital/features/parent/widgets/midtrans_va_detail_form.dart';

/// Shows the Midtrans Snap payment modal dialog.
///
/// Displays payment method selection, payment instructions (QRIS, VA, Alfamart),
/// and a "simulate payment" button that triggers [onPay].
Future<void> showParentMidtransPaymentModal({
  required BuildContext context,
  required WidgetRef ref,
  required double amount,
  required String senderPhone,
  required String studentId,
  required String studentName,
  required bool isLoading,
  required Future<void> Function(double amount, String method) onPay,
}) async {
  final String orderId = 'KD-${DateTime.now().millisecondsSinceEpoch % 900000 + 100000}';
  String selectedMethod = 'QRIS'; // Default choice
  bool showInstructions = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          // Method details map helper
          final Map<String, dynamic> methodDetails = {
            'QRIS': {
              'title': 'QRIS',
              'icon': CupertinoIcons.qrcode,
              'subtext': 'Gopay, ShopeePay, Dana',
            },
            'BCA VA': {
              'title': 'BCA Virtual Account',
              'icon': Icons.account_balance,
              'subtext': 'Transfer dari BCA',
            },
            'Mandiri VA': {
              'title': 'Mandiri Virtual Account',
              'icon': Icons.account_balance,
              'subtext': "Transfer dari Livin'",
            },
            'Alfamart': {
              'title': 'Alfamart / Indomaret',
              'icon': Icons.storefront,
              'subtext': 'Bayar di kasir',
            },
          };

          final double modalWidth = MediaQuery.of(context).size.width;
          final bool isModalMobile = modalWidth < 600;

          return Dialog(
            backgroundColor: AppColors.white,
            insetPadding: isModalMobile
                ? const EdgeInsets.all(12)
                : const EdgeInsets.symmetric(
                    horizontal: 40.0, vertical: 24.0),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(isModalMobile ? 16 : 24),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 800,
                maxHeight: isModalMobile
                    ? MediaQuery.of(context).size.height * 0.9
                    : MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.offWhite2,
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(isModalMobile ? 16 : 24)),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(CupertinoIcons.shield_fill,
                                color: AppColors.teal, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'MIDTRANS SNAP',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(CupertinoIcons.xmark,
                              color: AppColors.textGray, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: showInstructions
                          // Step 2: Pay details & simulation trigger
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                  child: Text(
                                    'Simulasi Pembayaran Anda',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Selected method indicator
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.offWhite,
                                    border: Border.all(
                                        color: AppColors.borderGray),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                          methodDetails[selectedMethod]
                                              ['icon'],
                                          color: AppColors.teal),
                                      const SizedBox(width: 12),
                                      Text(
                                        methodDetails[selectedMethod]
                                            ['title'],
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        CurrencyFormatter.format(amount),
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.teal,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                if (selectedMethod == 'QRIS')
                                  const MidtransQrisDetailForm()
                                else if (selectedMethod.contains('VA'))
                                  MidtransVaDetailForm(
                                      senderPhone: senderPhone)
                                else
                                  const MidtransCstoreDetailForm(),

                                const SizedBox(height: 32),

                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accentOrange,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    padding:
                                        const EdgeInsets.symmetric(
                                            vertical: 16),
                                  ),
                                  onPressed: isLoading
                                      ? null
                                      : () async {
                                          setModalState(() {});
                                          await onPay(
                                              amount,
                                              methodDetails[
                                                      selectedMethod]
                                                  ['title']);
                                        },
                                  child: isLoading
                                      ? const CupertinoActivityIndicator(
                                          color: AppColors.white)
                                      : Text(
                                          'SIMULASIKAN PEMBAYARAN SUKSES',
                                          style:
                                              GoogleFonts.inter(
                                            color: AppColors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () {
                                    setModalState(() {
                                      showInstructions = false;
                                    });
                                  },
                                  child: Text(
                                    'Ganti Metode Pembayaran',
                                    style: GoogleFonts.inter(
                                      color: AppColors.teal,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          // Step 1: Bill & Method Choice list
                          : Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                // Total bill box
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.offWhite,
                                    border: Border.all(
                                        color: AppColors.borderGray),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(
                                          vertical: 24, horizontal: 16),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Total Tagihan',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textGray,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        CurrencyFormatter.format(amount),
                                        style: GoogleFonts.inter(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.teal,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Order ID: $orderId',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.textGray,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                Text(
                                  '${AppStrings.buttonSelect} Metode Pembayaran',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                MidtransPaymentMethodItem(
                                  keyValue: 'QRIS',
                                  title: 'QRIS',
                                  subtext: 'Gopay, ShopeePay, Dana',
                                  icon: CupertinoIcons.qrcode_viewfinder,
                                  isSelected: selectedMethod == 'QRIS',
                                  onTap: () {
                                    setModalState(() {
                                      selectedMethod = 'QRIS';
                                    });
                                  },
                                ),
                                MidtransPaymentMethodItem(
                                  keyValue: 'BCA VA',
                                  title: 'BCA Virtual Account',
                                  subtext: 'Transfer dari BCA',
                                  icon: Icons.account_balance,
                                  isSelected: selectedMethod == 'BCA VA',
                                  onTap: () {
                                    setModalState(() {
                                      selectedMethod = 'BCA VA';
                                    });
                                  },
                                ),
                                MidtransPaymentMethodItem(
                                  keyValue: 'Mandiri VA',
                                  title: 'Mandiri Virtual Account',
                                  subtext: "Transfer dari Livin'",
                                  icon: Icons.account_balance,
                                  isSelected: selectedMethod == 'Mandiri VA',
                                  onTap: () {
                                    setModalState(() {
                                      selectedMethod = 'Mandiri VA';
                                    });
                                  },
                                ),
                                MidtransPaymentMethodItem(
                                  keyValue: 'Alfamart',
                                  title: 'Alfamart / Indomaret',
                                  subtext: 'Bayar di kasir',
                                  icon: Icons.storefront,
                                  isSelected: selectedMethod == 'Alfamart',
                                  onTap: () {
                                    setModalState(() {
                                      selectedMethod = 'Alfamart';
                                    });
                                  },
                                ),
                              ],
                            ),
                    ),
                  ),

                  // Footer
                  if (!showInstructions)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(
                              color: AppColors.borderGray, width: 1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.teal,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () {
                              setModalState(() {
                                showInstructions = true;
                              });
                            },
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Text(
                                  'LANJUTKAN PEMBAYARAN',
                                  style: GoogleFonts.inter(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(CupertinoIcons.arrow_right,
                                    color: AppColors.white, size: 16),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(CupertinoIcons.lock_fill,
                                  color: AppColors.textGray, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                'Pembayaran Aman via Midtrans',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textGray,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
