import '../repositories/recurring_expense_repository.dart';

class DeleteRecurringExpense {
  final RecurringExpenseRepository _repository;

  DeleteRecurringExpense(this._repository);

  Future<void> call(String id) {
    return _repository.deleteRecurringExpense(id);
  }
}
