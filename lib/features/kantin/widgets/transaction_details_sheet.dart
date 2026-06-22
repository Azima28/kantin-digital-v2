import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';

void showTransactionDetailsSheet(BuildContext context, OperatorTransaction tx) {
  final String txId = tx.id;
  final int amount = tx.totalAmount;
  final String studentName = tx.studentName ?? AppStrings.adminStudents;
  final String timeStr = tx.createdAt != null
      ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
          .format(tx.createdAt!.toLocal())
      : '-';

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    backgroundColor: AppColors.white,
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          final itemsAsync = ref.watch(transactionDetailsProvider(txId));

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Rincian Transaksi',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Pelanggan',
                        style:
                            TextStyle(color: AppColors.textGray, fontSize: 13)),
                    Text(studentName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Waktu',
                        style:
                            TextStyle(color: AppColors.textGray, fontSize: 13)),
                    Text(timeStr,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13)),
                  ],
                ),
                const Divider(height: 20),
                const Text(
                  'Item Jajanan:',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                itemsAsync.when(
                  data: (items) {
                    return Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final item = items[i];
                          final String name = item.productName;
                          final int itemPrice = item.unitPrice;
                          final int qty = item.quantity;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('$qty x  $name',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textDark)),
                                Text(
                                    CurrencyFormatter.format(itemPrice * qty),
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CupertinoActivityIndicator()),
                  error: (err, stack) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${AppStrings.labelFailed} memuat item',
                        style:
                            TextStyle(color: AppColors.error, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(transactionDetailsProvider(txId)),
                        child: const Text(AppStrings.buttonRetry,
                            style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Pembayaran:',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(
                      CurrencyFormatter.format(amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );
    },
  );
}
