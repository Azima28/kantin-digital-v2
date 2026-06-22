import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

/// Convenience store (Alfamart/Indomaret) payment code display.
class MidtransCstoreDetailForm extends StatelessWidget {
  const MidtransCstoreDetailForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: Column(
            children: [
              Text(
                'Kode Pembayaran Kasir',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'KD-${Random().nextInt(89999) + 10000}',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.teal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Berikan kode pembayaran di atas ke kasir Alfamart atau Indomaret terdekat untuk menyelesaikan top-up.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textGray,
          ),
        ),
      ],
    );
  }
}
