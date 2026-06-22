import 'package:flutter/material.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

class AdminSectionLabel extends StatelessWidget {
  final String label;

  const AdminSectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.mutedGray,
        letterSpacing: 1.2,
      ),
    );
  }
}
