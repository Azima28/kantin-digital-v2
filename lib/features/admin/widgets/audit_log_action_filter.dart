import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

/// Action filter dropdown for the audit log screen.
class AuditLogActionFilter extends StatelessWidget {
  final String selectedAction;
  final List<String> actions;
  final ValueChanged<String> onChanged;

  const AuditLogActionFilter({
    super.key,
    required this.selectedAction,
    required this.actions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedAction,
          isExpanded: true,
          icon: const Icon(
            CupertinoIcons.chevron_down,
            size: 16,
            color: AppColors.darkTeal,
          ),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.nearBlack,
          ),
          items: actions.map((a) {
            return DropdownMenuItem(value: a, child: Text(a));
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              onChanged(val);
            }
          },
        ),
      ),
    );
  }
}
