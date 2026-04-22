import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/json_backup.dart';
import '../../domain/repositories/backup_restore_repository.dart';

class BackupRestoreRepositoryImpl implements BackupRestoreRepository {
  final AppDatabase _db;

  BackupRestoreRepositoryImpl(this._db);

  @override
  Future<void> restore(JsonBackupData data) async {
    await _db.transaction(() async {
      await (_db.delete(_db.expenses)).go();
      await (_db.delete(_db.recurringExpenses)).go();
      await (_db.delete(_db.categories)).go();
      await (_db.delete(_db.appSettings)).go();

      for (final category in data.categories) {
        await _db
            .into(_db.categories)
            .insert(
              CategoriesCompanion(
                id: Value(category.id),
                name: Value(category.name),
                parentId: Value(category.parentId),
                iconName: Value(category.iconName),
                colorValue: Value(category.colorValue),
                isSavings: Value(category.isSavings),
                sortOrder: Value(category.sortOrder),
                createdAt: Value(category.createdAt),
              ),
            );
      }

      for (final recurring in data.recurringExpenses) {
        await _db
            .into(_db.recurringExpenses)
            .insert(
              RecurringExpensesCompanion(
                id: Value(recurring.id),
                name: Value(recurring.name),
                amountCents: Value(recurring.amountCents),
                categoryId: Value(recurring.categoryId),
                interval: Value(recurring.interval),
                startDate: Value(recurring.startDate),
                endDate: Value(recurring.endDate),
                lastGeneratedDate: Value(recurring.lastGeneratedDate),
                isActive: Value(recurring.isActive),
                createdAt: Value(recurring.createdAt),
                updatedAt: Value(recurring.updatedAt),
              ),
            );
      }

      for (final expense in data.expenses) {
        await _db
            .into(_db.expenses)
            .insert(
              ExpensesCompanion(
                id: Value(expense.id),
                amountCents: Value(expense.amountCents),
                description: Value(expense.description),
                categoryId: Value(expense.categoryId),
                date: Value(expense.date),
                notes: Value(expense.notes),
                recurringExpenseId: Value(expense.recurringExpenseId),
                createdAt: Value(expense.createdAt),
                updatedAt: Value(expense.updatedAt),
              ),
            );
      }

      for (final entry in data.settings.entries) {
        await _db
            .into(_db.appSettings)
            .insert(
              AppSettingsCompanion.insert(key: entry.key, value: entry.value),
              mode: InsertMode.insertOrReplace,
            );
      }
    });
  }
}
