import 'package:flutter/material.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';

class PremiumPanel extends StatelessWidget {
  final Widget child;
  final bool isDesktop;
  const PremiumPanel({super.key, required this.child, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // In dark mode: no panel card, content sits directly on background
    // In light mode: keep the card look
    if (isDark) {
      return child;
    }

    return Container(
      margin: EdgeInsets.all(isDesktop ? 24.0 : 12.0),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(isDesktop ? 20.0 : 14.0),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
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
