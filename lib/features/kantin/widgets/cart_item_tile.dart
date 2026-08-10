import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';
import 'package:kantin_digital/features/kantin/providers/cart_provider.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

class CartItemTile extends ConsumerWidget {
  final CartItem item;

  const CartItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCustom = item.productId == null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderLight, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isCustom)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Nebula.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Nebula.amber.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          'Kustom',
                          style: TextStyle(
                            color: Nebula.amber,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${CurrencyFormatter.format(item.price)} x ${item.quantity}',
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Edit Quantity Controls
          Row(
            children: [
              Text(
                CurrencyFormatter.format(item.total),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Nebula.teal,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(
                  color: context.surfaceBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        ref.read(cartProvider.notifier).decreaseQuantity(
                          item.productId,
                          item.name,
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Icon(
                          CupertinoIcons.minus,
                          size: 14,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${item.quantity}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: context.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        ref.read(cartProvider.notifier).increaseQuantity(
                          item.productId,
                          item.name,
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Icon(
                          CupertinoIcons.plus,
                          size: 14,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}