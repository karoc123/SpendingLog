import '../entities/recurring_expense_entity.dart';

abstract class RecurringExpenseRepository {
  Future<List<RecurringExpenseEntity>> getAllRecurringExpenses();
  Stream<List<RecurringExpenseEntity>> watchAllRecurringExpenses();
  Future<List<RecurringExpenseEntity>> getActiveRecurringExpenses();
  Future<void> addRecurringExpense(RecurringExpenseEntity expense);
  Future<void> updateRecurringExpense(RecurringExpenseEntity expense);
  Future<void> deleteRecurringExpense(String id);
}
