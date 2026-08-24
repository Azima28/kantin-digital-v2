import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

/// A tile widget showing a single transaction entry with icon, description,
/// and amount with smooth responsive layout and generous corner radius.
class ParentTransactionTile extends ConsumerWidget {
  final OperatorTransaction transaction;
  final VoidCallback? onTap;

  const ParentTransactionTile({
    required this.transaction,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const Color primaryTeal = Nebula.teal;

    final int amount = transaction.totalAmount;
    final String type = transaction.type ?? 'purchase';
    final bool isTopup = type == 'topup';
    final bool isRefund = transaction.status?.toString().toLowerCase() == 'refunded' || type == 'refund';
    final bool isIncoming = isTopup || isRefund;
    final String canteen = transaction.canteenName ?? 'Stan Kantin';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Transaction Icon Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isIncoming
                    ? Nebula.teal.withValues(alpha: 0.12)
                    : Nebula.teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isTopup
                    ? Icons.account_balance_wallet_rounded
                    : (isRefund ? CupertinoIcons.arrow_uturn_left : Icons.restaurant_rounded),
                color: primaryTeal,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),

            // Title & Items Summary
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTopup ? 'Top-Up Saldo' : (isRefund ? 'Pengembalian Dana (Refund)' : canteen),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _getItemsSummary(transaction),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Trailing Amount
            Text(
              '${isIncoming ? "+" : "-"}Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: isIncoming ? Nebula.teal : context.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getItemsSummary(OperatorTransaction tx) {
    if (tx.type == 'topup') {
      return 'Top-up saldo digital';
    }
    final methodLabel = tx.purchaseMethodDisplay;
    final items = tx.transactionItems ?? [];
    if (items.isEmpty) {
      return '$methodLabel • Jajanan kantin';
    }
    final itemsText = items.map((item) {
      final qty = item.quantity;
      final name = item.productName;
      return "${qty}x $name";
    }).join(', ');
    return '$methodLabel • $itemsText';
  }
}
