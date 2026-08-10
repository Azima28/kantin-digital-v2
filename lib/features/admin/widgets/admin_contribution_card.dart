import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
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
              color: Nebula.teal,
            ),
          ),
          SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 88,
              height: 88,
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Nebula.teal,
                    borderRadius: BorderRadius.circular(44),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(34),
                    ),
                    child: Center(
                      child: Text(
                        'Vol.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Nebula.teal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          _buildLegendItem(context, Nebula.teal, 'Siswa'),
          const SizedBox(height: 4),
          _buildLegendItem(context, Nebula.amber, 'Petugas Kantin'),
          const SizedBox(height: 4),
          _buildLegendItem(context, Nebula.teal, 'Orang Tua'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 8,
          height: 8,
          child: AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: color,
              ),
            ),
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
            color: context.textSecondary,
            letterSpacing: 0.05,
          ),
        ),
      ],
    );
  }
}
