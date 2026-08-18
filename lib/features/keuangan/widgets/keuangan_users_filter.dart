import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kantin_digital/core/extensions/theme_extensions.dart';

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
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.dividerCol),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedStatus,
          isExpanded: true,
          style: GoogleFonts.inter(
            color: context.textPrimary,
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
              child: Text('Semua Status'),
            ),
            DropdownMenuItem(
              value: 'Aktif',
              child: Text('Aktif Normal (Kartu & Akun)'),
            ),
            DropdownMenuItem(
              value: 'Kartu Belum Terdaftar',
              child: Text('Kartu Belum Terdaftar'),
            ),
            DropdownMenuItem(
              value: 'Kartu Diblokir',
              child: Text('Kartu Diblokir'),
            ),
            DropdownMenuItem(
              value: 'Akun Diblokir',
              child: Text('Akun Diblokir'),
            ),
          ],
        ),
      ),
    );
  }
}
