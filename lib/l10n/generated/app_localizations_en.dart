// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SpendingLog';

  @override
  String get amount => 'Amount';

  @override
  String get date => 'Date';

  @override
  String get description => 'Description';

  @override
  String get notes => 'Notes (optional)';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get confirm => 'Confirm';

  @override
  String get edit => 'Edit';

  @override
  String get name => 'Name';

  @override
  String get enterValidAmount => 'Please enter a valid amount';

  @override
  String get enterDescription => 'Please enter a description';

  @override
  String get selectCategory => 'Please select a category';

  @override
  String get expenseSaved => 'Expense saved';

  @override
  String get noExpenses => 'No expenses yet';

  @override
  String get editExpense => 'Edit expense';

  @override
  String get committedThisMonth => 'Fixed costs this month';

  @override
  String get statistics => 'Statistics';

  @override
  String get monthly => 'Month';

  @override
  String get yearly => 'Year';

  @override
  String get totalSpent => 'Total';

  @override
  String get transactions => 'Transactions';

  @override
  String get topCategory => 'Top category';

  @override
  String get recurringExpenses => 'Recurring expenses';

  @override
  String get noRecurringExpenses => 'No recurring expenses';

  @override
  String get addRecurring => 'Add recurring expense';

  @override
  String get editRecurring => 'Edit recurring expense';

  @override
  String get deleteRecurring => 'Delete?';

  @override
  String get deleteRecurringConfirm => 'Really delete this recurring expense?';

  @override
  String get startDate => 'Start date';

  @override
  String get nextTransaction => 'Next transaction';

  @override
  String get active => 'Active';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeMode => 'Theme';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get system => 'System';

  @override
  String get language => 'Language';

  @override
  String get currency => 'Currency';

  @override
  String get security => 'Security';

  @override
  String get biometricAuth => 'Biometric authentication';

  @override
  String get biometricsUnavailableWeb => 'Not available on Web';

  @override
  String get biometricsNotAvailable => 'Biometric authentication not available';

  @override
  String get biometricReason => 'Please authenticate';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get data => 'Data';

  @override
  String get manageCategories => 'Manage categories';

  @override
  String get exportImport => 'Export / Import';

  @override
  String get about => 'About';

  @override
  String get csvExport => 'CSV Export';

  @override
  String get jsonExport => 'JSON Backup';

  @override
  String get jsonExportDescription =>
      'Full backup of all data (expenses, categories, recurring expenses, settings).';

  @override
  String get csvImport => 'CSV Import';

  @override
  String get csvImportDescription => 'Import expenses from a CSV file.';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get exportJson => 'Export JSON';

  @override
  String get importCsv => 'Import CSV';

  @override
  String get exportSuccess => 'Export successful';

  @override
  String get importSuccess => 'Import successful';

  @override
  String get entries => 'entries';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get deleteCategory => 'Delete category';

  @override
  String get deleteCategoryPrompt =>
      'What should happen with associated expenses?';

  @override
  String get deleteWithExpenses => 'Delete with expenses';

  @override
  String get reassignExpenses => 'Reassign expenses';

  @override
  String get reassignTo => 'Reassign to';

  @override
  String get addCategory => 'Add category';

  @override
  String get editCategory => 'Edit category';

  @override
  String get addSubcategory => 'Add subcategory';

  @override
  String get icon => 'Icon';

  @override
  String get color => 'Color';

  @override
  String get searchTransactions => 'Search…';

  @override
  String get filterCategory => 'Category';

  @override
  String get allCategories => 'All';

  @override
  String get clearFilter => 'Clear filter';

  @override
  String get fixedShort => 'Fix';

  @override
  String get flexShort => 'Flex';

  @override
  String get recurringGenerated => 'Generated from recurring rule';

  @override
  String get setupTitle => 'Setup';

  @override
  String get setupDescription =>
      'Please choose language, theme, and default categories.';

  @override
  String get addDefaultCategories => 'Add default categories';

  @override
  String get addDefaultCategoriesDescription =>
      'Imports categories with matching subcategories.';

  @override
  String get saving => 'Saving...';

  @override
  String get continueLabel => 'Continue';

  @override
  String get dailyTrend => 'Daily trend';

  @override
  String get monthlyTrend => 'Monthly trend';

  @override
  String get noChartData => 'No data';

  @override
  String get category => 'Category';

  @override
  String get includeAmountLabel => 'incl. amount';

  @override
  String get generateExpenseNow => 'Generate now';

  @override
  String get expenseGeneratedNow => 'Expense generated now';

  @override
  String get startDateValidationFuture =>
      'Start date must be today or in the future';

  @override
  String get exportFailed => 'Export failed';

  @override
  String get importFailed => 'Import failed';

  @override
  String get importRoutineTitle => 'Choose import routine';

  @override
  String get importRoutinePrompt => 'Which CSV format should be imported?';

  @override
  String get errorCopiedClipboard => 'Error copied to clipboard';
}
