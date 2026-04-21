import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/autocomplete_suggestion.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../categories/domain/entities/category_entity.dart';

/// Stream of all expenses (reactive).
final expenseListProvider = StreamProvider<List<ExpenseEntity>>((ref) {
  return ref.watch(getExpensesProvider).watch();
});

/// Stream of expenses for the current month.
final currentMonthExpensesProvider = StreamProvider<List<ExpenseEntity>>((ref) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  return ref.watch(getExpensesProvider).watchInRange(start, end);
});

/// Autocomplete suggestions for a query string.
final autocompleteSuggestionsProvider = FutureProvider.autoDispose
    .family<List<AutocompleteSuggestion>, String>((ref, query) {
      return ref.watch(getAutocompleteSuggestionsProvider).call(query);
    });

/// All categories (reactive stream).
final allCategoriesProvider = StreamProvider<List<CategoryEntity>>((ref) {
  return ref.watch(getCategoriesProvider).watch();
});

/// Category lookup map derived from [allCategoriesProvider].
final categoryMapProvider = Provider<Map<int, CategoryEntity>>((ref) {
  final categories = ref.watch(allCategoriesProvider).value;
  if (categories == null || categories.isEmpty) {
    return const <int, CategoryEntity>{};
  }
  return {for (final c in categories) c.id: c};
});

/// Committed recurring amount for this month.
final committedAmountProvider = FutureProvider<int>((ref) {
  return ref.watch(getCommittedAmountProvider).call();
});
