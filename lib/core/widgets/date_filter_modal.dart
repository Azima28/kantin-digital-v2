import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/utils/app_date_formatter.dart';

/// Parameter filter tanggal & rentang waktu
class AppDateFilterParam {
  final DateTime? startDate;
  final DateTime? endDate;
  final String label;

  const AppDateFilterParam({
    this.startDate,
    this.endDate,
    required this.label,
  });

  bool get isAllTime => startDate == null && endDate == null;

  /// Memeriksa apakah tanggal [dt] berada dalam rentang filter
  bool matches(DateTime? dt) {
    if (dt == null) return false;
    if (startDate == null && endDate == null) return true;
    final local = dt.toLocal();
    if (startDate != null) {
      final start = DateTime(startDate!.year, startDate!.month, startDate!.day, 0, 0, 0);
      if (local.isBefore(start)) return false;
    }
    if (endDate != null) {
      final end = DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59);
      if (local.isAfter(end)) return false;
    }
    return true;
  }
}

/// Tombol Filter Tanggal Minimalis yang Langsung Membuka Kalender
class DateFilterPillButton extends StatelessWidget {
  final AppDateFilterParam? activeFilter;
  final ValueChanged<AppDateFilterParam?> onFilterChanged;
  final String defaultLabel;

  const DateFilterPillButton({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
    this.defaultLabel = 'Pilih Tanggal',
  });

  @override
  Widget build(BuildContext context) {
    final bool hasActiveFilter = activeFilter != null && !activeFilter!.isAllTime;
    final String label = activeFilter?.label ?? defaultLabel;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => openDirectCalendarPicker(
          context,
          activeFilter: activeFilter,
          onFilterSelected: onFilterChanged,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: hasActiveFilter
                ? Nebula.teal.withValues(alpha: 0.12)
                : context.surfaceBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasActiveFilter
                  ? Nebula.teal
                  : context.borderLight,
              width: hasActiveFilter ? 1.2 : 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasActiveFilter ? Icons.event_available_rounded : Icons.calendar_today_rounded,
                size: 14,
                color: hasActiveFilter ? Nebula.teal : context.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: hasActiveFilter ? FontWeight.w700 : FontWeight.w500,
                    color: hasActiveFilter ? Nebula.teal : context.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (hasActiveFilter)
                GestureDetector(
                  onTap: () => onFilterChanged(null),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Nebula.teal.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 12,
                      color: Nebula.teal,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: context.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Membuka dialog Kalender langsung (Pilih Hari / Bulan / Tahun secara instan)
Future<void> openDirectCalendarPicker(
  BuildContext context, {
  required AppDateFilterParam? activeFilter,
  required ValueChanged<AppDateFilterParam?> onFilterSelected,
}) async {
  final now = DateTime.now();

  final isDark = context.isDark;
  final bgCard = isDark ? const Color(0xFF1E293B) : Colors.white;
  final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
  final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  final picked = await showDatePicker(
    context: context,
    initialDate: activeFilter?.startDate ?? now,
    firstDate: DateTime(2000, 1, 1),
    lastDate: DateTime(2100, 12, 31),
    helpText: 'PILIH TANGGAL FILTER',
    cancelText: 'Batal',
    confirmText: 'Pilih',
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Nebula.teal,
                onPrimary: Colors.white,
                surface: bgCard,
                onSurface: textPrimary,
                surfaceTint: Colors.transparent,
              ),
          dialogTheme: DialogThemeData(
            backgroundColor: bgCard,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: bgCard,
            surfaceTintColor: Colors.transparent,
            headerBackgroundColor: bgCard,
            headerForegroundColor: textPrimary,
            headerHeadlineStyle: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
            headerHelpStyle: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textMuted,
              letterSpacing: 0.5,
            ),
            weekdayStyle: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textMuted,
            ),
            dayStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textPrimary,
            ),
            yearStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textPrimary,
            ),
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.white;
              if (states.contains(WidgetState.disabled)) {
                return isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);
              }
              return textPrimary;
            }),
            dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Nebula.teal;
              return Colors.transparent;
            }),
            todayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.white;
              return Nebula.teal;
            }),
            todayBorder: const BorderSide(color: Nebula.teal, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            cancelButtonStyle: TextButton.styleFrom(
              foregroundColor: textMuted,
              textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            confirmButtonStyle: TextButton.styleFrom(
              foregroundColor: Nebula.teal,
              textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Nebula.teal,
              textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        child: child!,
      );
    },
  );

  if (picked != null) {
    final label = AppDateFormatter.formatDate(picked);
    onFilterSelected(AppDateFilterParam(
      startDate: picked,
      endDate: picked,
      label: label,
    ));
  }
}

/// Fallback alias
Future<void> showDateFilterModal(
  BuildContext context, {
  required AppDateFilterParam? activeFilter,
  required ValueChanged<AppDateFilterParam?> onFilterSelected,
}) =>
    openDirectCalendarPicker(
      context,
      activeFilter: activeFilter,
      onFilterSelected: onFilterSelected,
    );
