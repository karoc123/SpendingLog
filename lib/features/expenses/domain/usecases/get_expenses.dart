import '../entities/expense_entity.dart';
import '../repositories/expense_repository.dart';

class GetExpenses {
  final ExpenseRepository _repository;

  GetExpenses(this._repository);

  Future<List<ExpenseEntity>> call() {
    return _repository.getAllExpenses();
  }

  Stream<List<ExpenseEntity>> watch() {
    return _repository.watchAllExpenses();
  }

  Future<List<ExpenseEntity>> inRange(DateTime start, DateTime end) {
    return _repository.getExpensesInRange(start, end);
  }

  Stream<List<ExpenseEntity>> watchInRange(DateTime start, DateTime end) {
    return _repository.watchExpensesInRange(start, end);
  }

  Future<List<ExpenseEntity>> byCategory(
    int categoryId,
    DateTime start,
    DateTime end,
  ) {
    return _repository.getExpensesByCategory(categoryId, start, end);
  }
}
