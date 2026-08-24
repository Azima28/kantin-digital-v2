import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final hasOptions = item.selectedOptions.isNotEmpty;
    final hasNotes = item.notes != null && item.notes!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderLight, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                        child: const Text(
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
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Selected Options Chips
                if (hasOptions) ...[
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: item.selectedOptions.map((opt) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Nebula.teal.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Nebula.teal.withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          opt,
                          style: GoogleFonts.inter(
                            color: Nebula.teal,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 4),
                ],

                // Notes
                if (hasNotes) ...[
                  Row(
                    children: [
                      const Icon(CupertinoIcons.pencil_ellipsis_rectangle, size: 12, color: Nebula.amber),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.notes!,
                          style: GoogleFonts.inter(
                            color: context.textSecondary,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],

                Text(
                  '${CurrencyFormatter.format(item.price)} x ${item.quantity}',
                  style: GoogleFonts.inter(
                    color: context.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Total & Quantity Stepper
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(item.total),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                  color: Nebula.teal,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: context.surfaceBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.dividerCol, width: 0.5),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        ref.read(cartProvider.notifier).decreaseQuantity(
                          item.productId,
                          item.name,
                          selectedOptions: item.selectedOptions,
                          notes: item.notes,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Icon(
                          CupertinoIcons.minus,
                          size: 13,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${item.quantity}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: context.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        ref.read(cartProvider.notifier).increaseQuantity(
                          item.productId,
                          item.name,
                          selectedOptions: item.selectedOptions,
                          notes: item.notes,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Icon(
                          CupertinoIcons.plus,
                          size: 13,
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