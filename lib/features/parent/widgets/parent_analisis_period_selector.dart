import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

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
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.dividerCol, width: 0.5),
          ),
          child: Row(
            children: ['Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Kustom'].map((period) {
              final isSelected = selectedPeriod == period;
              final String labelText = period == 'Hari Ini'
                  ? 'Hari Ini'
                  : period == 'Minggu Ini'
                      ? 'Minggu'
                      : period == 'Bulan Ini'
                          ? 'Bulan'
                          : 'Kustom';
              return Expanded(
                child: GestureDetector(
                  onTap: () => onPeriodChanged(period),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Nebula.teal : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Nebula.teal.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        labelText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : context.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
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
                color: context.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}
