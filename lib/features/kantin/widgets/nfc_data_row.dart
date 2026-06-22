import 'package:flutter/material.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

class NfcDataRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const NfcDataRow(
    this.label,
    this.value, {
    super.key,
    this.valueColor = AppColors.textDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textGray,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
