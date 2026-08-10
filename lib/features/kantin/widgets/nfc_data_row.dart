import 'package:flutter/material.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';

class NfcDataRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const NfcDataRow(
    this.label,
    this.value, {
    super.key,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveValueColor = valueColor ?? context.textPrimary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: context.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: effectiveValueColor,
          ),
        ),
      ],
    );
  }
}
