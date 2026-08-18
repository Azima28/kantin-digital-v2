import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/services/pdf_service.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/kantin/models/order_item.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';
import 'package:kantin_digital/features/siswa/widgets/order_chat_sheet.dart';

/// Shows the rich transaction detail bottom sheet with product images, receipt PDF, and order chat.
void showTransactionDetailSheet(
    BuildContext context, WidgetRef ref, OperatorTransaction tx) {
  final String txId = tx.id;
  final String type = tx.type ?? 'purchase';
  final int amount = tx.totalAmount;
  final String timeStr = tx.createdAt != null
      ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(tx.createdAt!.toLocal())
      : '-';
  final String canteenName = tx.canteenName ?? 'Kantin';
  final String studentName = tx.studentName ?? 'Siswa';
  final String status = tx.status?.toString() ?? 'success';
  final bool isAppOrder = tx.purchaseMethod == 'app' || tx.purchaseMethod == 'app_order';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    backgroundColor: context.cardBg,
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          final itemsAsync = ref.watch(transactionDetailsProvider(txId));

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 14,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grab Handle
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      'Rincian Transaksi',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Header Badge Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: (type == 'topup' ? Nebula.teal : (status == 'refunded' ? Nebula.rose : Nebula.teal)).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (type == 'topup' ? Nebula.teal : (status == 'refunded' ? Nebula.rose : Nebula.teal)).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: (type == 'topup' ? Nebula.teal : (status == 'refunded' ? Nebula.rose : Nebula.teal)).withValues(alpha: 0.15),
                          child: Icon(
                            type == 'topup'
                                ? CupertinoIcons.arrow_up_circle
                                : (status == 'refunded' ? CupertinoIcons.arrow_uturn_left_circle : CupertinoIcons.check_mark_circled),
                            color: type == 'topup' ? Nebula.teal : (status == 'refunded' ? Nebula.rose : Nebula.teal),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                type == 'topup'
                                    ? 'Top-Up Saldo Berhasil'
                                    : (status == 'refunded' ? 'Pembayaran Dikembalikan (Refund)' : 'Pembayaran Berhasil'),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: context.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${isAppOrder ? "Pesanan Aplikasi" : (type == "topup" ? "Setoran Tunai" : "Tap Kartu RFID")} • $timeStr',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: context.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Metadata Info Section
                  _buildDataRow(context, 'ID Transaksi', '#${txId.length > 8 ? txId.substring(0, 8).toUpperCase() : txId}'),
                  const Divider(height: 18, thickness: 0.5),
                  _buildDataRow(context, 'Nama Siswa', studentName),
                  const Divider(height: 18, thickness: 0.5),
                  _buildDataRow(context, 'Merchant / Stan', type == 'topup' ? 'Koperasi / Petugas Keuangan' : canteenName),
                  const Divider(height: 18, thickness: 0.5),
                  _buildDataRow(context, 'Metode Pembayaran', type == 'topup' ? 'Kasir Tunai' : tx.purchaseMethodDisplay),

                  if (type == 'purchase') ...[
                    const Divider(height: 20, thickness: 0.5),
                    Text(
                      'Rincian Menu & Produk:',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Builder(
                      builder: (context) {
                        final items = (itemsAsync.asData?.value != null && itemsAsync.asData!.value.isNotEmpty)
                            ? itemsAsync.asData!.value
                            : (tx.transactionItems ?? <TransactionItem>[]);

                        if (items.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Detail produk kantin tercatat dalam sistem.',
                              style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary),
                            ),
                          );
                        }

                        return Column(
                          children: items.map((item) {
                            final String name = item.productName;
                            final int itemPrice = item.unitPrice;
                            final int qty = item.quantity;
                            final String? imgUrl = item.imageUrl;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: context.surfaceBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.dividerCol, width: 0.5),
                              ),
                              child: Row(
                                children: [
                                  if (imgUrl != null && imgUrl.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: imgUrl,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => Container(
                                          width: 40,
                                          height: 40,
                                          color: Nebula.teal.withValues(alpha: 0.08),
                                          child: const Icon(Icons.restaurant, size: 20, color: Nebula.teal),
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Nebula.teal.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.fastfood_rounded, size: 20, color: Nebula.teal),
                                    ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: context.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$qty x ${CurrencyFormatter.format(itemPrice)}',
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            color: context.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(itemPrice * qty),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],

                  const Divider(height: 22, thickness: 0.5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        type == 'topup' ? 'Total Masuk Saldo:' : 'Total Tagihan:',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary),
                      ),
                      Text(
                        CurrencyFormatter.format(amount),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: type == 'topup' ? Nebula.teal : context.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Actions: Print / Download Struk PDF (Single Full-Width Button)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Nebula.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      icon: const Icon(CupertinoIcons.printer_fill, size: 16, color: Colors.white),
                      label: Text(
                        'Cetak / Unduh Struk',
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      onPressed: () async {
                        final List<TransactionItem> effectiveItems =
                            (itemsAsync.asData?.value != null && itemsAsync.asData!.value.isNotEmpty)
                                ? itemsAsync.asData!.value
                                : (tx.transactionItems ?? <TransactionItem>[]);

                        final List<Map<String, dynamic>> itemsForPdf = effectiveItems.map((item) => {
                              'product_name': item.productName,
                              'quantity': item.quantity,
                              'unit_price': item.unitPrice,
                            }).toList();

                        await PdfService.showReceiptPreview(
                          transactionId: txId,
                          type: type,
                          amount: amount,
                          studentName: studentName,
                          canteenOrLocation: type == 'topup' ? 'Koperasi / Petugas Keuangan' : canteenName,
                          dateTime: tx.createdAt ?? DateTime.now(),
                          items: itemsForPdf,
                        );
                      },
                    ),
                  ),

                  // Chat Section if online order
                  if (isAppOrder) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.textPrimary,
                          side: BorderSide(color: context.dividerCol, width: 0.8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(CupertinoIcons.chat_bubble_2_fill, color: Nebula.teal, size: 18),
                        label: Text(
                          'Diskusi & Chat Pesanan',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          final dummyOrder = OrderItem(
                            id: txId,
                            studentId: tx.studentId ?? '',
                            studentName: studentName,
                            time: timeStr,
                            status: status,
                            items: const [],
                            totalAmount: amount,
                          );
                          OrderChatSheet.show(context, order: dummyOrder);
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildDataRow(BuildContext context, String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12.5)),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.5, color: context.textPrimary),
        ),
      ),
    ],
  );
}
