import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/kantin/models/order_item.dart';
import 'package:kantin_digital/features/kantin/providers/order_chat_provider.dart';
import 'package:kantin_digital/features/kantin/providers/pos_providers.dart';
import 'package:kantin_digital/features/kantin/widgets/pos_order_chat_sheet.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

class OrderDetailSheet extends ConsumerWidget {
  final OrderItem order;
  final void Function(String id, String newStatus, String studentId) onStatusChanged;

  const OrderDetailSheet({
    super.key,
    required this.order,
    required this.onStatusChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required OrderItem order,
    required void Function(String id, String newStatus, String studentId) onStatusChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderDetailSheet(
        order: order,
        onStatusChanged: onStatusChanged,
      ),
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

    // Status config mapping
    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;
    if (order.status == 'Sedang Dimasak') {
      statusColor = Nebula.amber;
      statusBgColor = Nebula.amber.withValues(alpha: 0.3).withValues(alpha: 0.2);
      statusIcon = Icons.soup_kitchen;
    } else if (order.status == 'Siap Diambil' || order.status == 'Siap Diantar') {
      statusColor = Nebula.teal;
      statusBgColor = Nebula.teal.withValues(alpha: 0.1);
      statusIcon = order.status == 'Siap Diantar' ? Icons.local_shipping_outlined : Icons.shopping_bag_outlined;
    } else if (order.status == 'Selesai') {
      statusColor = context.textSecondary;
      statusBgColor = context.textSecondary.withValues(alpha: 0.12);
      statusIcon = Icons.check_circle_outline;
    } else if (order.status == 'Dibatalkan') {
      statusColor = Nebula.rose;
      statusBgColor = Nebula.rose.withValues(alpha: 0.12);
      statusIcon = Icons.cancel_outlined;
    } else if (order.status == 'Menunggu Pembatalan') {
      statusColor = Nebula.rose;
      statusBgColor = Nebula.rose.withValues(alpha: 0.12);
      statusIcon = Icons.warning_amber_rounded;
    } else if (order.status == 'Menunggu Persetujuan Murid') {
      statusColor = Nebula.amber;
      statusBgColor = Nebula.amber.withValues(alpha: 0.12);
      statusIcon = Icons.hourglass_empty;
    } else {
      statusColor = Nebula.teal;
      statusBgColor = Nebula.teal.withValues(alpha: 0.08);
      statusIcon = Icons.fiber_new_outlined;
    }

    return Container(
      height: screenHeight,
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
                        'Rincian Pesanan',
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
                  _buildStudentBanner(context, ref),
                  const SizedBox(height: 24),

                  // 2. Interactive Stepper/Progress Tracker
                  _buildStatusStepper(context),
                  const SizedBox(height: 24),

                  // 3. Receipt Details Card
                  _buildReceiptCard(context, statusBgColor, statusColor, statusIcon, productImages),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Bottom Action Row
          _buildBottomActionButtons(context, ref),
        ],
      ),
    );
  }

  // Banner showing student details
  Widget _buildStudentBanner(BuildContext context, WidgetRef ref) {
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
              order.studentName.isNotEmpty ? order.studentName[0].toUpperCase() : '?',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.studentName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

  // Interactive stepper track with specific icons per status
  Widget _buildStatusStepper(BuildContext context) {
    final List<String> statuses = ['Baru', 'Sedang Dimasak', 'Siap Diambil', 'Selesai'];
    int currentIndex = statuses.indexOf(order.status);
    final bool isDelivery = order.deliveryLocation != null && order.deliveryLocation!.isNotEmpty;

    // Handle specific cases (like Siap Diantar being group 2)
    if (order.status == 'Siap Diantar') currentIndex = 2;
    if (order.status == 'Menunggu Pembatalan') currentIndex = 1;
    if (order.status == 'Dibatalkan') currentIndex = -1;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: context.surfaceBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderLight, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(statuses.length, (index) {
          final isCompleted = currentIndex >= index;
          final isCurrent = currentIndex == index;
          final isBatal = order.status == 'Dibatalkan';

          Color circleColor;
          if (isBatal) {
            circleColor = Nebula.rose;
          } else if (order.status == 'Menunggu Pembatalan' && index == 1) {
            circleColor = Nebula.rose;
          } else if (isCompleted) {
            circleColor = Nebula.teal;
          } else {
            circleColor = context.textSecondary.withValues(alpha: 0.4);
          }

          // Specific icon per status
          IconData icon;
          if (isBatal) {
            icon = Icons.cancel_rounded;
          } else if (order.status == 'Menunggu Pembatalan' && index == 1) {
            icon = Icons.warning_amber_rounded;
          } else {
            switch (index) {
              case 0:
                icon = Icons.receipt_long_rounded;
                break;
              case 1:
                icon = Icons.soup_kitchen_rounded;
                break;
              case 2:
                icon = isDelivery ? Icons.local_shipping_rounded : Icons.shopping_bag_rounded;
                break;
              case 3:
                icon = Icons.check_circle_rounded;
                break;
              default:
                icon = Icons.circle;
            }
          }

          String stepLabel = statuses[index];
          if (index == 2 && isDelivery) {
            stepLabel = 'Siap Diantar';
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent ? Colors.white : circleColor,
                  border: isCurrent ? Border.all(color: circleColor, width: 3.5) : null,
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: circleColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 16,
                    color: isCurrent ? circleColor : Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                stepLabel,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: isCurrent || isCompleted ? FontWeight.bold : FontWeight.w500,
                  color: isCurrent || isCompleted ? context.textPrimary : context.textSecondary,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // Receipt items details card
  Widget _buildReceiptCard(
    BuildContext context,
    Color badgeBgColor,
    Color statusColor,
    IconData statusIcon,
    Map<String, String?> productImages,
  ) {
    final String orderNum = '#A-${order.id.substring(0, math.min(6, order.id.length)).toUpperCase()}';

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
                        orderNum,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Nebula.teal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${order.id}',
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
                        order.status,
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

          // If the status is Menunggu Pembatalan, display request reason banner
          if (order.status == 'Menunggu Pembatalan' && order.cancelRequestReason != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Nebula.rose.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Nebula.rose.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.report_gmailerrorred_rounded, color: Nebula.rose, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Siswa Meminta Pembatalan:',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Nebula.rose,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.cancelRequestReason!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: context.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // If the status is Menunggu Persetujuan Murid, display waiting banner
          if (order.status == 'Menunggu Persetujuan Murid' && order.cancelRequestReason != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Nebula.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Nebula.amber.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.hourglass_empty_rounded, color: Nebula.amber, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Menunggu Persetujuan Murid:',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Nebula.amber,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Alasan pembatalan Anda: ${order.cancelRequestReason!}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: context.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Metadata properties
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildReceiptMetaRow(context, 'Waktu Transaksi', order.time),
                const SizedBox(height: 8),
                _buildReceiptMetaRow(
                  context,
                  'Tipe Pengambilan',
                  order.deliveryLocation != null && order.deliveryLocation!.isNotEmpty
                      ? order.deliveryLocation!
                      : 'Ambil Mandiri (Pickup)',
                ),
                const SizedBox(height: 8),
                _buildReceiptMetaRow(context, 'Metode Pembelian', order.deliveryLocation != null ? 'Aplikasi' : 'NFC / Kasir'),
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
                  'Item Pesanan:',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...(() {
                  final sortedItems = List<OrderSubItem>.from(order.items)
                    ..sort((a, b) => (b.price * b.qty).compareTo(a.price * a.qty));
                  return sortedItems.map((item) {
                    final imgUrl = productImages[item.name.toLowerCase().trim()];
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
                                  item.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: context.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '@ ${CurrencyFormatter.format(item.price)}',
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
                                'x${item.qty}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                CurrencyFormatter.format(item.price * item.qty),
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
                  });
                })(),
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
                Expanded(
                  child: Text(
                    'TOTAL PEMBAYARAN',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  CurrencyFormatter.format(order.totalAmount),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Nebula.teal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptMetaRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimary),
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

  // Actions bar at the bottom of sheet
  Widget _buildBottomActionButtons(BuildContext context, WidgetRef ref) {
    final isBatal = order.status == 'Dibatalkan';
    final isSelesai = order.status == 'Selesai';
    final isMerchantCancelRequest = order.status == 'Menunggu Persetujuan Murid';

    final chatAsync = ref.watch(orderChatStreamProvider(order.id));
    final int unreadCount = chatAsync.maybeWhen(
      data: (messages) => messages.where((m) => m.senderRole != 'canteen_operator' && !m.isRead).length,
      orElse: () => 0,
    );

    Widget buildChatButton({bool isFullWidth = false}) {
      return OutlinedButton(
        onPressed: () {
          Navigator.pop(context);
          PosOrderChatSheet.show(context, order: order);
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Nebula.teal.withValues(alpha: 0.5), width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.chat_bubble_2_fill, size: 15, color: Nebula.teal),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Chat Siswa',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: Nebula.teal),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, height: 1.0),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (order.status == 'Menunggu Pembatalan') {
      return Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: context.cardBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: buildChatButton(isFullWidth: true),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // Reject Cancellation (Tolak)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onStatusChanged(order.id, 'Sedang Dimasak', order.studentId);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.textSecondary,
                      side: BorderSide(color: context.dividerCol),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Tolak Batal',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Approve Cancellation (Setujui)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onStatusChanged(order.id, 'Dibatalkan', order.studentId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Nebula.rose,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Setujui Batal',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (isBatal || isSelesai || isMerchantCancelRequest) {
      return Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
        color: context.surfaceBg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: buildChatButton(isFullWidth: true),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isMerchantCancelRequest ? 'Menunggu Konfirmasi Murid' : 'Tutup Rincian'),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Primary Status Action Button on TOP (Full Width)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                String nextStatus = 'Sedang Dimasak';
                if (order.status == 'Sedang Dimasak') {
                  nextStatus = (order.deliveryLocation != null && order.deliveryLocation!.isNotEmpty)
                      ? 'Siap Diantar'
                      : 'Siap Diambil';
                } else if (order.status == 'Siap Diambil' || order.status == 'Siap Diantar') {
                  nextStatus = 'Selesai';
                }
                onStatusChanged(order.id, nextStatus, order.studentId);
              },
              icon: Icon(_getNextActionIcon(), size: 17),
              label: Text(
                _getNextActionLabel(),
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Nebula.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 2. Secondary Row below: [ Batalkan ] and [ Chat Siswa + Unread Badge ]
          Row(
            children: [
              // Cancel Action button
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onStatusChanged(order.id, 'Dibatalkan', order.studentId);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Nebula.rose,
                    side: const BorderSide(color: Nebula.rose, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Batalkan',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Chat Button with Badge
              Expanded(
                child: buildChatButton(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getNextActionIcon() {
    if (order.status == 'Baru') {
      return Icons.soup_kitchen_rounded;
    } else if (order.status == 'Sedang Dimasak') {
      return (order.deliveryLocation != null && order.deliveryLocation!.isNotEmpty)
          ? Icons.local_shipping_rounded
          : Icons.shopping_bag_rounded;
    } else {
      return Icons.check_circle_rounded;
    }
  }

  String _getNextActionLabel() {
    if (order.status == 'Baru') {
      return 'Terima & Masak';
    } else if (order.status == 'Sedang Dimasak') {
      return (order.deliveryLocation != null && order.deliveryLocation!.isNotEmpty) ? 'Siap Diantar' : 'Siap Diambil';
    } else if (order.status == 'Siap Diambil' || order.status == 'Siap Diantar') {
      return 'Selesai';
    }
    return 'Proses';
  }
}
