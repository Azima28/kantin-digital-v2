import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/features/admin/widgets/admin_bento_card.dart';

/// System health status card showing server health, API latency, and DB stats.
class AdminSystemHealthCard extends StatelessWidget {
  final Map<String, dynamic> systemHealth;

  const AdminSystemHealthCard({
    super.key,
    this.systemHealth = const {},
  });

  @override
  Widget build(BuildContext context) {
    final String status = systemHealth['status']?.toString() ?? 'Optimal';
    final String latency = systemHealth['api_latency']?.toString() ?? '14 ms';
    final String dbCapacity = systemHealth['db_capacity']?.toString() ?? '8%';
    final String successRate = systemHealth['success_rate']?.toString() ?? '100%';

    return AdminBentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'System Health',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Nebula.teal,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Nebula.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Nebula.teal,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      status,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Nebula.teal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildHealthItem(context, Icons.speed, 'API Latency', latency, highlightColor: Nebula.teal),
          const SizedBox(height: 10),
          _buildHealthItem(context, Icons.storage, 'DB Capacity', dbCapacity),
          const SizedBox(height: 10),
          _buildHealthItem(context, Icons.check_circle_outline, 'Success Rate', successRate, highlightColor: Nebula.teal),
        ],
      ),
    );
  }

  Widget _buildHealthItem(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? highlightColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: highlightColor ?? context.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: context.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          maxLines: 1,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: highlightColor ?? context.textPrimary,
          ),
        ),
      ],
    );
  }
}
