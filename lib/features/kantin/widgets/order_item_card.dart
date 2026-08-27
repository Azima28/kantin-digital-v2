import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/core/widgets/order_chat_button.dart';
import 'package:kantin_digital/features/kantin/models/order_item.dart';
import 'package:kantin_digital/features/kantin/widgets/order_detail_sheet.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

class OrderItemCard extends StatefulWidget {
  final OrderItem order;
  final void Function(String id, String newStatus, String studentId) onStatusChanged;

  const OrderItemCard({
    super.key,
    required this.order,
    required this.onStatusChanged,
  });

  @override
  State<OrderItemCard> createState() => _OrderItemCardState();
}

class _OrderItemCardState extends State<OrderItemCard> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60),
      lowerBound: 0.97,
      upperBound: 1.0,
    )..value = 1.0;
    _scaleAnimation = _scaleController;
  }

  @override
  void didUpdateWidget(OrderItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.id != widget.order.id) {
      _isExiting = false;
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap() async {
    // Press bounce micro-interaction (scale 100% -> 97% -> 100%, 120ms total)
    await _scaleController.animateTo(0.97, curve: Curves.easeOut);
    await _scaleController.animateTo(1.0, curve: Curves.easeOut);

    if (!mounted) return;

    OrderDetailSheet.show(
      context,
      order: widget.order,
      onStatusChanged: widget.onStatusChanged,
    );
  }

  void _triggerStatusChange(String newStatus) {
    setState(() {
      _isExiting = true;
    });
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        widget.onStatusChanged(widget.order.id, newStatus, widget.order.studentId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine card indicator color and badge details
    Color indicatorColor;
    Color badgeBgColor;
    Color badgeTextColor;
    IconData badgeIcon;
    String badgeLabel = widget.order.status;

    // Map status to visual styles
    if (widget.order.status == 'Selesai') {
      indicatorColor = Nebula.teal; // Green
      badgeBgColor = Nebula.teal.withValues(alpha: 0.08);
      badgeTextColor = Nebula.teal;
      badgeIcon = Icons.check_circle_outline;
    } else if (widget.order.status == 'Dibatalkan' || widget.order.status == 'Menunggu Pembatalan') {
      indicatorColor = Nebula.rose; // Red
      badgeBgColor = Nebula.rose.withValues(alpha: 0.08);
      badgeTextColor = Nebula.rose;
      badgeIcon = widget.order.status == 'Menunggu Pembatalan'
          ? Icons.warning_amber_rounded
          : Icons.cancel_outlined;
    } else {
      // Baru, Sedang Dimasak, Siap Diambil, Siap Diantar, Menunggu Persetujuan Murid -> Orange (Warning)
      indicatorColor = Nebula.amber; // Orange
      badgeBgColor = Nebula.amber.withValues(alpha: 0.08);
      badgeTextColor = Nebula.amber;
      
      if (widget.order.status == 'Sedang Dimasak') {
        badgeIcon = Icons.soup_kitchen;
      } else if (widget.order.status == 'Siap Diambil') {
        badgeIcon = Icons.shopping_bag_outlined;
      } else if (widget.order.status == 'Siap Diantar') {
        badgeIcon = Icons.local_shipping_outlined;
        if (widget.order.deliveryLocation != null) {
          badgeLabel = 'Siap Diantar (${widget.order.deliveryLocation})';
        }
      } else if (widget.order.status == 'Menunggu Persetujuan Murid') {
        badgeIcon = Icons.hourglass_empty_rounded;
      } else {
        badgeIcon = Icons.receipt_long_rounded; // Baru
      }
    }

    return AnimatedOpacity(
      opacity: _isExiting ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeIn,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.dividerCol, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                splashColor: Nebula.teal.withValues(alpha: 0.06),
                highlightColor: Nebula.teal.withValues(alpha: 0.03),
                onTap: _handleTap,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: indicatorColor, width: 6)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0), // Padding lega
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Student Name + Chat Button (Left) and Status Badge (Right)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      widget.order.studentName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: context.textPrimary,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  OrderChatIconButton(
                                    order: widget.order,
                                    myRole: 'canteen_operator',
                                    isCompact: true,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: badgeBgColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(badgeIcon, size: 11, color: badgeTextColor),
                                  const SizedBox(width: 3.5),
                                  Text(
                                    badgeLabel,
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: badgeTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Time & Order Code Row
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.time,
                              size: 13,
                              color: context.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.order.time,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: context.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: context.surfaceBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '#${widget.order.id.substring(0, 8).toUpperCase()}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: context.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Delivery / Pickup Location Badge for Cashier
                        if (widget.order.deliveryLocation != null && widget.order.deliveryLocation!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Builder(
                            builder: (context) {
                              final loc = widget.order.deliveryLocation!;
                              final bool isDelivery = !loc.toLowerCase().contains('pickup') && !loc.toLowerCase().contains('ambil');

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDelivery
                                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                      : context.surfaceBg,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isDelivery
                                        ? const Color(0xFF10B981).withValues(alpha: 0.35)
                                        : context.dividerCol,
                                    width: 0.6,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isDelivery ? CupertinoIcons.location_solid : CupertinoIcons.bag_fill,
                                      size: 12,
                                      color: isDelivery ? const Color(0xFF10B981) : context.textSecondary,
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        loc,
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: isDelivery ? const Color(0xFF10B981) : context.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 14),

                        // Food Thumbnail + List of items (Sorted by highest price, max 2 preview)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Builder(
                              builder: (context) {
                                final topItem = widget.order.mostExpensiveItem;
                                final String? imgUrl = topItem?.imageUrl;

                                final fallbackChild = Container(
                                  color: Nebula.teal.withValues(alpha: 0.1),
                                  child: Center(
                                    child: Icon(
                                      Icons.restaurant_menu_rounded,
                                      color: Nebula.teal,
                                      size: 22,
                                    ),
                                  ),
                                );

                                return Container(
                                  width: 48,
                                  height: 48,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: context.surfaceBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: context.dividerCol, width: 0.5),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: (imgUrl != null && imgUrl.isNotEmpty)
                                        ? Image.network(
                                            imgUrl,
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => fallbackChild,
                                          )
                                        : fallbackChild,
                                  ),
                                );
                              },
                            ),
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  // Sort items by price descending (termahal di atas)
                                  final sortedItems = List<OrderSubItem>.from(widget.order.items)
                                    ..sort((a, b) => (b.price * b.qty).compareTo(a.price * a.qty));
                                  final previewItems = sortedItems.take(2).toList();
                                  final remainingCount = sortedItems.length - previewItems.length;

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ...previewItems.map(
                                        (item) => Padding(
                                          padding: const EdgeInsets.only(bottom: 6.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      '${item.qty}x ${item.name}',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 13.5,
                                                        color: context.textPrimary,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    CurrencyFormatter.format(item.price * item.qty),
                                                    style: GoogleFonts.inter(
                                                      fontSize: 13.5,
                                                      color: context.textPrimary,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (item.selectedOptions.isNotEmpty || (item.notes != null && item.notes!.trim().isNotEmpty)) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  [
                                                    if (item.selectedOptions.isNotEmpty) item.selectedOptions.join(', '),
                                                    if (item.notes != null && item.notes!.trim().isNotEmpty) 'Catatan: ${item.notes!}',
                                                  ].join(' • '),
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    color: Nebula.amber,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (remainingCount > 0)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2.0, bottom: 4.0),
                                          child: Text(
                                            '+$remainingCount menu lainnya...',
                                            style: GoogleFonts.inter(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: Nebula.teal,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Dashed Divider
                        _buildDashedDivider(),
                        const SizedBox(height: 12),

                        // Total Price Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Harga',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: context.textSecondary,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(widget.order.totalAmount),
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Nebula.teal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Action Row
                        if (widget.order.status != 'Dibatalkan' && widget.order.status != 'Selesai')
                          widget.order.status == 'Menunggu Pembatalan'
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Warning Banner
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Nebula.rose.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Nebula.rose.withValues(alpha: 0.15)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.warning_amber_rounded,
                                            color: Nebula.rose,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              AppStrings.labelSiswaMintaBatal,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Nebula.rose,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Action Buttons
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        // Reject Request
                                        OutlinedButton(
                                          onPressed: () => _triggerStatusChange('Sedang Dimasak'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: context.textSecondary,
                                            side: BorderSide(color: context.dividerCol),
                                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: Text(
                                            AppStrings.adminReject,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Approve Request
                                        ElevatedButton(
                                          onPressed: () => _triggerStatusChange('Dibatalkan'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Nebula.rose,
                                            foregroundColor: context.cardBg,
                                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: Text(
                                            AppStrings.adminApprove,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : widget.order.status == 'Menunggu Persetujuan Murid'
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Nebula.amber.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Nebula.amber.withValues(alpha: 0.15)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.hourglass_empty_rounded,
                                            color: Nebula.amber,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Menunggu persetujuan pembatalan dari murid...',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Nebula.amber,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Row(
                                      children: [
                                        // Cancel Button
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () => _triggerStatusChange('Dibatalkan'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Nebula.rose,
                                              side: const BorderSide(color: Nebula.rose, width: 1.0),
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: Text(
                                              'Batalkan',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Accept or Dropdown Selector
                                        Expanded(
                                          child: widget.order.status == 'Baru'
                                              ? ElevatedButton(
                                                  onPressed: () => _triggerStatusChange('Sedang Dimasak'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Nebula.teal,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    elevation: 0,
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(CupertinoIcons.checkmark_circle, size: 14),
                                                      const SizedBox(width: 4),
                                                      Flexible(
                                                        child: Text(
                                                          'Terima',
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: GoogleFonts.inter(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w700,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : PopupMenuButton<String>(
                                                  onSelected: (newStatus) => _triggerStatusChange(newStatus),
                                                  itemBuilder: (BuildContext context) {
                                                    final bool isDelivery = widget.order.deliveryLocation != null && widget.order.deliveryLocation!.isNotEmpty;
                                                    final List<String> statusOptions = [
                                                      'Sedang Dimasak',
                                                      if (isDelivery) 'Siap Diantar' else 'Siap Diambil',
                                                      'Selesai',
                                                    ];
                                                    return statusOptions
                                                        .where((s) => s != widget.order.status)
                                                        .map((status) => PopupMenuItem(
                                                              value: status,
                                                              child: Text(status),
                                                            ))
                                                        .toList();
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 8,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: context.surfaceBg,
                                                      borderRadius: BorderRadius.circular(10),
                                                      border: Border.all(color: context.dividerCol, width: 0.5),
                                                    ),
                                                    child: FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            widget.order.status,
                                                            style: GoogleFonts.inter(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w600,
                                                              color: context.textPrimary,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Icon(
                                                            CupertinoIcons.chevron_down,
                                                            size: 11,
                                                            color: context.textPrimary,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
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
        ),
      ),
    );
  }

  Widget _buildDashedDivider() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: context.dividerCol),
              ),
            );
          }),
        );
      },
    );
  }
}
