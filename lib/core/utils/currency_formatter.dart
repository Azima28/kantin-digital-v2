import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

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

  /// Strips non-digits and returns int value (e.g. "15.000" -> 15000)
  static int parseClean(String raw) {
    final clean = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
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

    final formatter = NumberFormat('#,###', 'id_ID');
    final formatted = formatter.format(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

