import 'dart:convert';

import '../../../expenses/domain/entities/expense_entity.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../categories/domain/repositories/category_repository.dart';
import '../../../recurring/domain/entities/recurring_expense_entity.dart';
import '../../../recurring/domain/repositories/recurring_expense_repository.dart';
import '../repositories/settings_repository.dart';

/// Full JSON backup of all data.
class ExportJson {
  final ExpenseRepository _expenseRepository;
  final CategoryRepository _categoryRepository;
  final RecurringExpenseRepository _recurringRepository;
  final SettingsRepository _settingsRepository;

  ExportJson(
    this._expenseRepository,
    this._categoryRepository,
    this._recurringRepository,
    this._settingsRepository,
  );

  Future<String> call() async {
    final expenses = await _expenseRepository.getAllExpenses();
    final categories = await _categoryRepository.getAllCategories();
    final recurring = await _recurringRepository.getAllRecurringExpenses();
    final settings = await _settingsRepository.getAllSettings();

    final data = {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'categories': categories.map(_categoryToMap).toList(),
      'expenses': expenses.map(_expenseToMap).toList(),
      'recurring_expenses': recurring.map(_recurringToMap).toList(),
      'settings': settings,
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Map<String, dynamic> _categoryToMap(CategoryEntity c) => {
    'id': c.id,
    'name': c.name,
    'parent_id': c.parentId,
    'icon_name': c.iconName,
    'color_value': c.colorValue,
    'sort_order': c.sortOrder,
    'created_at': c.createdAt.toIso8601String(),
  };

  Map<String, dynamic> _expenseToMap(ExpenseEntity e) => {
    'id': e.id,
    'amount_cents': e.amountCents,
    'description': e.description,
    'category_id': e.categoryId,
    'date': e.date.toIso8601String(),
    'notes': e.notes,
    'recurring_expense_id': e.recurringExpenseId,
    'created_at': e.createdAt.toIso8601String(),
    'updated_at': e.updatedAt.toIso8601String(),
  };

  Map<String, dynamic> _recurringToMap(RecurringExpenseEntity r) => {
    'id': r.id,
    'name': r.name,
    'amount_cents': r.amountCents,
    'category_id': r.categoryId,
    'interval': r.interval.name,
    'start_date': r.startDate.toIso8601String(),
    'last_generated_date': r.lastGeneratedDate?.toIso8601String(),
    'is_active': r.isActive,
    'created_at': r.createdAt.toIso8601String(),
    'updated_at': r.updatedAt.toIso8601String(),
  };
}
