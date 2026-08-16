import 'package:flutter/material.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

/// Clean Modern Application Background — provides sleek, standard visual surface.
class PremiumBackground extends StatelessWidget {
  final Widget child;
  const PremiumBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgPrimary : const Color(0xFFF1F5F9),
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF1E293B),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF1F5F9),
                  Color(0xFFF1F5F9),
                ],
              ),
      ),
      child: child,
    );
  }
}

