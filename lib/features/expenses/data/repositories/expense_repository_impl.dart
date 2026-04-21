import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/autocomplete_suggestion.dart';
import '../../domain/repositories/expense_repository.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final AppDatabase _db;

  ExpenseRepositoryImpl(this._db);

  ExpenseEntity _toEntity(Expense row) => ExpenseEntity(
    id: row.id,
    amountCents: row.amountCents,
    description: row.description,
    categoryId: row.categoryId,
    date: row.date,
    notes: row.notes,
    recurringExpenseId: row.recurringExpenseId,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  ExpensesCompanion _toCompanion(ExpenseEntity e) => ExpensesCompanion(
    id: Value(e.id),
    amountCents: Value(e.amountCents),
    description: Value(e.description),
    categoryId: Value(e.categoryId),
    date: Value(e.date),
    notes: Value(e.notes),
    recurringExpenseId: Value(e.recurringExpenseId),
    createdAt: Value(e.createdAt),
    updatedAt: Value(e.updatedAt),
  );

  @override
  Future<List<ExpenseEntity>> getAllExpenses() async =>
      (await _db.getAllExpenses()).map(_toEntity).toList();

  @override
  Future<ExpenseEntity?> findLatestExpenseByDescription(
    String description,
  ) async {
    final row = await _db.getLatestExpenseByDescription(description);
    if (row == null) return null;
    return _toEntity(row);
  }

  @override
  Stream<List<ExpenseEntity>> watchAllExpenses() =>
      _db.watchAllExpenses().map((rows) => rows.map(_toEntity).toList());

  @override
  Future<List<ExpenseEntity>> getExpensesInRange(
    DateTime start,
    DateTime end,
  ) async => (await _db.getExpensesInRange(start, end)).map(_toEntity).toList();

  @override
  Stream<List<ExpenseEntity>> watchExpensesInRange(
    DateTime start,
    DateTime end,
  ) => _db
      .watchExpensesInRange(start, end)
      .map((rows) => rows.map(_toEntity).toList());

  @override
  Future<List<ExpenseEntity>> getExpensesByCategory(
    int categoryId,
    DateTime start,
    DateTime end,
  ) async => (await _db.getExpensesByCategory(
    categoryId,
    start,
    end,
  )).map(_toEntity).toList();

  @override
  Future<void> addExpense(ExpenseEntity expense) async {
    await _db.insertExpense(_toCompanion(expense));
  }

  @override
  Future<void> updateExpense(ExpenseEntity expense) async {
    await _db.updateExpense(_toCompanion(expense));
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _db.deleteExpense(id);
  }

  @override
  Future<List<AutocompleteSuggestion>> getAutocompleteSuggestions(
    String query,
  ) async {
    final rows = await _db.getAutocompleteSuggestions(query);
    return rows
        .map(
          (r) => AutocompleteSuggestion(
            description: r.description,
            categoryId: r.categoryId,
            amountCents: r.amountCents,
            frequency: r.frequency,
          ),
        )
        .toList();
  }
}
