import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../../features/expenses/data/repositories/expense_repository_impl.dart';
import '../../features/expenses/domain/repositories/expense_repository.dart';
import '../../features/expenses/domain/usecases/add_expense.dart';
import '../../features/expenses/domain/usecases/delete_expense.dart';
import '../../features/expenses/domain/usecases/get_autocomplete_suggestions.dart';
import '../../features/expenses/domain/usecases/get_expenses.dart';
import '../../features/expenses/domain/usecases/update_expense.dart';
import '../../features/categories/data/repositories/category_repository_impl.dart';
import '../../features/categories/domain/repositories/category_repository.dart';
import '../../features/categories/domain/usecases/add_category.dart';
import '../../features/categories/domain/usecases/delete_category.dart';
import '../../features/categories/domain/usecases/get_categories.dart';
import '../../features/categories/domain/usecases/update_category.dart';
import '../../features/recurring/data/repositories/recurring_expense_repository_impl.dart';
import '../../features/recurring/domain/repositories/recurring_expense_repository.dart';
import '../../features/recurring/domain/usecases/add_recurring_expense.dart';
import '../../features/recurring/domain/usecases/delete_recurring_expense.dart';
import '../../features/recurring/domain/usecases/generate_recurring_entries.dart';
import '../../features/recurring/domain/usecases/get_committed_amount.dart';
import '../../features/recurring/domain/usecases/get_recurring_expenses.dart';
import '../../features/recurring/domain/usecases/update_recurring_expense.dart';
import '../../features/statistics/domain/usecases/get_spending_by_category.dart';
import '../../features/statistics/domain/usecases/get_spending_summary.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/export_csv.dart';
import '../../features/settings/domain/usecases/export_json.dart';
import '../../features/settings/domain/usecases/get_setting.dart';
import '../../features/settings/domain/usecases/import_csv_monekin.dart';
import '../../features/settings/domain/usecases/import_csv_dkb.dart';
import '../../features/settings/domain/usecases/update_setting.dart';

const requiredOnboardingVersion = '1';

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.defaults();
  ref.onDispose(() => db.close());
  return db;
});

// ---------------------------------------------------------------------------
// Repositories
// ---------------------------------------------------------------------------

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepositoryImpl(ref.watch(databaseProvider));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(ref.watch(databaseProvider));
});

final recurringExpenseRepositoryProvider = Provider<RecurringExpenseRepository>(
  (ref) {
    return RecurringExpenseRepositoryImpl(ref.watch(databaseProvider));
  },
);

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(ref.watch(databaseProvider));
});

// ---------------------------------------------------------------------------
// Expense use cases
// ---------------------------------------------------------------------------

final addExpenseProvider = Provider<AddExpense>((ref) {
  return AddExpense(ref.watch(expenseRepositoryProvider));
});

final getExpensesProvider = Provider<GetExpenses>((ref) {
  return GetExpenses(ref.watch(expenseRepositoryProvider));
});

final updateExpenseProvider = Provider<UpdateExpense>((ref) {
  return UpdateExpense(ref.watch(expenseRepositoryProvider));
});

final deleteExpenseProvider = Provider<DeleteExpense>((ref) {
  return DeleteExpense(ref.watch(expenseRepositoryProvider));
});

final getAutocompleteSuggestionsProvider = Provider<GetAutocompleteSuggestions>(
  (ref) {
    return GetAutocompleteSuggestions(ref.watch(expenseRepositoryProvider));
  },
);

// ---------------------------------------------------------------------------
// Category use cases
// ---------------------------------------------------------------------------

final getCategoriesProvider = Provider<GetCategories>((ref) {
  return GetCategories(ref.watch(categoryRepositoryProvider));
});

final addCategoryProvider = Provider<AddCategory>((ref) {
  return AddCategory(ref.watch(categoryRepositoryProvider));
});

final updateCategoryProvider = Provider<UpdateCategory>((ref) {
  return UpdateCategory(ref.watch(categoryRepositoryProvider));
});

final deleteCategoryProvider = Provider<DeleteCategory>((ref) {
  return DeleteCategory(ref.watch(categoryRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Recurring use cases
// ---------------------------------------------------------------------------

final addRecurringExpenseProvider = Provider<AddRecurringExpense>((ref) {
  return AddRecurringExpense(ref.watch(recurringExpenseRepositoryProvider));
});

final getRecurringExpensesProvider = Provider<GetRecurringExpenses>((ref) {
  return GetRecurringExpenses(ref.watch(recurringExpenseRepositoryProvider));
});

final updateRecurringExpenseProvider = Provider<UpdateRecurringExpense>((ref) {
  return UpdateRecurringExpense(ref.watch(recurringExpenseRepositoryProvider));
});

final deleteRecurringExpenseProvider = Provider<DeleteRecurringExpense>((ref) {
  return DeleteRecurringExpense(ref.watch(recurringExpenseRepositoryProvider));
});

final generateRecurringEntriesProvider = Provider<GenerateRecurringEntries>((
  ref,
) {
  return GenerateRecurringEntries(
    ref.watch(recurringExpenseRepositoryProvider),
    ref.watch(expenseRepositoryProvider),
  );
});

final getCommittedAmountProvider = Provider<GetCommittedAmount>((ref) {
  return GetCommittedAmount(ref.watch(recurringExpenseRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Statistics use cases
// ---------------------------------------------------------------------------

final getSpendingByCategoryProvider = Provider<GetSpendingByCategory>((ref) {
  return GetSpendingByCategory(
    ref.watch(expenseRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
  );
});

final getSpendingSummaryProvider = Provider<GetSpendingSummary>((ref) {
  return GetSpendingSummary(ref.watch(expenseRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Settings use cases
// ---------------------------------------------------------------------------

final getSettingProvider = Provider<GetSetting>((ref) {
  return GetSetting(ref.watch(settingsRepositoryProvider));
});

final updateSettingProvider = Provider<UpdateSetting>((ref) {
  return UpdateSetting(ref.watch(settingsRepositoryProvider));
});

final exportCsvProvider = Provider<ExportCsv>((ref) {
  return ExportCsv(
    ref.watch(expenseRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
  );
});

final exportJsonProvider = Provider<ExportJson>((ref) {
  return ExportJson(
    ref.watch(expenseRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
    ref.watch(recurringExpenseRepositoryProvider),
    ref.watch(settingsRepositoryProvider),
  );
});

final importCsvMonekinProvider = Provider<ImportCsvMonekin>((ref) {
  return ImportCsvMonekin(
    ref.watch(expenseRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
  );
});

final importCsvDkbProvider = Provider<ImportCsvDkb>((ref) {
  return ImportCsvDkb(
    ref.watch(expenseRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
  );
});

// Legacy alias for backward compatibility
final importCsvProvider = Provider<ImportCsvMonekin>((ref) {
  return ref.watch(importCsvMonekinProvider);
});

// ---------------------------------------------------------------------------
// Reactive settings (streams)
// ---------------------------------------------------------------------------

final currencySymbolProvider = StreamProvider<String>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watchSetting('currency_symbol')
      .map((v) => v ?? '€');
});

final localeSettingProvider = StreamProvider<String>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watchSetting('locale')
      .map((v) => v ?? 'de');
});

final biometricsEnabledProvider = StreamProvider<bool>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watchSetting('biometrics_enabled')
      .map((v) => v == 'true');
});

final themeModeSettingProvider = StreamProvider<String>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watchSetting('theme_mode')
      .map((v) => v ?? 'system');
});

final onboardingCompletedProvider = StreamProvider<bool>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watchSetting('onboarding_completed')
      .map((v) => v == 'true');
});

final onboardingVersionProvider = StreamProvider<String>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watchSetting('onboarding_version')
      .map((v) => v ?? '0');
});

final needsOnboardingProvider = Provider<bool>((ref) {
  final onboardingCompleted =
      ref.watch(onboardingCompletedProvider).value ?? false;
  final onboardingVersion = ref.watch(onboardingVersionProvider).value ?? '0';
  return !onboardingCompleted || onboardingVersion != requiredOnboardingVersion;
});
