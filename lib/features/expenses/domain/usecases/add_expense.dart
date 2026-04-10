import '../entities/expense_entity.dart';
import '../repositories/expense_repository.dart';

class AddExpense {
  final ExpenseRepository _repository;

  AddExpense(this._repository);

  Future<void> call(ExpenseEntity expense) {
    return _repository.addExpense(expense);
  }
}
