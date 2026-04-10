import 'package:intl/intl.dart';

/// Formats an amount in cents for display using the given currency symbol
/// and locale. All amounts are stored as positive integers (cents);
/// the sign is implied (expenses are always outgoing).
String formatAmount(int cents, {String symbol = '€', String locale = 'de_DE'}) {
  final value = cents / 100;
  final formatter = NumberFormat.currency(
    locale: locale,
    symbol: symbol,
    decimalDigits: 2,
  );
  return formatter.format(value);
}

/// Parses a user-entered amount string (e.g. "12,50" or "12.50") into cents.
int? parseAmountToCents(String input) {
  if (input.trim().isEmpty) return null;
  // Normalize comma to dot.
  final normalized = input.replaceAll(',', '.').trim();
  final value = double.tryParse(normalized);
  if (value == null || value < 0) return null;
  return (value * 100).round();
}
