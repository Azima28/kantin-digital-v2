import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';

/// Info card showing student status, RFID, username, email, class/rombel, balance, and daily limit.
class AdminStudentStatusCard extends StatelessWidget {
  final bool isCardActive;
  final bool isAccountActive;
  final String rfidUid;
  final String username;
  final String email;
  final String className;
  final int balance;
  final double? dailyLimit;

  const AdminStudentStatusCard({
    super.key,
    required this.isCardActive,
    this.isAccountActive = true,
    required this.rfidUid,
    required this.username,
    required this.email,
    required this.className,
    required this.balance,
    this.dailyLimit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerCol.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          _buildInfoRow(context, 'Status Akun Login', isAccountActive),
          Divider(height: 16, thickness: 0.5, color: context.dividerCol.withValues(alpha: 0.7)),
          _buildInfoRow(context, 'Status Kartu RFID', isCardActive),
          Divider(height: 16, thickness: 0.5, color: context.dividerCol.withValues(alpha: 0.7)),
          _buildTextInfoRow(
            context,
            'Kelas / Rombel',
            className.isNotEmpty ? className : 'Belum Ditentukan',
            highlightColor: Nebula.teal,
            isBold: true,
          ),
          Divider(height: 16, thickness: 0.5, color: context.dividerCol.withValues(alpha: 0.7)),
          _buildTextInfoRow(context, 'UID RFID', rfidUid.isNotEmpty ? rfidUid : '-', isMonospace: true),
          Divider(height: 16, thickness: 0.5, color: context.dividerCol.withValues(alpha: 0.7)),
          _buildTextInfoRow(
            context,
            'Username',
            username.isNotEmpty ? username : '-',
          ),
          Divider(height: 16, thickness: 0.5, color: context.dividerCol.withValues(alpha: 0.7)),
          _buildTextInfoRow(
            context,
            'Email',
            email.isNotEmpty ? email : '-',
          ),
          Divider(height: 16, thickness: 0.5, color: context.dividerCol.withValues(alpha: 0.7)),
          _buildTextInfoRow(
            context,
            'Saldo',
            CurrencyFormatter.format(balance),
            highlightColor: Nebula.teal,
            isBold: true,
          ),
          Divider(height: 16, thickness: 0.5, color: context.dividerCol.withValues(alpha: 0.7)),
          _buildTextInfoRow(
            context,
            'Batas Harian',
            dailyLimit != null && dailyLimit! > 0
                ? CurrencyFormatter.format(dailyLimit as num)
                : 'Rp 0',
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
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: context.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
          decoration: BoxDecoration(
            color: isActive
                ? Nebula.teal.withValues(alpha: 0.15)
                : Nebula.rose.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            isActive ? 'ACTIVE' : 'BLOCKED',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isActive ? Nebula.teal : Nebula.rose,
              letterSpacing: 0.5,
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
              fontSize: 12.5,
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
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: highlightColor ?? context.textPrimary,
                  )
                : GoogleFonts.inter(
                    fontSize: isBold ? 13.5 : 12.5,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                    color: highlightColor ?? context.textPrimary,
                  ),
          ),
        ),
      ],
    );
  }
}
