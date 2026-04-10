import 'package:csv/csv.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/icon_map.dart';
import '../../../expenses/domain/entities/expense_entity.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../categories/domain/repositories/category_repository.dart';

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

  /// Parses amount from DKB format (German decimal: 1.234,56)
  static double? _parseAmount(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return null;

    final hasComma = s.contains(',');
    final hasDot = s.contains('.');

    if (hasComma && hasDot) {
      if (s.lastIndexOf(',') > s.lastIndexOf('.')) {
        // German: 1.234,56 → remove dots, comma → dot
        s = s.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // English: 1,234.56 → remove commas
        s = s.replaceAll(',', '');
      }
    } else if (hasComma) {
      s = s.replaceAll(',', '.');
    }

    return double.tryParse(s);
  }

  static String _normalizeName(String name) => name.trim().toLowerCase();

  static int _deterministicColor(String name) {
    var hash = 0;
    for (final code in name.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return availableCategoryColors[hash % availableCategoryColors.length];
  }

  /// Find the category that was most recently used with a given recipient.
  Future<CategoryEntity?> _findCategoryByRecipient(
    String recipient,
    List<ExpenseEntity> allExpenses,
    Map<int, CategoryEntity> categoryMap,
  ) async {
    if (recipient.trim().isEmpty) return null;

    final normalizedRecipient = _normalizeName(recipient);

    /// Search in all expenses (on real data, this would use database query)
    ExpenseEntity? lastExpenseWithRecipient;
    for (final expense in allExpenses) {
      final desc = _normalizeName(expense.description);
      if (desc == normalizedRecipient) {
        if (lastExpenseWithRecipient == null ||
            expense.date.isAfter(lastExpenseWithRecipient.date)) {
          lastExpenseWithRecipient = expense;
        }
      }
    }

    if (lastExpenseWithRecipient != null) {
      return categoryMap[lastExpenseWithRecipient.categoryId];
    }

    return null;
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
    final allExpenses = await _expenseRepository.getAllExpenses();
    final categoryMap = {for (final c in existingCategories) c.id: c};

    int imported = 0;

    for (final row in dataRows) {
      if (row.length < 9) continue;

      // Column 6: Umsatztyp - filter for "Ausgang" only
      final umsatztyp = row[6].toString().trim();
      if (umsatztyp != 'Ausgang') continue;

      // Column 8: Amount (must be negative for expenses)
      final amount = _parseAmount(row[8].toString());
      if (amount == null || amount >= 0) continue;

      // Convert to positive cents
      final amountCents = (amount.abs() * 100).round();

      // Column 0: Date (format: DD.MM.YY)
      final dateStr = row[0].toString().trim();
      DateTime? date;
      try {
        final parts = dateStr.split('.');
        if (parts.length == 3) {
          date = DateTime(
            int.parse('20${parts[2]}'),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
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
      var existingCat = await _findCategoryByRecipient(
        recipient,
        allExpenses,
        categoryMap,
      );

      if (existingCat != null) {
        categoryId = existingCat.id;
      } else {
        /// No history for this recipient - create a new category
        /// Use "Transaktionen" or similar default by recipient
        final newCatId = await _categoryRepository.addCategory(
          CategoryEntity(
            id: 0,
            name: recipient,
            colorValue: _deterministicColor(recipient),
            createdAt: DateTime.now(),
          ),
        );
        categoryId = newCatId;
      }

      final expense = ExpenseEntity(
        id: _uuid.v4(),
        amountCents: amountCents,
        description: recipient,
        categoryId: categoryId,
        date: date,
        notes: purpose.isNotEmpty ? purpose : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _expenseRepository.addExpense(expense);
      imported++;
    }

    return imported;
  }
}
