import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kantin_digital/core/constants/app_colors.dart';
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow('Status Kartu', isCardActive),
          const Divider(
            height: 24,
            thickness: 0.5,
            color: AppColors.borderGray,
          ),
          _buildTextInfoRow('UID RFID', rfidUid, isMonospace: true),
          const Divider(
            height: 24,
            thickness: 0.5,
            color: AppColors.borderGray,
          ),
          _buildTextInfoRow(
            'Username',
            username.isNotEmpty ? username : '-',
          ),
          const Divider(
            height: 24,
            thickness: 0.5,
            color: AppColors.borderGray,
          ),
          _buildTextInfoRow(
            'Email',
            email.isNotEmpty ? email : '-',
          ),
          const Divider(
            height: 24,
            thickness: 0.5,
            color: AppColors.borderGray,
          ),
          _buildTextInfoRow(
            'Saldo',
            CurrencyFormatter.format(balance),
            highlightColor: AppColors.darkTeal,
            isBold: true,
          ),
          const Divider(
            height: 24,
            thickness: 0.5,
            color: AppColors.borderGray,
          ),
          _buildTextInfoRow(
            'Batas Harian',
            dailyLimit != null
                ? CurrencyFormatter.format(dailyLimit as num)
                : 'Tidak Terbatas',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, bool isActive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.darkGray,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? AppColors.successLight : AppColors.errorLightColor,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            isActive ? 'ACTIVE' : 'BLOCKED',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isActive
                  ? AppColors.successGreen
                  : AppColors.errorRed2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextInfoRow(
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
              color: AppColors.darkGray,
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
                    color: highlightColor ?? AppColors.nearBlack,
                  )
                : GoogleFonts.inter(
                    fontSize: isBold ? 20 : 15,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                    color: highlightColor ?? AppColors.nearBlack,
                  ),
          ),
        ),
      ],
    );
  }
}
