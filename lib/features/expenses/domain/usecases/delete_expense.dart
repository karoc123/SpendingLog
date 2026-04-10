import '../repositories/expense_repository.dart';

class DeleteExpense {
  final ExpenseRepository _repository;

  DeleteExpense(this._repository);

  Future<void> call(String id) {
    return _repository.deleteExpense(id);
  }
}
