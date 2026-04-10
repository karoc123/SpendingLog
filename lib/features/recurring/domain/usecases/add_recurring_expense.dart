import '../entities/recurring_expense_entity.dart';
import '../repositories/recurring_expense_repository.dart';

class AddRecurringExpense {
  final RecurringExpenseRepository _repository;

  AddRecurringExpense(this._repository);

  Future<void> call(RecurringExpenseEntity expense) {
    return _repository.addRecurringExpense(expense);
  }
}
