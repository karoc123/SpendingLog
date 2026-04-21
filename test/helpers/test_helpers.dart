import 'package:mocktail/mocktail.dart';

import 'package:spending_log/features/expenses/domain/entities/expense_entity.dart';
import 'package:spending_log/features/expenses/domain/repositories/expense_repository.dart';
import 'package:spending_log/features/categories/domain/entities/category_entity.dart';
import 'package:spending_log/features/categories/domain/repositories/category_repository.dart';
import 'package:spending_log/features/recurring/domain/entities/recurring_expense_entity.dart';
import 'package:spending_log/features/recurring/domain/repositories/recurring_expense_repository.dart';
import 'package:spending_log/features/settings/domain/repositories/settings_repository.dart';

// ---------------------------------------------------------------------------
// Mock repositories
// ---------------------------------------------------------------------------

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockRecurringExpenseRepository extends Mock
    implements RecurringExpenseRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

// ---------------------------------------------------------------------------
// Test data factories
// ---------------------------------------------------------------------------

ExpenseEntity makeExpense({
  String id = 'test-id',
  int amountCents = 1250,
  String description = 'Test expense',
  int categoryId = 1,
  DateTime? date,
  String? notes,
  String? recurringExpenseId,
}) => ExpenseEntity(
  id: id,
  amountCents: amountCents,
  description: description,
  categoryId: categoryId,
  date: date ?? DateTime(2026, 4, 10),
  notes: notes,
  recurringExpenseId: recurringExpenseId,
  createdAt: DateTime(2026, 4, 10),
  updatedAt: DateTime(2026, 4, 10),
);

CategoryEntity makeCategory({
  int id = 1,
  String name = 'Test Category',
  int? parentId,
  String iconName = 'category',
  int colorValue = 0xFF4CAF50,
  int sortOrder = 0,
}) => CategoryEntity(
  id: id,
  name: name,
  parentId: parentId,
  iconName: iconName,
  colorValue: colorValue,
  sortOrder: sortOrder,
  createdAt: DateTime(2026, 1, 1),
);

RecurringExpenseEntity makeRecurring({
  String id = 'recurring-1',
  String name = 'Netflix',
  int amountCents = 1599,
  int categoryId = 1,
  RecurringInterval interval = RecurringInterval.monthly,
  DateTime? startDate,
  DateTime? endDate,
  DateTime? lastGeneratedDate,
  bool isActive = true,
}) => RecurringExpenseEntity(
  id: id,
  name: name,
  amountCents: amountCents,
  categoryId: categoryId,
  interval: interval,
  startDate: startDate ?? DateTime(2026, 1, 1),
  endDate: endDate,
  lastGeneratedDate: lastGeneratedDate,
  isActive: isActive,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);
