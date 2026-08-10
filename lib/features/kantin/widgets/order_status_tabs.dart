import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

class OrderStatusTabs extends StatelessWidget {
  final String selectedTab;
  final int countBaru;
  final int countProses;
  final int countSelesai;
  final int countBatal;
  final ValueChanged<String> onTabChanged;

  const OrderStatusTabs({
    super.key,
    required this.selectedTab,
    required this.countBaru,
    required this.countProses,
    required this.countSelesai,
    required this.countBatal,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> tabs = [
      {'key': 'baru', 'label': 'Baru', 'count': countBaru},
      {'key': 'proses', 'label': 'Proses', 'count': countProses},
      {'key': 'selesai', 'label': 'Selesai', 'count': countSelesai},
      {'key': 'batal', 'label': 'Batal', 'count': countBatal},
    ];

    final int activeIndex = tabs.indexWhere((t) => t['key'] == selectedTab);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900),
        decoration: BoxDecoration(
          color: context.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double tabWidth = constraints.maxWidth / tabs.length;

            return Stack(
              children: [
                // Sliding indicator
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut,
                  left: activeIndex * tabWidth,
                  top: 0,
                  bottom: 0,
                  width: tabWidth,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Nebula.teal, // active tab background
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Nebula.teal.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                // Tab buttons
                Row(
                  children: tabs.map((tab) {
                    final String tabKey = tab['key'];
                    final String label = tab['label'];
                    final int count = tab['count'];
                    final bool isSelected = tabKey == selectedTab;

                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onTabChanged(tabKey),
                        child: AnimatedScale(
                          scale: isSelected ? 1.03 : 1.0,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 250),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    color: isSelected ? Colors.white : context.textSecondary,
                                  ),
                                  child: Text(label),
                                ),
                                if (count > 0) ...[
                                  const SizedBox(width: 6),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.white.withValues(alpha: 0.25) : Colors.blueAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Text(
                                      '$count',
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
