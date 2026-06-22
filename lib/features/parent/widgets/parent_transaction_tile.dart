import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/models/models.dart';

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
    const Color primaryTeal = AppColors.teal;
    const Color orangeAccent = AppColors.darkOrange;

    final int amount = transaction.totalAmount;
    final String type = transaction.type ?? 'purchase';
    final bool isTopup = type == 'topup';
    final String canteen = transaction.canteenName ?? 'Stan Kantin';

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: isTopup
            ? AppColors.softOrange
            : AppColors.softTeal.withValues(alpha: 0.3),
        child: Icon(
          isTopup ? Icons.account_balance : Icons.restaurant,
          color: isTopup ? orangeAccent : primaryTeal,
          size: 18,
        ),
      ),
      title: Text(
        isTopup ? 'Top-Up Berhasil' : canteen,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
      subtitle: Text(
        _getItemsSummary(transaction),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: AppColors.textGray,
        ),
      ),
      trailing: Text(
        '${isTopup ? "+" : "-"}Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isTopup ? AppColors.successGreen : AppColors.errorRed2,
        ),
      ),
    );
  }

  String _getItemsSummary(OperatorTransaction tx) {
    if (tx.type == 'topup') {
      return 'Top-up saldo digital';
    }
    final items = tx.transactionItems ?? [];
    if (items.isEmpty) {
      return 'Pembelian jajanan';
    }
    return items.map((item) {
      final qty = item.quantity;
      final name = item.productName;
      return "${qty}x $name";
    }).join(', ');
  }
}
