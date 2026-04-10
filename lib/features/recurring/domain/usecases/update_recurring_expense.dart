import '../entities/recurring_expense_entity.dart';
import '../repositories/recurring_expense_repository.dart';

class UpdateRecurringExpense {
  final RecurringExpenseRepository _repository;

  UpdateRecurringExpense(this._repository);

  Future<void> call(RecurringExpenseEntity expense) {
    return _repository.updateRecurringExpense(expense);
  }
}
