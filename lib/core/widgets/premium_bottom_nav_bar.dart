import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';

class PremiumBottomNavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badgeCount;

  const PremiumBottomNavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount = 0,
  });
}

class PremiumBottomNavBar extends StatelessWidget {
  final List<PremiumBottomNavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color? activeColor;
  final Color? inactiveColor;

  const PremiumBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color actualActiveColor = activeColor ?? (isDark ? const Color(0xFF0D9488) : Theme.of(context).colorScheme.primary);
    final Color actualInactiveColor = inactiveColor ?? (isDark ? const Color(0xFF94A3B8) : context.textSecondary);

    final double tabWidth = MediaQuery.of(context).size.width / items.length;

    return Container(
      height: 64 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : context.cardBg,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0x1FFFFFFF) : context.borderLight,
            width: 1.0,
          ),
        ),
      ),

      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Sliding indicator
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            top: 0,
            left: currentIndex * tabWidth + (tabWidth - 40) / 2,
            child: Container(
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                color: actualActiveColor,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
              ),
            ),
          ),
          // Items
          Positioned.fill(
            child: Row(
              children: List.generate(items.length, (index) {
                final item = items[index];
                final bool isActive = index == currentIndex;

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: AnimatedScale(
                        scale: isActive ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutBack,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  isActive ? item.activeIcon : item.icon,
                                  size: 22,
                                  color: isActive ? actualActiveColor : actualInactiveColor,
                                ),
                                if (item.badgeCount > 0)
                                  Positioned(
                                    right: -8,
                                    top: -8,
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 300),
                                      transitionBuilder: (child, animation) {
                                        return ScaleTransition(
                                          scale: animation,
                                          child: child,
                                        );
                                      },
                                      child: Container(
                                        key: ValueKey<int>(item.badgeCount),
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: AppColors.rose,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Text(
                                          '${item.badgeCount}',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                color: isActive ? actualActiveColor : actualInactiveColor,
                              ),
                              child: Text(item.label),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
