import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

/// Period selector for the Analisis tab.
/// Provides a clean 3-segment slide control ('Hari Ini', 'Minggu', 'Bulan')
/// plus a separate dedicated Date Filter Popup Button.
class ParentAnalisisPeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final DateTimeRange? customDateRange;
  final ValueChanged<String> onPeriodChanged;
  final VoidCallback onOpenCustomDatePicker;
  final VoidCallback onClearCustomDate;

  const ParentAnalisisPeriodSelector({
    super.key,
    required this.selectedPeriod,
    this.customDateRange,
    required this.onPeriodChanged,
    required this.onOpenCustomDatePicker,
    required this.onClearCustomDate,
  });

  @override
  Widget build(BuildContext context) {
    final isCustomActive = selectedPeriod == 'Kustom' && customDateRange != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // 3-Segment Sliding Tab Bar (Hari Ini, Minggu, Bulan)
            Expanded(
              child: Container(
                height: 42,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.dividerCol, width: 0.8),
                ),
                child: Row(
                  children: [
                    _buildTab(context, 'Hari Ini', 'Hari Ini'),
                    _buildTab(context, 'Minggu Ini', 'Minggu'),
                    _buildTab(context, 'Bulan Ini', 'Bulan'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Separate Date Filter Button (Opens Popup Dialog)
            InkWell(
              onTap: onOpenCustomDatePicker,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isCustomActive
                      ? Nebula.teal.withValues(alpha: 0.15)
                      : context.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCustomActive ? Nebula.teal : context.dividerCol,
                    width: isCustomActive ? 1.5 : 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCustomActive ? Icons.event_available_rounded : CupertinoIcons.calendar,
                      size: 16,
                      color: isCustomActive ? Nebula.teal : context.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Pilih Tanggal',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isCustomActive ? FontWeight.w800 : FontWeight.w600,
                        color: isCustomActive ? Nebula.teal : context.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // If Custom Filter is Active, show clean pill tag with clear (X) action
        if (isCustomActive)
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Nebula.teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Nebula.teal.withValues(alpha: 0.25), width: 0.8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range_rounded, size: 14, color: Nebula.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Periode Kustom: ${DateFormat('dd MMM', 'id_ID').format(customDateRange!.start)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(customDateRange!.end)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Nebula.teal,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onClearCustomDate,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Icon(Icons.close_rounded, size: 16, color: context.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTab(BuildContext context, String key, String label) {
    final isSelected = selectedPeriod == key;
    return Expanded(
      child: InkWell(
        onTap: () => onPeriodChanged(key),
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Nebula.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Nebula.teal.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : context.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
