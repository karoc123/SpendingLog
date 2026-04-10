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

      if (dates.isNotEmpty) {
        final updated = rule.copyWith(
          lastGeneratedDate: () => dates.last,
          updatedAt: currentDate,
        );
        await _recurringRepository.updateRecurringExpense(updated);
      }
    }

    return generated;
  }

  List<DateTime> _calculatePendingDates(
    RecurringExpenseEntity rule,
    DateTime now,
  ) {
    final dates = <DateTime>[];
    // Start from the day after the last generated date, or from the start date.
    DateTime cursor = rule.lastGeneratedDate != null
        ? _nextOccurrence(rule.lastGeneratedDate!, rule.interval)
        : rule.startDate;

    while (!cursor.isAfter(now)) {
      dates.add(cursor);
      cursor = _nextOccurrence(cursor, rule.interval);
    }

    return dates;
  }

  DateTime _nextOccurrence(DateTime from, RecurringInterval interval) {
    switch (interval) {
      case RecurringInterval.monthly:
        final next = DateTime(from.year, from.month + 1, from.day);
        // Clamp to end of month if the day overflows.
        if (next.month > from.month + 1 ||
            (next.month == 1 &&
                from.month == 12 &&
                next.year > from.year + 1)) {
          return DateTime(from.year, from.month + 2, 0);
        }
        return next;
      case RecurringInterval.yearly:
        return DateTime(from.year + 1, from.month, from.day);
    }
  }
}
