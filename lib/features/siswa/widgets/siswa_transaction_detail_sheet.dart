import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/services/pdf_service.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';

/// Shows the transaction detail bottom sheet.
///
/// This can be called as a top-level function or wrapped in a widget class.
void showTransactionDetailSheet(
    BuildContext context, WidgetRef ref, OperatorTransaction tx) {
  final String txId = tx.id;
  final String type = tx.type ?? 'purchase';
  final int amount = tx.totalAmount;
  final String timeStr = tx.createdAt != null
      ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(tx.createdAt!.toLocal())
      : '-';
  final String canteenName = tx.canteenName ?? 'Kantin';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    backgroundColor: context.cardBg,
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          final itemsAsync = ref.watch(transactionDetailsProvider(txId));

          return SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // iOS Grab Handle
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
                      '${AppStrings.titleDetail} Transaksi',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Success Centered Checkmark/Plus
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Nebula.teal.withValues(alpha: 0.1),
                          ),
                          child: Icon(
                            type == 'topup'
                                ? CupertinoIcons.square_arrow_down
                                : CupertinoIcons.check_mark_circled,
                            color: Nebula.teal,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          type == 'topup' ? 'Top-Up Saldo Berhasil' : 'Pembayaran Berhasil',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Details
                  _buildDataRow(context, 'ID Transaksi', txId.substring(0, 10).toUpperCase()),
                  const Divider(height: 20),
                  _buildDataRow(context, 'Waktu', timeStr),
                  const Divider(height: 20),
                  _buildDataRow(
                    context,
                    'Metode/Lokasi',
                    type == 'topup'
                        ? 'QRIS / Koperasi'
                        : '$canteenName (${tx.purchaseMethod == 'app' ? 'Aplikasi' : 'RFID/NFC'})',
                  ),

                  if (type == 'purchase') ...[
                    const Divider(height: 20),
                    Text(
                      'Rincian Pembelian:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: context.textPrimary,
                      ),
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
                                    Text(
                                      '$qty x  $name',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: context.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(itemPrice * qty),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: context.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                      loading: () => const Center(child: CupertinoActivityIndicator()),
                      error: (err, stack) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${AppStrings.labelFailed} memuat detail barang',
                            style: TextStyle(color: context.errorColor, fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: () => ref.invalidate(transactionDetailsProvider(txId)),
                            child: const Text(
                              AppStrings.buttonRetry,
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        type == 'topup' ? 'Total Masuk Saldo:' : 'Total Potong Saldo:',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: context.textPrimary),
                      ),
                      Text(
                        CurrencyFormatter.format(amount),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: type == 'topup' ? Nebula.teal : context.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // PDF Download button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Nebula.teal),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(AppStrings.successPdfDownloaded),
                            backgroundColor: Nebula.teal,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Simpan Struk PDF',
                        style: TextStyle(
                          color: Nebula.teal,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // PDF Share button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Nebula.teal),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        try {
                          final List<Map<String, dynamic>> itemsForPdf =
                              (itemsAsync.asData?.value ?? []).map((item) => {
                                    'product_name': item.productName,
                                    'quantity': item.quantity,
                                    'unit_price': item.unitPrice,
                                  }).toList();

                          await PdfService.shareReceipt(
                            transactionId: txId,
                            type: type,
                            amount: amount,
                            studentName: tx.studentName ?? AppStrings.adminStudents,
                            canteenOrLocation:
                                type == 'topup' ? 'QRIS / Koperasi' : canteenName,
                            dateTime: tx.createdAt ?? DateTime.now(),
                            items: itemsForPdf,
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${AppStrings.labelFailed} membuat struk PDF: $e'),
                                backgroundColor: context.errorColor,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.share, color: Nebula.teal, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Bagikan Struk PDF',
                            style: TextStyle(
                              color: Nebula.teal,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// Internal helper — builds a label + value row.
Widget _buildDataRow(BuildContext context, String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(color: context.textSecondary, fontSize: 13)),
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
      ),
    ],
  );
}
