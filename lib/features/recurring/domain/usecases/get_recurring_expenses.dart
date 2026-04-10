import '../entities/recurring_expense_entity.dart';
import '../repositories/recurring_expense_repository.dart';

class GetRecurringExpenses {
  final RecurringExpenseRepository _repository;

  GetRecurringExpenses(this._repository);

  Future<List<RecurringExpenseEntity>> call() {
    return _repository.getAllRecurringExpenses();
  }

  Stream<List<RecurringExpenseEntity>> watch() {
    return _repository.watchAllRecurringExpenses();
  }

  Future<List<RecurringExpenseEntity>> active() {
    return _repository.getActiveRecurringExpenses();
  }
}
