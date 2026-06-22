import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

/// Period selector for the Analisis tab.
///
/// Provides a segmented control for 'Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Kustom'
/// and displays the custom date range when selected.
class ParentAnalisisPeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final DateTimeRange? customDateRange;
  final ValueChanged<String> onPeriodChanged;

  const ParentAnalisisPeriodSelector({
    super.key,
    required this.selectedPeriod,
    this.customDateRange,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          child: CupertinoSegmentedControl<String>(
            groupValue: selectedPeriod,
            selectedColor: AppColors.primary,
            unselectedColor: AppColors.white,
            borderColor: AppColors.borderGray,
            pressedColor: const Color(0x1A006767),
            children: const {
              'Hari Ini': Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Hari Ini', style: TextStyle(fontSize: 12)),
              ),
              'Minggu Ini': Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Minggu', style: TextStyle(fontSize: 12)),
              ),
              'Bulan Ini': Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Bulan', style: TextStyle(fontSize: 12)),
              ),
              'Kustom': Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Kustom', style: TextStyle(fontSize: 12)),
              ),
            },
            onValueChanged: onPeriodChanged,
          ),
        ),
        if (selectedPeriod == 'Kustom' && customDateRange != null)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Text(
              'Periode: ${DateFormat('dd MMM', 'id_ID').format(customDateRange!.start)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(customDateRange!.end)}',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textGray,
              ),
            ),
          ),
      ],
    );
  }
}
