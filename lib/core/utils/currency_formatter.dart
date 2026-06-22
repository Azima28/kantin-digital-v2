class CurrencyFormatter {
  CurrencyFormatter._();

  /// Formats a numeric value to Indonesian Rupiah representation (e.g. 15000 -> "Rp 15.000")
  static String format(num value) {
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final int val = value is double ? value.round() : value.toInt();
    final String str = val.toString();
    final String formatted = str.replaceAllMapped(reg, (Match match) => '${match[1]}.');
    return 'Rp $formatted';
  }
}
