import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';

class KeuanganStatusFilter extends StatelessWidget {
  final String selectedStatus;
  final ValueChanged<String> onChanged;

  const KeuanganStatusFilter({
    super.key,
    required this.selectedStatus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedStatus,
          isExpanded: true,
          style: GoogleFonts.inter(
            color: AppColors.nearBlack,
            fontSize: 13,
          ),
          onChanged: (val) {
            if (val != null) {
              onChanged(val);
            }
          },
          items: const [
            DropdownMenuItem(
              value: 'Semua',
              child: Text(AppStrings.labelAll),
            ),
            DropdownMenuItem(
              value: 'Aktif',
              child: Text('Aktif'),
            ),
            DropdownMenuItem(
              value: 'Belum Aktif',
              child: Text('Belum Aktif'),
            ),
            DropdownMenuItem(
              value: 'Diblokir',
              child: Text('Diblokir'),
            ),
          ],
        ),
      ),
    );
  }
}
