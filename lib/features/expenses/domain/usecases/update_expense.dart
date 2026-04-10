import '../entities/expense_entity.dart';
import '../repositories/expense_repository.dart';

class UpdateExpense {
  final ExpenseRepository _repository;

  UpdateExpense(this._repository);

  Future<void> call(ExpenseEntity expense) {
    return _repository.updateExpense(expense);
  }
}
