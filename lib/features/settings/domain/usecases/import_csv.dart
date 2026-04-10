import 'package:csv/csv.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/icon_map.dart';
import '../../../expenses/domain/entities/expense_entity.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../categories/domain/repositories/category_repository.dart';

const _uuid = Uuid();
const _seedDefaultParentNames = {
  'lebensmittel',
  'haushalt',
  'freizeit',
  'essen',
  'transport',
  'gesundheit',
  'arbeit',
  'sonstiges',
};

/// Imports expenses from a CSV string.
///
/// Supports the format of the example CSV:
/// ID, Amount, Date, Title, Note, Account, Currency, Category, Subcategory
///
/// Categories/subcategories are matched by name; new ones are created if
/// they don't exist.
class ImportCsv {
  final ExpenseRepository _expenseRepository;
  final CategoryRepository _categoryRepository;

  ImportCsv(this._expenseRepository, this._categoryRepository);

  /// Normalises an amount string that may use German number formatting
  /// (`1.234,56`) or standard formatting (`1234.56`) into a value that
  /// [double.tryParse] understands.
  static double? _parseAmount(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return null;

    final hasComma = s.contains(',');
    final hasDot = s.contains('.');

    if (hasComma && hasDot) {
      // Determine which is the decimal separator (it comes last).
      if (s.lastIndexOf(',') > s.lastIndexOf('.')) {
        // German: 1.234,56 → remove dots (thousands), comma → dot.
        s = s.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // English: 1,234.56 → remove commas (thousands).
        s = s.replaceAll(',', '');
      }
    } else if (hasComma) {
      // Only comma → treat as decimal separator.
      s = s.replaceAll(',', '.');
    }
    // Only dot or no separator → already fine for double.tryParse.

    return double.tryParse(s);
  }

  static String _normalizeName(String name) => name.trim().toLowerCase();

  static String _subcategoryKey(int parentId, String subcategoryName) {
    return '$parentId::${_normalizeName(subcategoryName)}';
  }

  static int _deterministicColor(String name) {
    var hash = 0;
    for (final code in name.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return availableCategoryColors[hash % availableCategoryColors.length];
  }

  Future<int> call(String csvContent) async {
    final trimmed = csvContent.trim();
    if (trimmed.isEmpty) return 0;

    // Auto-detect field separator: if the header line contains ';' it is
    // likely a German-locale CSV export.
    final firstLine = trimmed.split('\n').first;
    final separator = firstLine.contains(';') ? ';' : ',';

    final rows = CsvDecoder(
      fieldDelimiter: separator,
      dynamicTyping: false,
    ).convert(trimmed);
    if (rows.isEmpty) return 0;

    // First row is header — skip it.
    final dataRows = rows.skip(1).toList();
    if (dataRows.isEmpty) return 0;

    // Load existing categories.
    final existingCategories = await _categoryRepository.getAllCategories();
    final categoriesByName = <String, CategoryEntity>{};
    final subcategoriesByParentAndName = <String, CategoryEntity>{};
    for (final category in existingCategories) {
      if (category.parentId == null) {
        categoriesByName[_normalizeName(category.name)] = category;
      } else {
        subcategoriesByParentAndName[_subcategoryKey(
              category.parentId!,
              category.name,
            )] =
            category;
      }
    }

    int imported = 0;

    for (final row in dataRows) {
      if (row.length < 8) continue;

      final amount = _parseAmount(row[1].toString());
      if (amount == null) continue;

      // Skip positive values (credits/refunds) - import only expenses.
      if (amount >= 0) continue;

      // Convert to positive cents (CSV amounts may be negative for expenses).
      final amountCents = (amount.abs() * 100).round();

      final dateStr = row[2].toString();
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;

      final title = row[3].toString().trim();
      if (title.isEmpty) continue;

      final note = row.length > 4 ? row[4].toString().trim() : '';
      final parentCategoryName = row[7].toString().trim();
      final categoryName = row.length > 8 ? row[8].toString().trim() : '';

      // In CSV mapping: Category = parent category, Subcategory = category.
      int categoryId;
      if (parentCategoryName.isNotEmpty) {
        var parentCat = categoriesByName[_normalizeName(parentCategoryName)];
        if (parentCat == null) {
          // Create new parent category.
          final newId = await _categoryRepository.addCategory(
            CategoryEntity(
              id: 0,
              name: parentCategoryName,
              colorValue: _deterministicColor(parentCategoryName),
              createdAt: DateTime.now(),
            ),
          );
          parentCat = CategoryEntity(
            id: newId,
            name: parentCategoryName,
            colorValue: _deterministicColor(parentCategoryName),
            createdAt: DateTime.now(),
          );
          categoriesByName[_normalizeName(parentCategoryName)] = parentCat;
        }

        if (categoryName.isNotEmpty) {
          final key = _subcategoryKey(parentCat.id, categoryName);
          var subCat = subcategoriesByParentAndName[key];
          if (subCat == null) {
            final newId = await _categoryRepository.addCategory(
              CategoryEntity(
                id: 0,
                name: categoryName,
                parentId: parentCat.id,
                colorValue: parentCat.colorValue,
                createdAt: DateTime.now(),
              ),
            );
            subCat = CategoryEntity(
              id: newId,
              name: categoryName,
              parentId: parentCat.id,
              colorValue: parentCat.colorValue,
              createdAt: DateTime.now(),
            );
            subcategoriesByParentAndName[key] = subCat;
          }
          categoryId = subCat.id;
        } else {
          categoryId = parentCat.id;
        }
      } else {
        // Default to first category (Miscellaneous-like).
        final misc =
            categoriesByName['sonstiges'] ??
            categoriesByName['miscellaneous'] ??
            existingCategories.first;
        categoryId = misc.id;
      }

      final expense = ExpenseEntity(
        id: _uuid.v4(),
        amountCents: amountCents,
        description: title,
        categoryId: categoryId,
        date: date,
        notes: note.isNotEmpty ? note : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _expenseRepository.addExpense(expense);
      imported++;
    }

    await _cleanupUnusedSeedDefaults();

    return imported;
  }

  Future<void> _cleanupUnusedSeedDefaults() async {
    final allCategories = await _categoryRepository.getAllCategories();
    final allExpenses = await _expenseRepository.getAllExpenses();
    final usedCategoryIds = allExpenses.map((e) => e.categoryId).toSet();

    final categoryById = {for (final c in allCategories) c.id: c};
    final usedWithAncestors = <int>{...usedCategoryIds};
    for (final id in usedCategoryIds) {
      var current = categoryById[id];
      while (current?.parentId != null) {
        usedWithAncestors.add(current!.parentId!);
        current = categoryById[current.parentId!];
      }
    }

    for (final category in allCategories) {
      if (category.parentId != null) continue;
      final normalized = _normalizeName(category.name);
      if (!_seedDefaultParentNames.contains(normalized)) continue;
      if (usedWithAncestors.contains(category.id)) continue;
      final hasChildren = allCategories.any((c) => c.parentId == category.id);
      if (hasChildren) continue;
      await _categoryRepository.deleteCategory(category.id);
    }
  }
}
