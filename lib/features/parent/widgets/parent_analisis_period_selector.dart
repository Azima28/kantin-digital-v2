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
        // 1. Full-Width 3-Segment Sliding Tab Bar (Hari Ini, Minggu, Bulan)
        Container(
          height: 44,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(14),
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
        const SizedBox(height: 10),

        // 2. Full-Width Date Filter Bar
        InkWell(
          onTap: onOpenCustomDatePicker,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isCustomActive
                  ? Nebula.teal.withValues(alpha: 0.12)
                  : context.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCustomActive ? Nebula.teal : context.dividerCol,
                width: isCustomActive ? 1.5 : 0.8,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isCustomActive ? Icons.event_available_rounded : CupertinoIcons.calendar,
                      size: 16,
                      color: isCustomActive ? Nebula.teal : context.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCustomActive
                          ? 'Rentang: ${DateFormat('dd MMM', 'id_ID').format(customDateRange!.start)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(customDateRange!.end)}'
                          : 'Pilih Rentang Tanggal...',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: isCustomActive ? FontWeight.w800 : FontWeight.w600,
                        color: isCustomActive ? Nebula.teal : context.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (isCustomActive)
                  InkWell(
                    onTap: onClearCustomDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(Icons.close_rounded, size: 16, color: context.textSecondary),
                    ),
                  )
                else
                  Icon(CupertinoIcons.chevron_right, size: 14, color: context.textSecondary.withValues(alpha: 0.6)),
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
