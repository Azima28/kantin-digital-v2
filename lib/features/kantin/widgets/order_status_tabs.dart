import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

class OrderStatusTabs extends StatelessWidget {
  final String selectedTab;
  final int countSemua;
  final int countBaru;
  final int countProses;
  final ValueChanged<String> onTabChanged;

  const OrderStatusTabs({
    super.key,
    required this.selectedTab,
    required this.countSemua,
    required this.countBaru,
    required this.countProses,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildTabButton('semua', 'Semua Pesanan ($countSemua)'),
        const SizedBox(width: 8),
        _buildTabButton('baru', 'Baru ($countBaru)'),
        const SizedBox(width: 8),
        _buildTabButton('proses', 'Proses ($countProses)'),
      ],
    );
  }

  Widget _buildTabButton(String tabKey, String label) {
    final bool isSelected = selectedTab == tabKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(tabKey),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.teal : AppColors.grayLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.white : AppColors.textGray,
            ),
          ),
        ),
      ),
    );
  }
}
