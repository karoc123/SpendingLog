import '../entities/recurring_expense_entity.dart';
import '../repositories/recurring_expense_repository.dart';

/// Calculates total committed (recurring) spending for the current month.
class GetCommittedAmount {
  final RecurringExpenseRepository _repository;

  GetCommittedAmount(this._repository);

  /// Returns the sum of amount_cents for all active recurring expenses
  /// that apply in the current month.
  Future<int> call({DateTime? now}) async {
    final date = now ?? DateTime.now();
    final monthStart = DateTime(date.year, date.month, 1);
    final monthEnd = DateTime(date.year, date.month + 1, 0, 23, 59, 59);
    final active = await _repository.getActiveRecurringExpenses();
    int total = 0;

    for (final rule in active) {
      final occurrences = _occurrenceCountInMonth(rule, monthStart, monthEnd);
      total += occurrences * rule.amountCents;
    }

    return total;
  }

  int _occurrenceCountInMonth(
    RecurringExpenseEntity rule,
    DateTime monthStart,
    DateTime monthEnd,
  ) {
    if (rule.startDate.isAfter(monthEnd)) return 0;
    if (rule.endDate != null &&
        !_dayOnly(rule.endDate!).isAfter(_dayOnly(monthStart))) {
      return 0;
    }

    var cursor = rule.startDate;
    while (cursor.isBefore(monthStart)) {
      cursor = _nextOccurrence(cursor, rule.interval);
    }

    var count = 0;
    while (!cursor.isAfter(monthEnd)) {
      if (_isAtOrAfterEndDate(rule, cursor)) {
        break;
      }
      count++;
      cursor = _nextOccurrence(cursor, rule.interval);
    }

    return count;
  }

  bool _isAtOrAfterEndDate(RecurringExpenseEntity rule, DateTime date) {
    if (rule.endDate == null) return false;
    return !_dayOnly(date).isBefore(_dayOnly(rule.endDate!));
  }

  DateTime _dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  DateTime _addMonthsClamped(DateTime from, int monthsToAdd) {
    final monthIndex = from.month - 1 + monthsToAdd;
    final targetYear = from.year + (monthIndex ~/ 12);
    final targetMonth = (monthIndex % 12) + 1;
    final lastDayOfTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
    final targetDay = from.day <= lastDayOfTargetMonth
        ? from.day
        : lastDayOfTargetMonth;

    return DateTime(
      targetYear,
      targetMonth,
      targetDay,
      from.hour,
      from.minute,
      from.second,
      from.millisecond,
      from.microsecond,
    );
  }

  DateTime _nextOccurrence(DateTime from, RecurringInterval interval) {
    switch (interval) {
      case RecurringInterval.daily:
        return from.add(const Duration(days: 1));
      case RecurringInterval.weekly:
        return from.add(const Duration(days: 7));
      case RecurringInterval.monthly:
        return _addMonthsClamped(from, 1);
      case RecurringInterval.quarterly:
        return _addMonthsClamped(from, 3);
      case RecurringInterval.yearly:
        return _addMonthsClamped(from, 12);
    }
  }
}
