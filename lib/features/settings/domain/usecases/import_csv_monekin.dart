import 'package:csv/csv.dart';
import 'package:uuid/uuid.dart';

import '../../../expenses/domain/entities/expense_entity.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../categories/domain/repositories/category_repository.dart';
import 'csv_import_utils.dart';

const _uuid = Uuid();

/// Imports expenses from a Monekin CSV export.
///
/// Supports the format of Monekin CSV:
/// ID, Amount, Date, Title, Note, Account, Currency, Category, Subcategory
///
/// Categories/subcategories are matched by name; new ones are created if
/// they don't exist.
class ImportCsvMonekin {
  final ExpenseRepository _expenseRepository;
  final CategoryRepository _categoryRepository;

  ImportCsvMonekin(this._expenseRepository, this._categoryRepository);

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
        categoriesByName[CsvImportUtils.normalizeName(category.name)] =
            category;
      } else {
        subcategoriesByParentAndName[CsvImportUtils.subcategoryKey(
              category.parentId!,
              category.name,
            )] =
            category;
      }
    }

    int imported = 0;

    for (final row in dataRows) {
      if (row.length < 8) continue;

      final amount = CsvImportUtils.parseAmount(row[1].toString());
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
        var parentCat =
            categoriesByName[CsvImportUtils.normalizeName(parentCategoryName)];
        if (parentCat == null) {
          final now = DateTime.now();
          final colorValue = CsvImportUtils.deterministicColor(
            parentCategoryName,
          );
          // Create new parent category.
          final newId = await _categoryRepository.addCategory(
            CategoryEntity(
              id: 0,
              name: parentCategoryName,
              colorValue: colorValue,
              createdAt: now,
            ),
          );
          parentCat = CategoryEntity(
            id: newId,
            name: parentCategoryName,
            colorValue: colorValue,
            createdAt: now,
          );
          categoriesByName[CsvImportUtils.normalizeName(parentCategoryName)] =
              parentCat;
        }

        if (categoryName.isNotEmpty) {
          final key = CsvImportUtils.subcategoryKey(parentCat.id, categoryName);
          var subCat = subcategoriesByParentAndName[key];
          if (subCat == null) {
            final now = DateTime.now();
            final newId = await _categoryRepository.addCategory(
              CategoryEntity(
                id: 0,
                name: categoryName,
                parentId: parentCat.id,
                colorValue: parentCat.colorValue,
                createdAt: now,
              ),
            );
            subCat = CategoryEntity(
              id: newId,
              name: categoryName,
              parentId: parentCat.id,
              colorValue: parentCat.colorValue,
              createdAt: now,
            );
            subcategoriesByParentAndName[key] = subCat;
          }
          categoryId = subCat.id;
        } else {
          categoryId = parentCat.id;
        }
      } else {
        // Default to first category (Miscellaneous-like).
        var misc =
            categoriesByName['sonstiges'] ??
            categoriesByName['miscellaneous'] ??
            (existingCategories.isEmpty ? null : existingCategories.first);
        if (misc == null) {
          final now = DateTime.now();
          final newId = await _categoryRepository.addCategory(
            CategoryEntity(
              id: 0,
              name: 'Import',
              colorValue: CsvImportUtils.deterministicColor('Import'),
              createdAt: now,
            ),
          );
          misc = CategoryEntity(
            id: newId,
            name: 'Import',
            colorValue: CsvImportUtils.deterministicColor('Import'),
            createdAt: now,
          );
          categoriesByName[CsvImportUtils.normalizeName(misc.name)] = misc;
        }
        categoryId = misc.id;
      }

      final now = DateTime.now();
      final expense = ExpenseEntity(
        id: _uuid.v4(),
        amountCents: amountCents,
        description: title,
        categoryId: categoryId,
        date: date,
        notes: note.isNotEmpty ? note : null,
        createdAt: now,
        updatedAt: now,
      );

      await _expenseRepository.addExpense(expense);
      imported++;
    }

    await CsvImportUtils.cleanupUnusedSeedDefaults(
      categoryRepository: _categoryRepository,
      expenseRepository: _expenseRepository,
    );

    return imported;
  }
}
