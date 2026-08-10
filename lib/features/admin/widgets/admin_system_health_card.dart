import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/features/admin/widgets/admin_bento_card.dart';

/// System health status card.
class AdminSystemHealthCard extends StatelessWidget {
  const AdminSystemHealthCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminBentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Health',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Nebula.teal,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Nebula.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 6,
                  height: 6,
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: Nebula.teal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Optimal',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Nebula.teal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildHealthItem(context, Icons.speed, 'API Latency', '-'),
          const SizedBox(height: 10),
          _buildHealthItem(context, Icons.storage, 'DB Capacity', '0%'),
          const SizedBox(height: 10),
          _buildHealthItem(context, Icons.check_circle, 'Success Rate', '100%'),
        ],
      ),
    );
  }

  Widget _buildHealthItem(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: context.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          maxLines: 1,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
        ),
      ],
    );
  }
}
