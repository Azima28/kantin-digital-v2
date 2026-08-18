import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

/// A tile widget showing a single transaction entry with icon, description,
/// and amount.
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

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: isIncoming
            ? Nebula.teal.withValues(alpha: 0.15)
            : Nebula.teal.withValues(alpha: 0.1),
        child: Icon(
          isTopup ? Icons.account_balance : (isRefund ? CupertinoIcons.arrow_uturn_left : Icons.restaurant),
          color: isIncoming ? primaryTeal : primaryTeal,
          size: 18,
        ),
      ),
      title: Text(
        isTopup ? 'Top-Up Berhasil' : (isRefund ? 'Dana Dikembalikan (Refund)' : canteen),
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: context.textPrimary,
        ),
      ),
      subtitle: Text(
        _getItemsSummary(transaction),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: context.textSecondary,
        ),
      ),
      trailing: Text(
        '${isIncoming ? "+" : "-"}Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isIncoming ? Nebula.teal : context.textPrimary,
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
