import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

class NebulaSidebarItemData {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const NebulaSidebarItemData({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

class NebulaSidebar extends StatelessWidget {
  final IconData headerIcon;
  final String? headerTitle;
  final List<NebulaSidebarItemData> items;
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final String footerLabel;
  final IconData footerIcon;
  final VoidCallback? onLogout;

  const NebulaSidebar({
    super.key,
    required this.headerIcon,
    this.headerTitle,
    required this.items,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.footerLabel,
    this.footerIcon = Icons.storefront_rounded,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    // Deep Teal Background color matching user screenshot (#054A47 / #004D4D)
    const Color sidebarBg = Color(0xFF054A47);
    const Color activeItemBg = Color(0xFF0B6E6A);
    const Color activeCyanAccent = Color(0xFF2DD4BF);
    const Color logoBadgeBg = Color(0xFF0D9488);

    return Container(
      width: 130,
      decoration: const BoxDecoration(
        color: sidebarBg,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 28),

          // Top Header Logo Badge (Square rounded badge with store icon)
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: logoBadgeBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              headerIcon,
              color: Colors.white,
              size: 28,
            ),
          ),

          if (headerTitle != null && headerTitle!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              headerTitle!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFB2DFDF),
                letterSpacing: 0.5,
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Menu Items List (Centered layout: Icon top, Label bottom)
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final bool isSelected = index == selectedIndex;

                return InkWell(
                  onTap: () => onItemTapped(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? activeItemBg : Colors.transparent,
                    ),
                    child: Stack(
                      children: [
                        // Left Cyan Active Indicator Bar
                        if (isSelected)
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 4,
                              decoration: const BoxDecoration(
                                color: activeCyanAccent,
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(4),
                                  bottomRight: Radius.circular(4),
                                ),
                              ),
                            ),
                          ),

                        // Centered Content (Icon on top, label on bottom with smooth scale animation)
                        Center(
                          child: AnimatedScale(
                            scale: isSelected ? 1.15 : 1.0,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutBack,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                                  size: 24,
                                  color: isSelected ? Colors.white : const Color(0xFFB2DFDF),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.label,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? Colors.white : const Color(0xFFB2DFDF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Pinned Item / Role Identifier
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            child: Column(
              children: [
                Icon(
                  footerIcon,
                  size: 26,
                  color: const Color(0xFFB2DFDF),
                ),
                const SizedBox(height: 4),
                Text(
                  footerLabel,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFB2DFDF),
                  ),
                ),
                if (onLogout != null) ...[
                  const SizedBox(height: 10),
                  IconButton(
                    onPressed: onLogout,
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Nebula.rose,
                      size: 20,
                    ),
                    tooltip: 'Keluar',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
