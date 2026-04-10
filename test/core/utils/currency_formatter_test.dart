import 'package:flutter_test/flutter_test.dart';

import 'package:spending_log/core/utils/currency_formatter.dart';

void main() {
  group('formatAmount', () {
    test('should format cents as EUR with German locale by default', () {
      final result = formatAmount(1250);

      // NumberFormat for de_DE with EUR symbol
      expect(result, contains('12'));
      expect(result, contains('50'));
      expect(result, contains('€'));
    });

    test('should format zero cents', () {
      final result = formatAmount(0);

      expect(result, contains('0'));
      expect(result, contains('€'));
    });

    test('should use custom symbol', () {
      final result = formatAmount(1000, symbol: r'$', locale: 'en_US');

      expect(result, contains(r'$'));
      expect(result, contains('10'));
    });
  });

  group('parseAmountToCents', () {
    test('should parse amount with dot', () {
      expect(parseAmountToCents('12.50'), 1250);
    });

    test('should parse amount with comma (German format)', () {
      expect(parseAmountToCents('12,50'), 1250);
    });

    test('should parse whole number', () {
      expect(parseAmountToCents('10'), 1000);
    });

    test('should return null for empty input', () {
      expect(parseAmountToCents(''), isNull);
    });

    test('should return null for whitespace only', () {
      expect(parseAmountToCents('   '), isNull);
    });

    test('should return null for invalid input', () {
      expect(parseAmountToCents('abc'), isNull);
    });

    test('should return null for negative amount', () {
      expect(parseAmountToCents('-5.00'), isNull);
    });

    test('should handle small amounts', () {
      expect(parseAmountToCents('0.01'), 1);
    });

    test('should handle large amounts', () {
      expect(parseAmountToCents('9999.99'), 999999);
    });

    test('should trim whitespace', () {
      expect(parseAmountToCents('  12.50  '), 1250);
    });
  });
}
