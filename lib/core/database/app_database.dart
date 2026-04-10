import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

part 'app_database.g.dart';

const _uuid = Uuid();

// ---------------------------------------------------------------------------
// Table definitions
// ---------------------------------------------------------------------------

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get parentId => integer().nullable()();
  TextColumn get iconName => text().withDefault(const Constant('category'))();
  IntColumn get colorValue =>
      integer().withDefault(const Constant(0xFF9E9E9E))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Expenses extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  IntColumn get amountCents => integer()();
  TextColumn get description => text().withLength(min: 1, max: 255)();
  IntColumn get categoryId => integer().references(Categories, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get notes => text().nullable()();
  TextColumn get recurringExpenseId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class RecurringExpenses extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  IntColumn get amountCents => integer()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get interval => text()(); // 'monthly' | 'yearly'
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get lastGeneratedDate => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

@DriftDatabase(tables: [Categories, Expenses, RecurringExpenses, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Named constructor that opens the default on-disk database.
  factory AppDatabase.defaults() => AppDatabase(_openConnection());

  /// In-memory constructor for tests.
  factory AppDatabase.memory() => AppDatabase(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  // Migration strategy — seed default categories on first run.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _seedDefaultCategories();
      await _seedDefaultSettings();
    },
    // Future migration example:
    // onUpgrade: (Migrator m, int from, int to) async { ... }
  );

  Future<void> _seedDefaultCategories() async {
    final defaults = <Map<String, Object?>>[
      {
        'name': 'Lebensmittel',
        'icon_name': 'shopping_cart',
        'color_value': 0xFF4CAF50,
        'sort_order': 0,
      },
      {
        'name': 'Haushalt',
        'icon_name': 'home',
        'color_value': 0xFF2196F3,
        'sort_order': 1,
      },
      {
        'name': 'Freizeit',
        'icon_name': 'sports_esports',
        'color_value': 0xFFFF9800,
        'sort_order': 2,
      },
      {
        'name': 'Essen',
        'icon_name': 'restaurant',
        'color_value': 0xFFE91E63,
        'sort_order': 3,
      },
      {
        'name': 'Transport',
        'icon_name': 'directions_car',
        'color_value': 0xFF9C27B0,
        'sort_order': 4,
      },
      {
        'name': 'Gesundheit',
        'icon_name': 'favorite',
        'color_value': 0xFFF44336,
        'sort_order': 5,
      },
      {
        'name': 'Arbeit',
        'icon_name': 'work',
        'color_value': 0xFF607D8B,
        'sort_order': 6,
      },
      {
        'name': 'Sonstiges',
        'icon_name': 'category',
        'color_value': 0xFF795548,
        'sort_order': 7,
      },
    ];

    for (final cat in defaults) {
      await into(categories).insert(
        CategoriesCompanion.insert(
          name: cat['name']! as String,
          iconName: Value(cat['icon_name']! as String),
          colorValue: Value(cat['color_value']! as int),
          sortOrder: Value(cat['sort_order']! as int),
        ),
      );
    }
  }

  Future<void> _seedDefaultSettings() async {
    final defaults = <Map<String, String>>[
      {'key': 'currency', 'value': 'EUR'},
      {'key': 'currency_symbol', 'value': '€'},
      {'key': 'locale', 'value': 'de'},
      {'key': 'biometrics_enabled', 'value': 'false'},
      {'key': 'theme_mode', 'value': 'system'},
    ];
    for (final s in defaults) {
      await into(
        appSettings,
      ).insert(AppSettingsCompanion.insert(key: s['key']!, value: s['value']!));
    }
  }

  // ---------------------------------------------------------------------------
  // Category queries
  // ---------------------------------------------------------------------------

  Future<List<Category>> getAllCategories() => select(categories).get();

  Stream<List<Category>> watchAllCategories() => select(categories).watch();

  Future<List<Category>> getParentCategories() =>
      (select(categories)..where((c) => c.parentId.isNull())).get();

  Future<List<Category>> getSubcategories(int parentId) =>
      (select(categories)..where((c) => c.parentId.equals(parentId))).get();

  Future<int> insertCategory(CategoriesCompanion entry) =>
      into(categories).insert(entry);

  Future<bool> updateCategory(CategoriesCompanion entry) =>
      update(categories).replace(entry);

  Future<int> deleteCategory(int id) =>
      (delete(categories)..where((c) => c.id.equals(id))).go();

  // ---------------------------------------------------------------------------
  // Expense queries
  // ---------------------------------------------------------------------------

  Future<List<Expense>> getAllExpenses() =>
      (select(expenses)..orderBy([(e) => OrderingTerm.desc(e.date)])).get();

  Stream<List<Expense>> watchAllExpenses() =>
      (select(expenses)..orderBy([(e) => OrderingTerm.desc(e.date)])).watch();

  Future<List<Expense>> getExpensesInRange(DateTime start, DateTime end) =>
      (select(expenses)
            ..where((e) => e.date.isBetweenValues(start, end))
            ..orderBy([(e) => OrderingTerm.desc(e.date)]))
          .get();

  Stream<List<Expense>> watchExpensesInRange(DateTime start, DateTime end) =>
      (select(expenses)
            ..where((e) => e.date.isBetweenValues(start, end))
            ..orderBy([(e) => OrderingTerm.desc(e.date)]))
          .watch();

  Future<List<Expense>> getExpensesByCategory(
    int categoryId,
    DateTime start,
    DateTime end,
  ) =>
      (select(expenses)
            ..where(
              (e) =>
                  e.categoryId.equals(categoryId) &
                  e.date.isBetweenValues(start, end),
            )
            ..orderBy([(e) => OrderingTerm.desc(e.date)]))
          .get();

  Future<int> insertExpense(ExpensesCompanion entry) =>
      into(expenses).insert(entry);

  Future<bool> updateExpense(ExpensesCompanion entry) =>
      update(expenses).replace(entry);

  Future<int> deleteExpense(String id) =>
      (delete(expenses)..where((e) => e.id.equals(id))).go();

  /// Autocomplete: group by description+category, ranked by frequency.
  Future<List<AutocompleteSuggestionRow>> getAutocompleteSuggestions(
    String query,
  ) async {
    final lowerQuery = '%${query.toLowerCase()}%';
    final results = await customSelect(
      'SELECT description, category_id, amount_cents, COUNT(*) as frequency '
      'FROM expenses '
      'WHERE LOWER(description) LIKE ? '
      'GROUP BY description, category_id '
      'ORDER BY frequency DESC '
      'LIMIT 10',
      variables: [Variable.withString(lowerQuery)],
      readsFrom: {expenses},
    ).get();

    return results.map((row) {
      return AutocompleteSuggestionRow(
        description: row.read<String>('description'),
        categoryId: row.read<int>('category_id'),
        amountCents: row.read<int>('amount_cents'),
        frequency: row.read<int>('frequency'),
      );
    }).toList();
  }

  /// Spending grouped by category for a date range.
  Future<List<CategorySpendingRow>> getSpendingByCategory(
    DateTime start,
    DateTime end,
  ) async {
    final results = await customSelect(
      'SELECT e.category_id, c.name AS category_name, c.parent_id, '
      'c.color_value, c.icon_name, SUM(e.amount_cents) AS total_cents, '
      'COUNT(*) AS tx_count '
      'FROM expenses e '
      'INNER JOIN categories c ON e.category_id = c.id '
      'WHERE e.date BETWEEN ? AND ? '
      'GROUP BY e.category_id '
      'ORDER BY total_cents ASC',
      variables: [Variable.withDateTime(start), Variable.withDateTime(end)],
      readsFrom: {expenses, categories},
    ).get();

    return results.map((row) {
      return CategorySpendingRow(
        categoryId: row.read<int>('category_id'),
        categoryName: row.read<String>('category_name'),
        parentId: row.readNullable<int>('parent_id'),
        colorValue: row.read<int>('color_value'),
        iconName: row.read<String>('icon_name'),
        totalCents: row.read<int>('total_cents'),
        transactionCount: row.read<int>('tx_count'),
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Recurring expense queries
  // ---------------------------------------------------------------------------

  Future<List<RecurringExpense>> getAllRecurringExpenses() =>
      select(recurringExpenses).get();

  Stream<List<RecurringExpense>> watchAllRecurringExpenses() =>
      select(recurringExpenses).watch();

  Future<List<RecurringExpense>> getActiveRecurringExpenses() =>
      (select(recurringExpenses)..where((r) => r.isActive.equals(true))).get();

  Future<int> insertRecurringExpense(RecurringExpensesCompanion entry) =>
      into(recurringExpenses).insert(entry);

  Future<bool> updateRecurringExpense(RecurringExpensesCompanion entry) =>
      update(recurringExpenses).replace(entry);

  Future<int> deleteRecurringExpense(String id) =>
      (delete(recurringExpenses)..where((r) => r.id.equals(id))).go();

  // ---------------------------------------------------------------------------
  // Settings queries
  // ---------------------------------------------------------------------------

  Future<String?> getSetting(String key) async {
    final row = await (select(
      appSettings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Stream<String?> watchSetting(String key) =>
      (select(appSettings)..where((s) => s.key.equals(key)))
          .watchSingleOrNull()
          .map((row) => row?.value);

  Future<void> setSetting(String key, String value) => into(
    appSettings,
  ).insertOnConflictUpdate(AppSettingsCompanion.insert(key: key, value: value));

  Future<List<AppSetting>> getAllSettings() => select(appSettings).get();

  // ---------------------------------------------------------------------------
  // Bulk / export helpers
  // ---------------------------------------------------------------------------

  Future<void> reassignExpensesToCategory(
    int fromCategoryId,
    int toCategoryId,
  ) => (update(expenses)..where((e) => e.categoryId.equals(fromCategoryId)))
      .write(ExpensesCompanion(categoryId: Value(toCategoryId)));

  Future<int> deleteExpensesByCategory(int categoryId) =>
      (delete(expenses)..where((e) => e.categoryId.equals(categoryId))).go();
}

// ---------------------------------------------------------------------------
// Helper row classes for custom queries
// ---------------------------------------------------------------------------

class AutocompleteSuggestionRow {
  final String description;
  final int categoryId;
  final int amountCents;
  final int frequency;

  AutocompleteSuggestionRow({
    required this.description,
    required this.categoryId,
    required this.amountCents,
    required this.frequency,
  });
}

class CategorySpendingRow {
  final int categoryId;
  final String categoryName;
  final int? parentId;
  final int colorValue;
  final String iconName;
  final int totalCents;
  final int transactionCount;

  CategorySpendingRow({
    required this.categoryId,
    required this.categoryName,
    required this.parentId,
    required this.colorValue,
    required this.iconName,
    required this.totalCents,
    required this.transactionCount,
  });
}

// ---------------------------------------------------------------------------
// Database opener
// ---------------------------------------------------------------------------

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    if (kIsWeb) {
      // On web, use an in-memory database (drift doesn't support
      // persistent web storage with NativeDatabase).
      // For production web, consider using drift's WasmDatabase.
      return NativeDatabase.memory();
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'spending_log.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
