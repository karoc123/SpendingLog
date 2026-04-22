import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';

import 'package:spending_log/core/database/app_database.dart';
import 'package:spending_log/features/settings/data/repositories/backup_restore_repository_impl.dart';
import 'package:spending_log/features/settings/domain/entities/json_backup.dart';

void main() {
  late AppDatabase db;
  late BackupRestoreRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.memory();
    repository = BackupRestoreRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('restore replaces all data from backup payload', () async {
    final oldCategoryId = await db.insertCategory(
      CategoriesCompanion.insert(name: 'Old Category'),
    );
    await db.insertExpense(
      ExpensesCompanion(
        id: const Value('old-exp'),
        amountCents: const Value(500),
        description: const Value('Old expense'),
        categoryId: Value(oldCategoryId),
        date: Value(DateTime(2026, 1, 1)),
      ),
    );
    await db.setSetting('currency_symbol', '€');

    final payload = JsonBackupData(
      categories: [
        JsonBackupCategory(
          id: 10,
          name: 'Budget',
          parentId: null,
          iconName: 'account_balance',
          colorValue: 0xFF4CAF50,
          isSavings: false,
          sortOrder: 0,
          createdAt: DateTime(2026, 2, 1),
        ),
        JsonBackupCategory(
          id: 11,
          name: 'Emergency Fund',
          parentId: 10,
          iconName: 'savings',
          colorValue: 0xFF26A69A,
          isSavings: true,
          sortOrder: 0,
          createdAt: DateTime(2026, 2, 1),
        ),
      ],
      recurringExpenses: [
        JsonBackupRecurringExpense(
          id: 'rec-1',
          name: 'Monthly Savings',
          amountCents: 20000,
          categoryId: 11,
          interval: 'monthly',
          startDate: DateTime(2026, 2, 1),
          endDate: null,
          lastGeneratedDate: null,
          isActive: true,
          createdAt: DateTime(2026, 2, 1),
          updatedAt: DateTime(2026, 2, 1),
        ),
      ],
      expenses: [
        JsonBackupExpense(
          id: 'exp-1',
          amountCents: 20000,
          description: 'Transfer savings',
          categoryId: 11,
          date: DateTime(2026, 2, 5),
          notes: null,
          recurringExpenseId: 'rec-1',
          createdAt: DateTime(2026, 2, 5),
          updatedAt: DateTime(2026, 2, 5),
        ),
      ],
      settings: const {'currency_symbol': r'$', 'theme_mode': 'dark'},
    );

    await repository.restore(payload);

    final categories = await db.getAllCategories();
    final expenses = await db.getAllExpenses();
    final recurring = await db.getAllRecurringExpenses();

    expect(categories, hasLength(2));
    expect(categories.where((c) => c.isSavings), hasLength(1));
    expect(expenses, hasLength(1));
    expect(expenses.single.id, 'exp-1');
    expect(recurring, hasLength(1));
    expect(recurring.single.id, 'rec-1');
    expect(await db.getSetting('currency_symbol'), r'$');
    expect(await db.getSetting('theme_mode'), 'dark');
  });

  test('restore is atomic and rolls back when insertion fails', () async {
    await db.insertCategory(CategoriesCompanion.insert(name: 'Keep Me'));
    await db.setSetting('theme_mode', 'system');

    final invalidPayload = JsonBackupData(
      categories: [
        JsonBackupCategory(
          id: 1,
          name: 'One',
          parentId: null,
          iconName: 'category',
          colorValue: 0xFF9E9E9E,
          isSavings: false,
          sortOrder: 0,
          createdAt: DateTime(2026, 3, 1),
        ),
        JsonBackupCategory(
          id: 1,
          name: 'Duplicate',
          parentId: null,
          iconName: 'category',
          colorValue: 0xFF9E9E9E,
          isSavings: false,
          sortOrder: 0,
          createdAt: DateTime(2026, 3, 1),
        ),
      ],
      recurringExpenses: const [],
      expenses: const [],
      settings: const {'theme_mode': 'dark'},
    );

    await expectLater(
      () => repository.restore(invalidPayload),
      throwsA(anything),
    );

    final categoriesAfter = await db.getAllCategories();
    expect(categoriesAfter, isNotEmpty);
    expect(categoriesAfter.single.name, 'Keep Me');
    expect(await db.getSetting('theme_mode'), 'system');
  });
}
