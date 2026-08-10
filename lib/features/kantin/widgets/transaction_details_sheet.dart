import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';
import 'package:kantin_digital/features/kantin/providers/pos_providers.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

void showTransactionDetailsSheet(BuildContext context, OperatorTransaction tx) {
  TransactionDetailsSheet.show(context, tx);
}

class TransactionDetailsSheet extends ConsumerWidget {
  final OperatorTransaction tx;

  const TransactionDetailsSheet({
    super.key,
    required this.tx,
  });

  static Future<void> show(BuildContext context, OperatorTransaction tx) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionDetailsSheet(tx: tx),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double screenHeight = MediaQuery.of(context).size.height;

    final productsAsync = ref.watch(posProductsProvider);
    final Map<String, String?> productImages = {};
    productsAsync.whenData((products) {
      for (final p in products) {
        productImages[p.name.toLowerCase().trim()] = p.imageUrl;
      }
    });

    final String studentName = tx.studentName ?? AppStrings.adminStudents;
    final String firstLetter = studentName.isNotEmpty ? studentName[0].toUpperCase() : '?';

    // Status config mapping
    final isCancelled = tx.status == 'cancelled';
    final statusColor = isCancelled ? Nebula.rose : Nebula.teal;
    final statusBgColor = isCancelled
        ? Nebula.rose.withValues(alpha: 0.12)
        : Nebula.teal.withValues(alpha: 0.1);
    final statusIcon = isCancelled ? Icons.cancel_outlined : Icons.check_circle_outline;
    final statusText = isCancelled ? 'Dibatalkan' : 'Berhasil';

    final String timeStr = tx.createdAt != null
        ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(tx.createdAt!.toLocal())
        : '-';

    return Container(
      height: screenHeight * 0.85,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle & Top Title
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: context.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rincian Transaksi',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(CupertinoIcons.multiply_circle_fill, size: 24),
                        color: context.textSecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.dividerCol),

          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Student Profile Banner Card
                  _buildStudentBanner(context, studentName, firstLetter),
                  const SizedBox(height: 24),

                  // 2. Receipt Details Card
                  _buildReceiptCard(context, statusBgColor, statusColor, statusIcon, statusText, timeStr, productImages, ref),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Banner showing student details
  Widget _buildStudentBanner(BuildContext context, String studentName, String firstLetter) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Nebula.teal.withValues(alpha: 0.08).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Nebula.teal.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Nebula.teal,
            child: Text(
              firstLetter,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Siswa Pembeli',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Receipt items details card
  Widget _buildReceiptCard(
    BuildContext context,
    Color badgeBgColor,
    Color statusColor,
    IconData statusIcon,
    String statusText,
    String timeStr,
    Map<String, String?> productImages,
    WidgetRef ref,
  ) {
    final String txNum = '#T-${tx.id.substring(0, math.min(6, tx.id.length)).toUpperCase()}';
    final itemsAsync = ref.watch(transactionDetailsProvider(tx.id));

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderLight, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Order Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        txNum,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Nebula.teal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${tx.id}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.dividerCol),

          // Metadata properties
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildReceiptMetaRow(context, 'Waktu Transaksi', timeStr),
                const SizedBox(height: 8),
                _buildReceiptMetaRow(context, 'Metode Pembelian', tx.purchaseMethod == 'app' ? 'Aplikasi' : 'NFC / Kasir'),
                const SizedBox(height: 8),
                _buildReceiptMetaRow(context, 'Status Transaksi', statusText, valueColor: statusColor),
              ],
            ),
          ),

          // Dashed border line separating meta from items list
          _buildDashedDivider(context),

          // Items listing
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Item Jajanan:',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                itemsAsync.when(
                  data: (items) {
                    return Column(
                      children: items.map((item) {
                        final String name = item.productName;
                        final int price = item.unitPrice;
                        final int qty = item.quantity;
                        final imgUrl = productImages[name.toLowerCase().trim()];
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              // Product photo thumbnail
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: context.surfaceBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: context.borderLight, width: 0.5),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: imgUrl != null && imgUrl.isNotEmpty
                                      ? Image.network(
                                          imgUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Icon(
                                            Icons.fastfood_outlined,
                                            color: context.textSecondary,
                                            size: 18,
                                          ),
                                        )
                                      : Icon(
                                          Icons.fastfood_outlined,
                                          color: context.textSecondary,
                                          size: 18,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Name & Price
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: context.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '@ ${CurrencyFormatter.format(price)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: context.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Quantity & Subtotal
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'x$qty',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    CurrencyFormatter.format(price * qty),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(child: CupertinoActivityIndicator()),
                  ),
                  error: (err, stack) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      children: [
                        Text(
                          '${AppStrings.labelFailed} memuat item',
                          style: const TextStyle(color: Nebula.rose, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: () => ref.invalidate(transactionDetailsProvider(tx.id)),
                          child: Text(AppStrings.buttonRetry, style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Dashed border separating items from subtotal/total
          _buildDashedDivider(context),

          // Receipt Footer Totals
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tx.status == 'cancelled' ? 'TOTAL PENGEMBALIAN' : 'TOTAL PENDAPATAN',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(tx.totalAmount),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: tx.status == 'cancelled' ? context.textSecondary : Nebula.teal,
                    decoration: tx.status == 'cancelled' ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptMetaRow(BuildContext context, String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor ?? context.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDashedDivider(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(
          30,
          (index) => Expanded(
            child: Container(
              color: index % 2 == 0 ? Colors.transparent : context.dividerCol,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
