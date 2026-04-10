import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../categories/domain/repositories/category_repository.dart';

class CategorySpending {
  final int categoryId;
  final String categoryName;
  final int? parentId;
  final int colorValue;
  final String iconName;
  final int totalCents;
  final int transactionCount;

  const CategorySpending({
    required this.categoryId,
    required this.categoryName,
    this.parentId,
    required this.colorValue,
    required this.iconName,
    required this.totalCents,
    required this.transactionCount,
  });
}

class GetSpendingByCategory {
  final ExpenseRepository _expenseRepository;
  final CategoryRepository _categoryRepository;

  GetSpendingByCategory(this._expenseRepository, this._categoryRepository);

  /// Returns spending aggregated by parent category for the given range.
  /// Subcategory spending is rolled up into parent totals for the pie chart.
  Future<List<CategorySpending>> call(DateTime start, DateTime end) async {
    final expenses = await _expenseRepository.getExpensesInRange(start, end);
    final categories = await _categoryRepository.getAllCategories();

    final categoryMap = {for (final c in categories) c.id: c};

    // Aggregate by resolving each expense's category to its parent.
    final parentTotals = <int, _Accumulator>{};

    for (final expense in expenses) {
      final cat = categoryMap[expense.categoryId];
      if (cat == null) continue;

      final parentId = cat.parentId ?? cat.id;
      final parent = categoryMap[parentId] ?? cat;

      final acc = parentTotals.putIfAbsent(
        parentId,
        () => _Accumulator(parent),
      );
      acc.totalCents += expense.amountCents;
      acc.count++;
    }

    final result =
        parentTotals.values
            .map(
              (a) => CategorySpending(
                categoryId: a.category.id,
                categoryName: a.category.name,
                parentId: a.category.parentId,
                colorValue: a.category.colorValue,
                iconName: a.category.iconName,
                totalCents: a.totalCents,
                transactionCount: a.count,
              ),
            )
            .toList()
          ..sort((a, b) => a.totalCents.compareTo(b.totalCents));

    return result;
  }

  /// Returns spending for sub-categories of [parentCategoryId].
  Future<List<CategorySpending>> subcategoryBreakdown(
    int parentCategoryId,
    DateTime start,
    DateTime end,
  ) async {
    final expenses = await _expenseRepository.getExpensesInRange(start, end);
    final categories = await _categoryRepository.getAllCategories();
    final categoryMap = {for (final c in categories) c.id: c};

    // Include expenses in the parent itself and its children.
    final childIds =
        categories
            .where((c) => c.parentId == parentCategoryId)
            .map((c) => c.id)
            .toSet()
          ..add(parentCategoryId);

    final totals = <int, _Accumulator>{};
    for (final expense in expenses) {
      if (!childIds.contains(expense.categoryId)) continue;
      final cat = categoryMap[expense.categoryId]!;
      final acc = totals.putIfAbsent(cat.id, () => _Accumulator(cat));
      acc.totalCents += expense.amountCents;
      acc.count++;
    }

    return totals.values
        .map(
          (a) => CategorySpending(
            categoryId: a.category.id,
            categoryName: a.category.name,
            parentId: a.category.parentId,
            colorValue: a.category.colorValue,
            iconName: a.category.iconName,
            totalCents: a.totalCents,
            transactionCount: a.count,
          ),
        )
        .toList()
      ..sort((a, b) => a.totalCents.compareTo(b.totalCents));
  }
}

class _Accumulator {
  final CategoryEntity category;
  int totalCents = 0;
  int count = 0;

  _Accumulator(this.category);
}
