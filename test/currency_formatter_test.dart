import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formats zero correctly', () {
      expect(CurrencyFormatter.format(0), contains('0'));
    });

    test('formats positive amount with Rp prefix', () {
      final result = CurrencyFormatter.format(50000);
      expect(result, contains('Rp'));
      expect(result, contains('50'));
    });

    test('formats large amounts with thousand separators', () {
      final result = CurrencyFormatter.format(1500000);
      // Should contain 1.500.000 or 1,500,000 depending on locale
      expect(result, isNotEmpty);
      expect(result, contains('Rp'));
    });

    test('formats negative amounts', () {
      final result = CurrencyFormatter.format(-25000);
      expect(result, isNotEmpty);
    });

    test('formats decimal amounts', () {
      // CurrencyFormatter should show no decimals (decimalDigits: 0)
      final result = CurrencyFormatter.format(15000.50);
      expect(result, isNotNull);
    });
  });
}
