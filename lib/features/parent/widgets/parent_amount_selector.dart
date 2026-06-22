import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

class ParentAmountSelector extends StatelessWidget {
  final int? selectedAmount;
  final ValueChanged<int> onAmountSelected;
  final double screenWidth;

  const ParentAmountSelector({
    super.key,
    required this.selectedAmount,
    required this.onAmountSelected,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: screenWidth < 480 ? 2 : 3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: screenWidth < 480 ? 2.5 : 2.2,
      children: [
        _buildQuickAmountItem(10000, 'Rp 10.000'),
        _buildQuickAmountItem(20000, 'Rp 20.000'),
        _buildQuickAmountItem(50000, 'Rp 50.000'),
        _buildQuickAmountItem(100000, 'Rp 100.000'),
        _buildQuickAmountItem(200000, 'Rp 200.000'),
        _buildQuickAmountItem(500000, 'Rp 500.000'),
      ],
    );
  }

  Widget _buildQuickAmountItem(int amount, String label) {
    final bool isSelected = selectedAmount == amount;
    return GestureDetector(
      onTap: () => onAmountSelected(amount),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.softTeal.withValues(alpha: 0.2) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.teal : AppColors.borderGray,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.teal.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.teal : AppColors.textDark,
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: AppColors.teal,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      CupertinoIcons.checkmark,
                      color: AppColors.white,
                      size: 10,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
