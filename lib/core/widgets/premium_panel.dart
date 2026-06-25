import 'package:flutter/material.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

class PremiumPanel extends StatelessWidget {
  final Widget child;
  final bool isDesktop;
  const PremiumPanel({super.key, required this.child, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(isDesktop ? 24.0 : 12.0),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.85), // Soft white blend
        borderRadius: BorderRadius.circular(isDesktop ? 20.0 : 14.0),
        border: Border.all(
          color: AppColors.borderLight.withValues(alpha: 0.8),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isDesktop ? 20.0 : 14.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.white.withValues(alpha: 0.95),
                const Color(0xFFF5F6F8).withValues(alpha: 0.9),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
