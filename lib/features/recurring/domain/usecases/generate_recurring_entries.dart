import 'package:uuid/uuid.dart';

import '../../../expenses/domain/entities/expense_entity.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../entities/recurring_expense_entity.dart';
import '../repositories/recurring_expense_repository.dart';

const _uuid = Uuid();

/// Generates pending expense entries for all active recurring expenses.
///
/// Should be called on app launch. For each active recurring rule, it
/// calculates all dates between its last generation date and [now], then
/// creates expense entries for each.
class GenerateRecurringEntries {
  final RecurringExpenseRepository _recurringRepository;
  final ExpenseRepository _expenseRepository;

  GenerateRecurringEntries(this._recurringRepository, this._expenseRepository);

  Future<int> call({DateTime? now}) async {
    final currentDate = now ?? DateTime.now();
    final activeRules = await _recurringRepository.getActiveRecurringExpenses();
    int generated = 0;

    for (final rule in activeRules) {
      final dates = _calculatePendingDates(rule, currentDate);
      for (final date in dates) {
        final expense = ExpenseEntity(
          id: _uuid.v4(),
          amountCents: rule.amountCents,
          description: rule.name,
          categoryId: rule.categoryId,
          date: date,
          recurringExpenseId: rule.id,
          createdAt: currentDate,
          updatedAt: currentDate,
        );
        await _expenseRepository.addExpense(expense);
        generated++;
      }

      var updatedRule = rule;
      var shouldUpdate = false;

      if (dates.isNotEmpty) {
        updatedRule = updatedRule.copyWith(
          lastGeneratedDate: () => dates.last,
          updatedAt: currentDate,
        );
        shouldUpdate = true;
      }

      if (_shouldDeactivateAtEndDate(rule, currentDate) &&
          updatedRule.isActive) {
        updatedRule = updatedRule.copyWith(
          isActive: false,
          updatedAt: currentDate,
        );
        shouldUpdate = true;
      }

      if (shouldUpdate) {
        await _recurringRepository.updateRecurringExpense(updatedRule);
      }
    }

    return generated;
  }

  List<DateTime> _calculatePendingDates(
    RecurringExpenseEntity rule,
    DateTime now,
  ) {
    final dates = <DateTime>[];
    final nowDay = _dayOnly(now);
    final endDay = rule.endDate != null ? _dayOnly(rule.endDate!) : null;

    // Start from the day after the last generated date, or from the start date.
    DateTime cursor = rule.lastGeneratedDate != null
        ? _nextOccurrence(rule.lastGeneratedDate!, rule.interval)
        : rule.startDate;

    while (!_dayOnly(cursor).isAfter(nowDay)) {
      // End date is an exclusive cutoff: from this day onward the rule is inactive.
      if (endDay != null && !_dayOnly(cursor).isBefore(endDay)) {
        break;
      }
      dates.add(cursor);
      cursor = _nextOccurrence(cursor, rule.interval);
    }

    return dates;
  }

  bool _shouldDeactivateAtEndDate(RecurringExpenseEntity rule, DateTime now) {
    if (rule.endDate == null) return false;
    return !_dayOnly(now).isBefore(_dayOnly(rule.endDate!));
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
