import 'package:csv/csv.dart';
import 'package:uuid/uuid.dart';

import '../../../expenses/domain/entities/expense_entity.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../categories/domain/repositories/category_repository.dart';

const _uuid = Uuid();

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

  Future<int> call(String csvContent) async {
    final rows = const CsvToListConverter(eol: '\n').convert(csvContent.trim());
    if (rows.isEmpty) return 0;

    // First row is header — skip it.
    final dataRows = rows.skip(1).toList();
    if (dataRows.isEmpty) return 0;

    // Load existing categories.
    final existingCategories = await _categoryRepository.getAllCategories();
    final categoryByName = <String, CategoryEntity>{
      for (final c in existingCategories) c.name.toLowerCase(): c,
    };

    int imported = 0;

    for (final row in dataRows) {
      if (row.length < 8) continue;

      final amountStr = row[1].toString();
      final amount = double.tryParse(amountStr);
      if (amount == null) continue;

      // Convert to positive cents (CSV amounts may be negative for expenses).
      final amountCents = (amount.abs() * 100).round();

      final dateStr = row[2].toString();
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;

      final title = row[3].toString().trim();
      if (title.isEmpty) continue;

      final note = row.length > 4 ? row[4].toString().trim() : '';
      final categoryName = row[7].toString().trim();
      final subcategoryName = row.length > 8 ? row[8].toString().trim() : '';

      // Resolve or create parent category.
      int categoryId;
      if (categoryName.isNotEmpty) {
        var parentCat = categoryByName[categoryName.toLowerCase()];
        if (parentCat == null) {
          // Create new parent category.
          final newId = await _categoryRepository.addCategory(
            CategoryEntity(
              id: 0,
              name: categoryName,
              createdAt: DateTime.now(),
            ),
          );
          parentCat = CategoryEntity(
            id: newId,
            name: categoryName,
            createdAt: DateTime.now(),
          );
          categoryByName[categoryName.toLowerCase()] = parentCat;
        }

        if (subcategoryName.isNotEmpty) {
          final subKey = subcategoryName.toLowerCase();
          var subCat = categoryByName[subKey];
          if (subCat == null || subCat.parentId != parentCat.id) {
            final newId = await _categoryRepository.addCategory(
              CategoryEntity(
                id: 0,
                name: subcategoryName,
                parentId: parentCat.id,
                createdAt: DateTime.now(),
              ),
            );
            subCat = CategoryEntity(
              id: newId,
              name: subcategoryName,
              parentId: parentCat.id,
              createdAt: DateTime.now(),
            );
            categoryByName[subKey] = subCat;
          }
          categoryId = subCat.id;
        } else {
          categoryId = parentCat.id;
        }
      } else {
        // Default to first category (Miscellaneous-like).
        final misc =
            categoryByName['sonstiges'] ??
            categoryByName['miscellaneous'] ??
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

    return imported;
  }
}
