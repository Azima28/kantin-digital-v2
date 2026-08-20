import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/models/models.dart';

/// A single timeline tile for an audit log entry.
class AuditLogTile extends StatelessWidget {
  final AuditLog log;
  final VoidCallback onDetailTap;

  const AuditLogTile({
    super.key,
    required this.log,
    required this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    final String actionType = log.actionType;
    final String desc = log.description;
    final String actor = log.actorName;
    final date = log.createdAt?.toLocal() ?? DateTime.now();

    // Format time relative
    final diff = DateTime.now().difference(date);
    String timeStr = 'Baru saja';
    if (diff.inDays > 0) {
      timeStr = '${diff.inDays} hari yang lalu';
    } else if (diff.inHours > 0) {
      timeStr = '${diff.inHours} jam yang lalu';
    } else if (diff.inMinutes > 0) {
      timeStr = '${diff.inMinutes} menit yang lalu';
    }

    Color actionColor = Nebula.teal;
    IconData actionIcon = CupertinoIcons.settings;
    if (actionType == 'BATAL_PESANAN' || actionType.contains('BATAL')) {
      actionColor = Nebula.rose;
      actionIcon = CupertinoIcons.xmark_circle_fill;
    } else if (actionType == 'MERCHANT_PAYOUT') {
      actionColor = Nebula.rose;
      actionIcon = CupertinoIcons.arrow_up_right_circle_fill;
    } else if (actionType == 'KOREKSI_SALDO' || actionType == 'MERCHANT_BALANCE_ADJUSTMENT') {
      actionColor = Nebula.amber;
      actionIcon = CupertinoIcons.arrow_right_arrow_left_circle_fill;
    } else if (actionType == 'TOPUP_TUNAI' || actionType == 'TOPUP' || actionType.contains('TOPUP')) {
      actionColor = Nebula.teal;
      actionIcon = CupertinoIcons.arrow_up_circle_fill;
    } else if (actionType == 'REGISTRASI_KARTU') {
      actionColor = Nebula.teal;
      actionIcon = CupertinoIcons.creditcard_fill;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: actionColor.withValues(alpha: 0.1),
            child: (actionType.contains('BLOKIR') || actionType == 'UNLINK_KARTU')
                ? Padding(
                    padding: const EdgeInsets.all(3),
                    child: Image.asset(
                      'assets/icons/ic_card_block.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(actionIcon, color: actionColor, size: 18),
                    ),
                  )
                : (actionType.contains('AKTIFKAN') || actionType == 'REGISTRASI_KARTU')
                    ? Padding(
                        padding: const EdgeInsets.all(3),
                        child: Image.asset(
                          'assets/icons/ic_card_activate.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(actionIcon, color: actionColor, size: 18),
                        ),
                      )
                    : Icon(actionIcon, color: actionColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: actionColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          actionType.replaceAll('_', ' '),
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: actionColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeStr,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pelaksana: $actor',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: context.textSecondary,
                  ),
                ),
                SizedBox(height: 8),
                InkWell(
                  onTap: onDetailTap,
                  child: Row(
                    children: [
                      Text(
                        '${AppStrings.titleDetail} Log Perubahan',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Nebula.teal,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        CupertinoIcons.arrow_right,
                        size: 14,
                        color: Nebula.teal,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
