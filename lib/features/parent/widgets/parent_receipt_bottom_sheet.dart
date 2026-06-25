import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';

/// Bottom sheet widget for displaying transaction receipt details.
class ParentReceiptBottomSheet extends ConsumerWidget {
  final OperatorTransaction transaction;
  final String Function(OperatorTransaction tx) getItemsSummary;

  const ParentReceiptBottomSheet({
    super.key,
    required this.transaction,
    required this.getItemsSummary,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int amount = transaction.totalAmount;
    final String type = transaction.type ?? 'purchase';
    final bool isTopup = type == 'topup';
    final String canteen = transaction.canteenName ?? 'Stan Kantin';
    final DateTime date = transaction.createdAt?.toLocal() ?? DateTime.now();
    final items = transaction.transactionItems ?? [];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // iOS Grab Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Center(
              child: Text(
                'DETAIL STRUK',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Success stamp
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  color: AppColors.successGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${AppStrings.labelTransaction} Berhasil',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.successGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Transaction parameters
            _buildReceiptRow('ID Transaksi',
                transaction.id.substring(0, 18).toUpperCase()),
            const SizedBox(height: 12),
            _buildReceiptRow(
              'Waktu Transaksi',
              '${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date)} WIB',
            ),
            const SizedBox(height: 12),
            _buildReceiptRow(
              'Lokasi / Metode',
              isTopup
                  ? 'Top-up Transfer Bank'
                  : '$canteen (${transaction.purchaseMethod == 'app' ? 'Aplikasi' : 'RFID/NFC'})',
            ),
            const SizedBox(height: 16),

            const Divider(color: AppColors.borderGray, height: 1),
            const SizedBox(height: 16),

            if (!isTopup && items.isNotEmpty) ...[
              Text(
                'RINCIAN ITEM BELANJA:',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (context, i) => const SizedBox(height: 6),
                itemBuilder: (context, i) {
                  final item = items[i];
                  final qty = item.quantity;
                  final price = item.unitPrice;
                  final name = item.productName;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${qty}x $name',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format((qty * price).toInt()),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.borderGray, height: 1),
              const SizedBox(height: 16),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL NOMINAL',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(amount),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Struk PDF berhasil diunduh ke perangkat.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(
                CupertinoIcons.arrow_down_to_line,
                color: AppColors.white,
                size: 16,
              ),
              label: Text(
                'UNDUH STRUK PDF',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
