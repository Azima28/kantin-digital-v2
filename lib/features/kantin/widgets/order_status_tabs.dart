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
        padding: const EdgeInsets.all(3),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double tabWidth = constraints.maxWidth / tabs.length;

            return Stack(
              children: [
                // Sliding indicator
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut,
                  left: (activeIndex >= 0 ? activeIndex : 0) * tabWidth + 1.5,
                  top: 1.5,
                  bottom: 1.5,
                  width: tabWidth - 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Nebula.teal, // active tab background
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Nebula.teal.withValues(alpha: 0.25),
                          blurRadius: 6,
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
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    color: isSelected ? Colors.white : context.textSecondary,
                                  ),
                                  child: Text(label),
                                ),
                                if (count > 0) ...[
                                  const SizedBox(width: 3.5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFF3B82F6),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$count',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          height: 1.0,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
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
