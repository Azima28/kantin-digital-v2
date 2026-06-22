import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/features/admin/widgets/admin_bento_card.dart';

/// Role contribution card showing student/canteen/parent activity.
class AdminContributionCard extends StatelessWidget {
  const AdminContributionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminBentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Role Activity',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.darkTeal,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.darkTeal,
                  width: 10,
                ),
              ),
              child: Center(
                child: Text(
                  'Vol.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkTeal,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegendItem(AppColors.darkTeal, 'Siswa'),
          const SizedBox(height: 4),
          _buildLegendItem(AppColors.accentOrange2, 'Petugas Kantin'),
          const SizedBox(height: 4),
          _buildLegendItem(AppColors.successGreen, 'Orang Tua'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
            letterSpacing: 0.05,
          ),
        ),
      ],
    );
  }
}
