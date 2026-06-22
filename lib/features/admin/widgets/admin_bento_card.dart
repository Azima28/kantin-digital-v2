import 'package:flutter/material.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

/// A reusable bento card container used throughout the admin dashboard.
class AdminBentoCard extends StatelessWidget {
  final Widget child;

  const AdminBentoCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: child,
    );
  }
}
