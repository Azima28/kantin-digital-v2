/* Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V5 */
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/theme/hallmark_color_scheme.dart';
import 'package:kantin_digital/features/kantin/models/order_item.dart';
import 'package:kantin_digital/features/kantin/providers/order_chat_provider.dart';
import 'package:kantin_digital/features/kantin/widgets/pos_order_chat_sheet.dart';
import 'package:kantin_digital/features/siswa/widgets/order_chat_sheet.dart';

/// Reusable Chat Icon Button with real-time unread message badge count
class OrderChatIconButton extends ConsumerWidget {
  final OrderItem order;
  final String myRole; // 'student' or 'canteen_operator'
  final VoidCallback? onTap;

  const OrderChatIconButton({
    super.key,
    required this.order,
    required this.myRole,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatAsync = ref.watch(orderChatStreamProvider(order.id));

    final int unreadCount = chatAsync.maybeWhen(
      data: (messages) => messages.where((m) => m.senderRole != myRole && !m.isRead).length,
      orElse: () => 0,
    );

    return InkWell(
      onTap: onTap ??
          () {
            if (myRole == 'student') {
              OrderChatSheet.show(context, order: order);
            } else {
              PosOrderChatSheet.show(context, order: order);
            }
          },
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? colors.brandPrimary.withValues(alpha: 0.15)
                  : colors.brandPrimary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.brandPrimary.withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            child: Icon(
              CupertinoIcons.chat_bubble_2_fill,
              size: 18,
              color: colors.brandPrimary,
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444), // Crimson Red
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.surfaceContainer,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
