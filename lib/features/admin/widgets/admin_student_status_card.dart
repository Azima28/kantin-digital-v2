import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';

/// Info card showing student status, RFID, username, email, balance, and daily limit.
/// Used inside the admin student detail screen.
class AdminStudentStatusCard extends StatelessWidget {
  final bool isCardActive;
  final String rfidUid;
  final String username;
  final String email;
  final int balance;
  final double? dailyLimit;

  const AdminStudentStatusCard({
    super.key,
    required this.isCardActive,
    required this.rfidUid,
    required this.username,
    required this.email,
    required this.balance,
    this.dailyLimit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(context, 'Status Kartu', isCardActive),
          Divider(
            height: 24,
            thickness: 0.5,
            color: context.dividerCol,
          ),
          _buildTextInfoRow(context, 'UID RFID', rfidUid, isMonospace: true),
          Divider(
            height: 24,
            thickness: 0.5,
            color: context.dividerCol,
          ),
          _buildTextInfoRow(
            context,
            'Username',
            username.isNotEmpty ? username : '-',
          ),
          Divider(
            height: 24,
            thickness: 0.5,
            color: context.dividerCol,
          ),
          _buildTextInfoRow(
            context,
            'Email',
            email.isNotEmpty ? email : '-',
          ),
          Divider(
            height: 24,
            thickness: 0.5,
            color: context.dividerCol,
          ),
          _buildTextInfoRow(
            context,
            'Saldo',
            CurrencyFormatter.format(balance),
            highlightColor: Nebula.teal,
            isBold: true,
          ),
          Divider(
            height: 24,
            thickness: 0.5,
            color: context.dividerCol,
          ),
          _buildTextInfoRow(
            context,
            'Batas Harian',
            dailyLimit != null
                ? CurrencyFormatter.format(dailyLimit as num)
                : 'Tidak Terbatas',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, bool isActive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: context.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? Nebula.teal.withValues(alpha: 0.1) : Nebula.rose.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            isActive ? 'ACTIVE' : 'BLOCKED',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isActive
                  ? Nebula.teal
                  : Nebula.rose,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextInfoRow(
    BuildContext context,
    String label,
    String value, {
    Color? highlightColor,
    bool isBold = false,
    bool isMonospace = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: context.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: isMonospace
                ? TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: highlightColor ?? context.textPrimary,
                  )
                : GoogleFonts.inter(
                    fontSize: isBold ? 20 : 15,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                    color: highlightColor ?? context.textPrimary,
                  ),
          ),
        ),
      ],
    );
  }
}
