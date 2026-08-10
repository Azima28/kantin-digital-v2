import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';

/// Greeting header section of the admin dashboard.
class AdminDashboardHeader extends StatelessWidget {
  const AdminDashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Halo, Super Admin',
          style: GoogleFonts.inter(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: Nebula.teal,
            letterSpacing: -0.02,
          ),
        ),
        Text(
          'Pusat kendali real-time.',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: context.textSecondary,
          ),
        ),
      ],
    );
  }
}
