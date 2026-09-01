/// Safe, high-performance Indonesian date & time formatter with zero external intl table dependencies.
/// Prevents web compilation crashes (such as TypeError: Cannot read properties of undefined reading 'M_ID').
class AppDateFormatter {
  AppDateFormatter._();

  static const List<String> shortMonths = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static const List<String> fullMonths = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> days = [
    '',
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  /// Formats date to 'dd MMM' (e.g. 16 Agu)
  static String formatDayMonth(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month >= 1 && local.month <= 12 ? shortMonths[local.month] : '';
    return '$day $month';
  }

  /// Formats date to 'dd MMM yyyy' (e.g. 16 Agu 2026)
  static String formatDate(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month >= 1 && local.month <= 12 ? shortMonths[local.month] : '';
    final year = local.year;
    return '$day $month $year';
  }

  /// Formats date to 'dd MMM yy' (e.g. 16 Agu 26)
  static String formatDateShortYear(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month >= 1 && local.month <= 12 ? shortMonths[local.month] : '';
    final yy = (local.year % 100).toString().padLeft(2, '0');
    return '$day $month $yy';
  }

  /// Formats date to 'dd MMMM yyyy' (e.g. 16 Agustus 2026)
  static String formatFullDate(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month >= 1 && local.month <= 12 ? fullMonths[local.month] : '';
    final year = local.year;
    return '$day $month $year';
  }

  /// Formats date to 'MMMM yyyy' (e.g. Agustus 2026)
  static String formatMonthYear(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final month = local.month >= 1 && local.month <= 12 ? fullMonths[local.month] : '';
    final year = local.year;
    return '$month $year';
  }

  /// Formats date to 'dd MMM yyyy, HH:mm' (e.g. 16 Agu 2026, 11:36)
  static String formatDateWithTime(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month >= 1 && local.month <= 12 ? shortMonths[local.month] : '';
    final year = local.year;
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$day $month $year, $h:$m';
  }

  /// Formats date to 'dd MMM yyyy, HH:mm:ss' (e.g. 16 Agu 2026, 11:36:00)
  static String formatDateWithTimeSeconds(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month >= 1 && local.month <= 12 ? shortMonths[local.month] : '';
    final year = local.year;
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    return '$day $month $year, $h:$m:$s';
  }

  /// Formats date to 'dd MMMM yyyy, HH:mm:ss' (e.g. 16 Agustus 2026, 11:36:00)
  static String formatFullDateWithTimeSeconds(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month >= 1 && local.month <= 12 ? fullMonths[local.month] : '';
    final year = local.year;
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    return '$day $month $year, $h:$m:$s';
  }

  /// Formats date to 'dd MMMM yyyy HH:mm' (e.g. 16 Agustus 2026 11:36)
  static String formatFullDateWithTime(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month >= 1 && local.month <= 12 ? fullMonths[local.month] : '';
    final year = local.year;
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$day $month $year $h:$m';
  }

  /// Formats date to 'dd MMM, HH:mm' (e.g. 16 Agu, 11:36)
  static String formatShortDateWithTime(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month >= 1 && local.month <= 12 ? shortMonths[local.month] : '';
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$day $month, $h:$m';
  }

  /// Formats date to 'HH:mm' (e.g. 11:36)
  static String formatTime(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Formats date to 'HH:mm WIB' (e.g. 11:36 WIB)
  static String formatTimeWib(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m WIB';
  }

  /// Formats date to 'dd/MM/yyyy' (e.g. 16/08/2026)
  static String formatDateSlash(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    return '$day/$month/$year';
  }

  /// Formats date to 'dd/MM/yyyy HH:mm' (e.g. 16/08/2026 11:36)
  static String formatDateTimeSlash(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $h:$m';
  }

  /// Formats date to 'dd/MM HH:mm' (e.g. 16/08 11:36)
  static String formatShortDateTimeSlash(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$day/$month $h:$m';
  }

  /// Formats date to 'yyyyMMdd_HHmm' (e.g. 20260816_1136)
  static String formatCompactFileStamp(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final year = local.year.toString();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$year$month${day}_$h$m';
  }

  /// Formats date to 'EEEE, dd MMMM yyyy' (e.g. Minggu, 16 Agustus 2026)
  static String formatDayFullDate(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final dayName = local.weekday >= 1 && local.weekday <= 7 ? days[local.weekday] : '';
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month >= 1 && local.month <= 12 ? fullMonths[local.month] : '';
    final year = local.year;
    return '$dayName, $day $month $year';
  }

  /// Formats date to 'EEEE, dd MMMM yyyy • HH:mm' (e.g. Minggu, 16 Agustus 2026 • 11:36)
  static String formatFullDayDateWithTime(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final dayName = local.weekday >= 1 && local.weekday <= 7 ? days[local.weekday] : '';
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month >= 1 && local.month <= 12 ? fullMonths[local.month] : '';
    final year = local.year;
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$dayName, $day $month $year • $h:$m';
  }
}
