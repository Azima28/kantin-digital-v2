/* Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V5 */
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/utils/app_date_formatter.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/kantin/models/order_item.dart';

/// Clickable product & order summary card embedded as the first item in the chat message stream
class OrderChatProductCard extends StatelessWidget {
  final OrderItem order;
  final VoidCallback onTap;

  const OrderChatProductCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final topItem = order.mostExpensiveItem;
    final String? imgUrl = topItem?.imageUrl;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine status badge color
    Color badgeColor = Nebula.teal;
    if (order.status == 'Sedang Dimasak' || order.status == 'Baru') {
      badgeColor = Nebula.amber;
    } else if (order.status == 'Dibatalkan' || order.status == 'Menunggu Pembatalan') {
      badgeColor = Nebula.rose;
    }

    // Sort items by price descending, take max 2, rest is "..."
    final sortedItems = List<OrderSubItem>.from(order.items)
      ..sort((a, b) => (b.price * b.qty).compareTo(a.price * a.qty));
    final previewItems = sortedItems.take(2).toList();
    final hasMore = sortedItems.length > 2;

    final bool isDelivery = order.deliveryLocation != null &&
        order.deliveryLocation!.isNotEmpty &&
        !order.deliveryLocation!.toLowerCase().contains('pickup') &&
        !order.deliveryLocation!.toLowerCase().contains('ambil');

    // Date & Time label (e.g. Minggu, 16 Agustus 2026 • 11:36 WIB)
    final String dateHeader = order.createdAt != null
        ? '${AppDateFormatter.formatDayFullDate(order.createdAt)} • ${AppDateFormatter.formatTimeWib(order.createdAt)}'
        : (order.time.isNotEmpty ? order.time : 'Hari ini');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Date, Day & Time Header Pill
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dateHeader,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.textSecondary,
            ),
          ),
        ),

        // 2. Clickable Order Summary Card
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                splashColor: Nebula.teal.withValues(alpha: 0.08),
                highlightColor: Nebula.teal.withValues(alpha: 0.04),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Row: Thumbnail + Vertical Items List + Status Badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Thumbnail
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: context.surfaceBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                                width: 0.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: (imgUrl != null && imgUrl.isNotEmpty)
                                  ? Image.network(
                                      imgUrl,
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _buildFallbackIcon(),
                                    )
                                  : _buildFallbackIcon(),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Vertical Items List (Kebawah, max 2, sisanya ...)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (previewItems.isEmpty)
                                  Text(
                                    'Pesanan Kantin',
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                ...previewItems.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 2.0),
                                    child: Text(
                                      '${item.qty}x ${item.name}',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: context.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                if (hasMore)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 1.0),
                                    child: Text(
                                      '...',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: Nebula.teal,
                                        letterSpacing: 1.5,
                                        height: 0.8,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              order.status,
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                      const SizedBox(height: 8),

                      // Bottom Info Bar: Total Price + Delivery/Pickup + Click CTA
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                CurrencyFormatter.format(order.totalAmount),
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: Nebula.teal,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text('•', style: TextStyle(color: context.textSecondary, fontSize: 11)),
                              const SizedBox(width: 6),
                              Text(
                                isDelivery ? 'Diantar' : 'Ambil di Stan',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: context.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                'Lihat Rincian',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Nebula.teal,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                CupertinoIcons.chevron_right,
                                size: 11,
                                color: Nebula.teal,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      color: Nebula.teal.withValues(alpha: 0.08),
      child: const Center(
        child: Icon(
          Icons.restaurant_menu_rounded,
          color: Nebula.teal,
          size: 24,
        ),
      ),
    );
  }
}
