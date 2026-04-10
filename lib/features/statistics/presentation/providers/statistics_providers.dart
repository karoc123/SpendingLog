import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../expenses/domain/entities/expense_entity.dart';
import '../../domain/usecases/get_spending_by_category.dart';
import '../../domain/usecases/get_spending_summary.dart';

/// Currently selected view mode for statistics.
enum StatsViewMode { monthly, yearly }

final statsViewModeProvider = StateProvider<StatsViewMode>((ref) {
  return StatsViewMode.monthly;
});

/// The currently viewed date (month/year perspective).
final statsDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

/// Date range derived from view mode + date.
final statsDateRangeProvider = Provider<(DateTime, DateTime)>((ref) {
  final mode = ref.watch(statsViewModeProvider);
  final date = ref.watch(statsDateProvider);

  switch (mode) {
    case StatsViewMode.monthly:
      final start = DateTime(date.year, date.month, 1);
      final end = DateTime(date.year, date.month + 1, 0, 23, 59, 59);
      return (start, end);
    case StatsViewMode.yearly:
      final start = DateTime(date.year, 1, 1);
      final end = DateTime(date.year, 12, 31, 23, 59, 59);
      return (start, end);
  }
});

/// Spending by category for the current stats period.
final spendingByCategoryProvider = FutureProvider<List<CategorySpending>>((
  ref,
) {
  final (start, end) = ref.watch(statsDateRangeProvider);
  return ref.watch(getSpendingByCategoryProvider).call(start, end);
});

/// Spending summary for the current stats period.
final spendingSummaryProvider = FutureProvider<SpendingSummary>((ref) {
  final (start, end) = ref.watch(statsDateRangeProvider);
  return ref.watch(getSpendingSummaryProvider).call(start, end);
});

/// Currently selected category in the chart for drill-down filtering.
final selectedChartCategoryProvider = StateProvider<int?>((ref) {
  return null;
});

typedef StatsExpenseFilter = ({DateTime start, DateTime end, int? categoryId});

final filteredStatsExpensesProvider =
    FutureProvider.family<List<ExpenseEntity>, StatsExpenseFilter>((
      ref,
      filter,
    ) {
      final getExpenses = ref.watch(getExpensesProvider);
      if (filter.categoryId != null) {
        return getExpenses.byCategory(
          filter.categoryId!,
          filter.start,
          filter.end,
        );
      }
      return getExpenses.inRange(filter.start, filter.end);
    });
