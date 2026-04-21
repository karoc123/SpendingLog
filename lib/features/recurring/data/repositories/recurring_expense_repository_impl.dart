import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/recurring_expense_entity.dart';
import '../../domain/repositories/recurring_expense_repository.dart';

class RecurringExpenseRepositoryImpl implements RecurringExpenseRepository {
  final AppDatabase _db;

  RecurringExpenseRepositoryImpl(this._db);

  RecurringExpenseEntity _toEntity(RecurringExpense row) =>
      RecurringExpenseEntity(
        id: row.id,
        name: row.name,
        amountCents: row.amountCents,
        categoryId: row.categoryId,
        interval: RecurringInterval.fromString(row.interval),
        startDate: row.startDate,
        endDate: row.endDate,
        lastGeneratedDate: row.lastGeneratedDate,
        isActive: row.isActive,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  RecurringExpensesCompanion _toCompanion(RecurringExpenseEntity e) =>
      RecurringExpensesCompanion(
        id: Value(e.id),
        name: Value(e.name),
        amountCents: Value(e.amountCents),
        categoryId: Value(e.categoryId),
        interval: Value(e.interval.name),
        startDate: Value(e.startDate),
        endDate: Value(e.endDate),
        lastGeneratedDate: Value(e.lastGeneratedDate),
        isActive: Value(e.isActive),
        createdAt: Value(e.createdAt),
        updatedAt: Value(e.updatedAt),
      );

  @override
  Future<List<RecurringExpenseEntity>> getAllRecurringExpenses() async =>
      (await _db.getAllRecurringExpenses()).map(_toEntity).toList();

  @override
  Stream<List<RecurringExpenseEntity>> watchAllRecurringExpenses() => _db
      .watchAllRecurringExpenses()
      .map((rows) => rows.map(_toEntity).toList());

  @override
  Future<List<RecurringExpenseEntity>> getActiveRecurringExpenses() async =>
      (await _db.getActiveRecurringExpenses()).map(_toEntity).toList();

  @override
  Future<void> addRecurringExpense(RecurringExpenseEntity expense) async {
    await _db.insertRecurringExpense(_toCompanion(expense));
  }

  @override
  Future<void> updateRecurringExpense(RecurringExpenseEntity expense) async {
    await _db.updateRecurringExpense(_toCompanion(expense));
  }

  @override
  Future<void> deleteRecurringExpense(String id) async {
    await _db.deleteRecurringExpense(id);
  }
}
