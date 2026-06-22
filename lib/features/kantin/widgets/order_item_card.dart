import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/features/kantin/models/order_item.dart';

class OrderItemCard extends StatelessWidget {
  final OrderItem order;
  final void Function(String id, String newStatus) onStatusChanged;

  const OrderItemCard({
    super.key,
    required this.order,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Determine card indicator color and badge details
    Color indicatorColor;
    Color badgeBgColor;
    Color badgeTextColor;
    IconData badgeIcon;
    String badgeLabel = order.status;

    if (order.status == 'Sedang Dimasak') {
      indicatorColor = AppColors.accentOrange; // Amber
      badgeBgColor = AppColors.softOrange;
      badgeTextColor = AppColors.darkOrange;
      badgeIcon = Icons.soup_kitchen;
    } else if (order.status == 'Siap Diambil') {
      indicatorColor = AppColors.success; // Green
      badgeBgColor = AppColors.successLight;
      badgeTextColor = AppColors.successDark;
      badgeIcon = Icons.shopping_bag_outlined;
    } else if (order.status == 'Siap Diantar') {
      indicatorColor = AppColors.success; // Green
      badgeBgColor = AppColors.successLight;
      badgeTextColor = AppColors.successDark;
      badgeIcon = Icons.local_shipping_outlined;
      if (order.deliveryLocation != null) {
        badgeLabel = 'Siap Diantar (${order.deliveryLocation})';
      }
    } else {
      // 'Baru'
      indicatorColor = AppColors.primary; // Blue
      badgeBgColor = AppColors.primaryLight;
      badgeTextColor = AppColors.primary;
      badgeIcon = Icons.fiber_new_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: indicatorColor, width: 5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top header: Name + Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        order.studentName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, size: 12, color: badgeTextColor),
                          const SizedBox(width: 4),
                          Text(
                            badgeLabel,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: badgeTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Time Row
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.time,
                      size: 13,
                      color: AppColors.textGray,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      order.time,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // List of items
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item.qty}x ${item.name}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Rp ${NumberFormat('#,###', 'id_ID').format(item.price * item.qty)}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Dashed Divider
                _buildDashedDivider(),
                const SizedBox(height: 8),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Rp ${NumberFormat('#,###', 'id_ID').format(order.totalAmount)}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Status Dropdown selector
                Align(
                  alignment: Alignment.bottomRight,
                  child: PopupMenuButton<String>(
                    onSelected: (newStatus) {
                      onStatusChanged(order.id, newStatus);
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(value: 'Baru', child: Text('Baru')),
                      const PopupMenuItem(
                        value: 'Sedang Dimasak',
                        child: Text('Sedang Dimasak'),
                      ),
                      const PopupMenuItem(
                        value: 'Siap Diambil',
                        child: Text('Siap Diambil'),
                      ),
                      const PopupMenuItem(
                        value: 'Siap Diantar',
                        child: Text('Siap Diantar'),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.systemBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            order.status,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            CupertinoIcons.chevron_down,
                            size: 10,
                            color: AppColors.textDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashedDivider() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: AppColors.borderLight),
              ),
            );
          }),
        );
      },
    );
  }
}
