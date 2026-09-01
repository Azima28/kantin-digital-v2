import 'package:flutter/services.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final RegExp _digitGroupRegExp = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');

  /// Formats a numeric value to Indonesian Rupiah representation (e.g. 15000 -> "Rp 15.000")
  static String format(num value) {
    final int val = value is double ? value.round() : value.toInt();
    final String str = val.toString();
    final String formatted = str.replaceAllMapped(_digitGroupRegExp, (Match match) => '${match[1]}.');
    return 'Rp $formatted';
  }

  /// Formats a numeric value with thousands separator dot without prefix (e.g. 15000 -> "15.000")
  static String formatWithoutPrefix(num value) {
    final int val = value is double ? value.round() : value.toInt();
    final String str = val.toString();
    return str.replaceAllMapped(_digitGroupRegExp, (Match match) => '${match[1]}.');
  }

  /// Strips non-digits and returns int value (e.g. "15.000" -> 15000)
  static int parseClean(String raw) {
    final clean = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
  }
}

/// Lightweight, drop-in replacement for NumberFormat without external intl locale tables
class AppNumberFormat {
  final String symbol;

  const AppNumberFormat({this.symbol = 'Rp '});

  static AppNumberFormat currency({String locale = 'id_ID', String symbol = 'Rp ', int decimalDigits = 0}) {
    return AppNumberFormat(symbol: symbol);
  }

  String format(num value) {
    if (symbol.isEmpty) {
      return CurrencyFormatter.formatWithoutPrefix(value);
    }
    return '$symbol${CurrencyFormatter.formatWithoutPrefix(value)}';
  }
}

/// Formatter untuk input nominal dengan pemisah ribuan titik (.) khas Indonesia
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final int maxAmount;

  const ThousandsSeparatorInputFormatter({this.maxAmount = 2000000});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final number = int.tryParse(cleanText);
    if (number == null) return oldValue;

    final formatted = CurrencyFormatter.formatWithoutPrefix(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
