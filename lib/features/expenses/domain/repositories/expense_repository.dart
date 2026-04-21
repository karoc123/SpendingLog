import '../entities/expense_entity.dart';
import '../entities/autocomplete_suggestion.dart';

abstract class ExpenseRepository {
  Future<List<ExpenseEntity>> getAllExpenses();
  Future<ExpenseEntity?> findLatestExpenseByDescription(String description);
  Stream<List<ExpenseEntity>> watchAllExpenses();
  Future<List<ExpenseEntity>> getExpensesInRange(DateTime start, DateTime end);
  Stream<List<ExpenseEntity>> watchExpensesInRange(
    DateTime start,
    DateTime end,
  );
  Future<List<ExpenseEntity>> getExpensesByCategory(
    int categoryId,
    DateTime start,
    DateTime end,
  );
  Future<void> addExpense(ExpenseEntity expense);
  Future<void> updateExpense(ExpenseEntity expense);
  Future<void> deleteExpense(String id);
  Future<List<AutocompleteSuggestion>> getAutocompleteSuggestions(String query);
}
