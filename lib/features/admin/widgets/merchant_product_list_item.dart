import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';

class MerchantProductListItem extends StatelessWidget {
  final String name;
  final int price;
  final bool isAvailable;

  const MerchantProductListItem({
    super.key,
    required this.name,
    required this.price,
    required this.isAvailable,
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
                name,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.nearBlack,
                ),
              ),
              Text(
                CurrencyFormatter.format(price),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textGray,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isAvailable 
                ? AppColors.successLight 
                : AppColors.errorLightColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            isAvailable ? 'Avail' : 'Sold Out',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: isAvailable ? AppColors.successGreen : AppColors.errorRed2,
            ),
          ),
        ),
      ],
    );
  }
}
