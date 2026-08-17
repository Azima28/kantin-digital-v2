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

  /// Formats date to 'dd MMM yyyy' (e.g. 16 Agu 2026)
  static String formatDate(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month >= 1 && local.month <= 12 ? shortMonths[local.month] : '';
    final year = local.year;
    return '$day $month $year';
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
}
