import 'package:csv/csv.dart';

import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../categories/domain/repositories/category_repository.dart';

/// Exports expenses in [start]..[end] as CSV string.
class ExportCsv {
  final ExpenseRepository _expenseRepository;
  final CategoryRepository _categoryRepository;

  ExportCsv(this._expenseRepository, this._categoryRepository);

  Future<String> call(DateTime start, DateTime end) async {
    final expenses = await _expenseRepository.getExpensesInRange(start, end);
    final categories = await _categoryRepository.getAllCategories();
    final catMap = {for (final c in categories) c.id: c};

    final rows = <List<dynamic>>[
      [
        'ID',
        'Amount',
        'Date',
        'Description',
        'Notes',
        'Category',
        'Subcategory',
        'Recurring',
      ],
    ];

    for (final e in expenses) {
      final cat = catMap[e.categoryId];
      final parentCat = cat?.parentId != null ? catMap[cat!.parentId] : null;
      rows.add([
        e.id,
        (e.amountCents / 100).toStringAsFixed(2),
        e.date.toIso8601String(),
        e.description,
        e.notes ?? '',
        parentCat?.name ?? cat?.name ?? '',
        parentCat != null ? (cat?.name ?? '') : '',
        e.isRecurring ? 'true' : 'false',
      ]);
    }

    return const CsvEncoder().convert(rows);
  }
}
