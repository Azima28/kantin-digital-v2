import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/services/pdf_service.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';

/// Full-screen view for displaying complete transaction receipt and details.
class ParentTransactionDetailScreen extends StatelessWidget {
  final OperatorTransaction transaction;

  const ParentTransactionDetailScreen({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final int amount = transaction.totalAmount;
    final String type = transaction.type ?? 'purchase';
    final bool isTopup = type == 'topup';
    final bool isRefund =
        transaction.status?.toString().toLowerCase() == 'refunded' ||
            type == 'refund';
    final bool isIncoming = isTopup || isRefund;
    final String canteen = transaction.canteenName ?? 'Stan Kantin';
    final DateTime date = transaction.createdAt?.toLocal() ?? DateTime.now();
    final items = transaction.transactionItems ?? [];

    final String statusLabel = isRefund
        ? 'Dana Dikembalikan (Refund)'
        : (isTopup ? 'Top-Up Saldo Berhasil' : 'Transaksi Berhasil');

    final Color primaryAccent =
        isRefund ? Nebula.amber : (isTopup ? Nebula.teal : Nebula.teal);

    return Scaffold(
      backgroundColor: context.surfaceBg,
      appBar: AppBar(
        toolbarHeight: 56,
        backgroundColor: context.cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        shape: Border(
          bottom: BorderSide(color: context.dividerCol, width: 0.5),
        ),
        leading: IconButton(
          icon: Icon(CupertinoIcons.chevron_left, color: context.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Kembali',
        ),
        title: Text(
          'Detail Struk Transaksi',
          style: GoogleFonts.inter(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.arrow_down_to_line,
                color: Nebula.teal, size: 20),
            tooltip: 'Unduh Struk PDF',
            onPressed: () => _downloadPdf(context),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Main Header Receipt Ticket Card
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.borderLight, width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Stamp Icon
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: primaryAccent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primaryAccent.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            isRefund
                                ? CupertinoIcons.arrow_uturn_left
                                : (isTopup
                                    ? Icons.account_balance_wallet_rounded
                                    : CupertinoIcons.checkmark_circle_fill),
                            color: primaryAccent,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Text(
                        statusLabel,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: primaryAccent,
                        ),
                      ),
                      const SizedBox(height: 6),

                      Text(
                        '${isIncoming ? "+" : "-"}Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: isIncoming ? primaryAccent : context.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),

                      Text(
                        '${DateFormat('EEEE, dd MMMM yyyy • HH:mm', 'id_ID').format(date)} WIB',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Transaction Meta Info Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.borderLight, width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INFORMASI TRANSAKSI',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: context.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Divider(color: context.dividerCol, height: 1),
                      const SizedBox(height: 12),

                      // ID Transaksi with copy button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ID Transaksi',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: context.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: transaction.id));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'ID Transaksi disalin ke clipboard',
                                    style: GoogleFonts.inter(fontSize: 12.5),
                                  ),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    transaction.id.length >= 18
                                        ? transaction.id
                                            .substring(0, 18)
                                            .toUpperCase()
                                        : transaction.id.toUpperCase(),
                                    style: GoogleFonts.sourceCodePro(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.copy_rounded,
                                      size: 13, color: context.textSecondary),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      _buildMetaRow(
                        context,
                        'Merchant / Stan',
                        isTopup ? 'Koperasi Sekolah' : canteen,
                      ),
                      const SizedBox(height: 10),

                      if (transaction.studentName != null &&
                          transaction.studentName!.isNotEmpty) ...[
                        _buildMetaRow(
                          context,
                          'Nama Siswa',
                          transaction.studentName!,
                        ),
                        const SizedBox(height: 10),
                      ],

                      _buildMetaRow(
                        context,
                        'Metode Pembayaran',
                        isTopup
                            ? 'Transfer Kasir Keuangan'
                            : transaction.purchaseMethodDisplay,
                      ),
                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Status Pembayaran',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: context.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: primaryAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: primaryAccent.withValues(alpha: 0.25),
                                  width: 0.8),
                            ),
                            child: Text(
                              isRefund
                                  ? 'REFUNDED'
                                  : (isTopup ? 'BERHASIL' : 'LUNAS'),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: primaryAccent,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Purchased Items Details Card (If available)
                if (!isTopup && items.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border:
                          Border.all(color: context.borderLight, width: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RINCIAN MENU YANG DIBELI',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: context.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Divider(color: context.dividerCol, height: 1),
                        const SizedBox(height: 12),

                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (context, i) =>
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Divider(
                                    color: context.dividerCol.withValues(alpha: 0.5),
                                    height: 1),
                              ),
                          itemBuilder: (context, i) {
                            final item = items[i];
                            final qty = item.quantity;
                            final price = item.unitPrice;
                            final name = item.productName;
                            final notes = item.customNotes;
                            final thumb = item.imageUrl;

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Item Thumbnail
                                if (thumb != null && thumb.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: CachedNetworkImage(
                                      imageUrl: thumb,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        width: 40,
                                        height: 40,
                                        color: context.surfaceBg,
                                      ),
                                      errorWidget: (context, url, error) =>
                                          _buildItemFallbackIcon(context),
                                    ),
                                  )
                                else
                                  _buildItemFallbackIcon(context),
                                const SizedBox(width: 12),

                                // Item Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: GoogleFonts.inter(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: context.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$qty x ${CurrencyFormatter.format(price)}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: context.textSecondary,
                                        ),
                                      ),
                                      if (notes != null && notes.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Catatan: $notes',
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            fontStyle: FontStyle.italic,
                                            color: Nebula.teal,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                Text(
                                  CurrencyFormatter.format((qty * price).toInt()),
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: context.textPrimary,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 14),

                        // Subtotal and differences
                        Builder(
                          builder: (context) {
                            final int itemsSubtotal = items.fold<int>(
                                0, (sum, it) => sum + (it.unitPrice * it.quantity));
                            final int feeDifference = amount - itemsSubtotal;

                            return Column(
                              children: [
                                Divider(color: context.dividerCol, height: 1),
                                const SizedBox(height: 12),
                                _buildMetaRow(
                                  context,
                                  'Subtotal Menu',
                                  CurrencyFormatter.format(itemsSubtotal),
                                ),
                                if (feeDifference > 0) ...[
                                  const SizedBox(height: 8),
                                  _buildMetaRow(
                                    context,
                                    transaction.isApp
                                        ? 'Biaya Antar (Ongkir)'
                                        : 'Biaya Layanan / Tambahan',
                                    '+${CurrencyFormatter.format(feeDifference)}',
                                    highlightColor: Nebula.teal,
                                  ),
                                ],
                                if (feeDifference < 0) ...[
                                  const SizedBox(height: 8),
                                  _buildMetaRow(
                                    context,
                                    'Potongan Harga / Diskon',
                                    '-${CurrencyFormatter.format(feeDifference.abs())}',
                                    highlightColor: Nebula.amber,
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Divider(color: context.dividerCol, height: 1),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'TOTAL PEMBAYARAN',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: context.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(amount),
                                      style: GoogleFonts.inter(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w900,
                                        color: Nebula.teal,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 4. Action Buttons
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Nebula.teal,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _downloadPdf(context),
                  icon: const Icon(CupertinoIcons.arrow_down_to_line,
                      color: Colors.white, size: 18),
                  label: Text(
                    'UNDUH STRUK PDF',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: context.dividerCol, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'KEMBALI KE RIWAYAT',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemFallbackIcon(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Nebula.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Icon(
          Icons.restaurant_rounded,
          color: Nebula.teal,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildMetaRow(BuildContext context, String label, String value,
      {Color? highlightColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: context.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: highlightColor ?? context.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _downloadPdf(BuildContext context) {
    final int amount = transaction.totalAmount;
    final String type = transaction.type ?? 'purchase';
    final String canteen = transaction.canteenName ?? 'Stan Kantin';
    final DateTime date = transaction.createdAt?.toLocal() ?? DateTime.now();
    final items = transaction.transactionItems ?? [];

    final List<Map<String, dynamic>> pdfItems = items
        .map((it) => {
              'name': it.productName,
              'quantity': it.quantity,
              'price': it.unitPrice,
            })
        .toList();

    PdfService.showReceiptPreview(
      transactionId: transaction.id,
      type: type,
      amount: amount,
      studentName: transaction.studentName ?? 'Siswa',
      canteenOrLocation: canteen,
      dateTime: date,
      items: pdfItems,
    );
  }
}
