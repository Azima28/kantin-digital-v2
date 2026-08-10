import 'package:flutter/material.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';

class AdminSectionLabel extends StatelessWidget {
  final String label;

  const AdminSectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: context.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }
}
