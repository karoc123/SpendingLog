import '../../../expenses/domain/repositories/expense_repository.dart';

class SpendingSummary {
  final int totalCents;
  final String topCategoryName;
  final int transactionCount;

  const SpendingSummary({
    required this.totalCents,
    required this.topCategoryName,
    required this.transactionCount,
  });
}

class GetSpendingSummary {
  final ExpenseRepository _expenseRepository;

  GetSpendingSummary(this._expenseRepository);

  Future<SpendingSummary> call(DateTime start, DateTime end) async {
    final expenses = await _expenseRepository.getExpensesInRange(start, end);

    if (expenses.isEmpty) {
      return const SpendingSummary(
        totalCents: 0,
        topCategoryName: '-',
        transactionCount: 0,
      );
    }

    final totalCents = expenses.fold<int>(0, (sum, e) => sum + e.amountCents);

    // Find the category with the highest absolute spending.
    // We can only return category ID here; the name is resolved in the
    // presentation layer. For simplicity, count by categoryId.
    final categoryTotals = <int, int>{};
    for (final e in expenses) {
      categoryTotals[e.categoryId] =
          (categoryTotals[e.categoryId] ?? 0) + e.amountCents;
    }
    final topCategoryId = categoryTotals.entries
        .reduce((a, b) => a.value.abs() > b.value.abs() ? a : b)
        .key;

    return SpendingSummary(
      totalCents: totalCents,
      topCategoryName: topCategoryId.toString(), // resolved in provider
      transactionCount: expenses.length,
    );
  }
}
