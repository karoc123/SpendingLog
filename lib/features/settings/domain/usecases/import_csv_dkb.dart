import 'package:csv/csv.dart';
import 'package:uuid/uuid.dart';

import '../../../expenses/domain/entities/expense_entity.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../categories/domain/repositories/category_repository.dart';
import 'csv_import_utils.dart';

const _uuid = Uuid();

/// Imports expenses from a DKB (Deutsche Kreditbank) CSV export.
///
/// DKB CSV format is German locale with semicolon delimiters:
/// Buchungsdatum, Wertstellung, Status, Zahlungspflichtiger, Zahlungsempfänger*in,
/// Verwendungszweck, Umsatztyp, IBAN, Betrag(€), ...
///
/// - Only imports "Ausgang" (outgoing) transactions
/// - Description from "Zahlungsempfänger*in" (recipient)
/// - Category lookup by recipient name from transaction history
/// - If no history exists, creates new category
class ImportCsvDkb {
  final ExpenseRepository _expenseRepository;
  final CategoryRepository _categoryRepository;

  ImportCsvDkb(this._expenseRepository, this._categoryRepository);

  /// Find the category that was most recently used with a given recipient.
  Future<CategoryEntity?> _findCategoryByRecipient(
    String recipient,
    Map<int, CategoryEntity> categoryMap,
  ) async {
    if (recipient.trim().isEmpty) return null;
    final lastExpense = await _expenseRepository.findLatestExpenseByDescription(
      recipient,
    );
    if (lastExpense == null) return null;
    return categoryMap[lastExpense.categoryId];
  }

  Future<int> call(String csvContent) async {
    final trimmed = csvContent.trim();
    if (trimmed.isEmpty) return 0;

    final rows = CsvDecoder(
      fieldDelimiter: ';',
      dynamicTyping: false,
    ).convert(trimmed);

    if (rows.isEmpty) return 0;

    /// Skip bank name and balance rows (they appear before header).
    int headerIndex = 0;
    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row.isNotEmpty &&
          row.length > 8 &&
          row[0].toString().contains('Buchungsdatum')) {
        headerIndex = i;
        break;
      }
    }

    final dataRows = rows.skip(headerIndex + 1).toList();
    if (dataRows.isEmpty) return 0;

    // Load existing data
    final existingCategories = await _categoryRepository.getAllCategories();
    final categoryMap = {for (final c in existingCategories) c.id: c};
    final recipientCategoryCache = <String, CategoryEntity?>{};

    int imported = 0;

    for (final row in dataRows) {
      if (row.length < 9) continue;

      // Column 6: Umsatztyp - filter for "Ausgang" only
      final umsatztyp = row[6].toString().trim();
      if (umsatztyp != 'Ausgang') continue;

      // Column 8: Amount (must be negative for expenses)
      final amount = CsvImportUtils.parseAmount(row[8].toString());
      if (amount == null || amount >= 0) continue;

      // Convert to positive cents
      final amountCents = (amount.abs() * 100).round();

      // Column 0: Date (format: DD.MM.YY)
      final dateStr = row[0].toString().trim();
      DateTime? date;
      try {
        final parts = dateStr.split('.');
        if (parts.length == 3) {
          final yearToken = parts[2];
          final parsedYear = int.parse(yearToken);
          final year = yearToken.length == 2 ? 2000 + parsedYear : parsedYear;
          date = DateTime(year, int.parse(parts[1]), int.parse(parts[0]));
        }
      } catch (_) {}
      if (date == null) continue;

      // Column 4: Zahlungsempfänger*in - becomes description
      final recipient = row[4].toString().trim();
      if (recipient.isEmpty) continue;

      // Column 5: Verwendungszweck - optional notes
      final purpose = row.length > 5 ? row[5].toString().trim() : '';

      // Category lookup: find by recipient from history, or create new
      int categoryId;
      final recipientKey = CsvImportUtils.normalizeName(recipient);
      CategoryEntity? existingCat;
      if (recipientCategoryCache.containsKey(recipientKey)) {
        existingCat = recipientCategoryCache[recipientKey];
      } else {
        existingCat = await _findCategoryByRecipient(recipient, categoryMap);
        recipientCategoryCache[recipientKey] = existingCat;
      }

      if (existingCat != null) {
        categoryId = existingCat.id;
      } else {
        /// No history for this recipient - use "Import" fallback category.
        CategoryEntity? importCat;
        for (final category in categoryMap.values) {
          if (CsvImportUtils.normalizeName(category.name) == 'import' &&
              category.parentId == null) {
            importCat = category;
            break;
          }
        }

        if (importCat == null) {
          final now = DateTime.now();
          final newCatId = await _categoryRepository.addCategory(
            CategoryEntity(
              id: 0,
              name: 'Import',
              colorValue: CsvImportUtils.deterministicColor('Import'),
              createdAt: now,
            ),
          );
          categoryId = newCatId;
          categoryMap[newCatId] = CategoryEntity(
            id: newCatId,
            name: 'Import',
            colorValue: CsvImportUtils.deterministicColor('Import'),
            createdAt: now,
          );
        } else {
          categoryId = importCat.id;
        }
      }

      final now = DateTime.now();
      final expense = ExpenseEntity(
        id: _uuid.v4(),
        amountCents: amountCents,
        description: recipient,
        categoryId: categoryId,
        date: date,
        notes: purpose.isNotEmpty ? purpose : null,
        createdAt: now,
        updatedAt: now,
      );

      await _expenseRepository.addExpense(expense);
      imported++;
    }

    return imported;
  }
}
