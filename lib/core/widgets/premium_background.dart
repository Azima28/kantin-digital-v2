import 'package:flutter/material.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

class PremiumBackground extends StatelessWidget {
  final Widget child;
  const PremiumBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEBF5F5), // Soft teal/mint tint
            Color(0xFFF4F6F9), // Neutral light background tint
            Color(0xFFE8ECEF), // Soft gray/teal tint at bottom right
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Subtle soft glowing circle top right (teal)
          Positioned(
            top: -150,
            right: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.045),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.045),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          // Subtle soft glowing circle bottom left (accent/orange)
          Positioned(
            bottom: -200,
            left: -200,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentOrange.withValues(alpha: 0.025),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentOrange.withValues(alpha: 0.025),
                    blurRadius: 120,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
