import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

/// Step indicator bar for multi-step flows.
///
/// Shows step label and a 3-segment progress bar.
class KeuanganStepIndicator extends StatelessWidget {
  final int currentStep;
  final String step1Label;
  final String step2Label;
  final String step3Label;

  const KeuanganStepIndicator({
    super.key,
    required this.currentStep,
    required this.step1Label,
    required this.step2Label,
    required this.step3Label,
  });

  @override
  Widget build(BuildContext context) {
    final label = currentStep == 1
        ? step1Label
        : currentStep == 2
            ? step2Label
            : step3Label;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.mutedGray,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.darkTeal,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: currentStep >= 2
                        ? AppColors.darkTeal
                        : AppColors.borderGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: currentStep >= 3
                        ? AppColors.darkTeal
                        : AppColors.borderGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
