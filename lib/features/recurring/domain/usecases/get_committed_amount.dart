import '../entities/recurring_expense_entity.dart';
import '../repositories/recurring_expense_repository.dart';

/// Calculates total committed (recurring) spending for the current month.
class GetCommittedAmount {
  final RecurringExpenseRepository _repository;

  GetCommittedAmount(this._repository);

  /// Returns the sum of amount_cents for all active recurring expenses
  /// that apply in [month]/[year]. Monthly expenses always apply; yearly
  /// expenses apply only if their start month matches.
  Future<int> call({DateTime? now}) async {
    final date = now ?? DateTime.now();
    final active = await _repository.getActiveRecurringExpenses();
    int total = 0;

    for (final rule in active) {
      switch (rule.interval) {
        case RecurringInterval.monthly:
          total += rule.amountCents;
          break;
        case RecurringInterval.yearly:
          if (rule.startDate.month == date.month) {
            total += rule.amountCents;
          }
          break;
      }
    }

    return total;
  }
}
