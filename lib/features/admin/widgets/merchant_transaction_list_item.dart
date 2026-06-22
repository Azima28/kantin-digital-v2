import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';

class MerchantTransactionListItem extends StatelessWidget {
  final String nisn;
  final DateTime date;
  final int amount;

  const MerchantTransactionListItem({
    super.key,
    required this.nisn,
    required this.date,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NISN: $nisn',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.nearBlack,
                ),
              ),
              Text(
                DateFormat('HH:mm', 'id_ID').format(date),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textGray,
                ),
              ),
            ],
          ),
        ),
        Text(
          CurrencyFormatter.format(amount),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.nearBlack,
          ),
        ),
      ],
    );
  }
}
