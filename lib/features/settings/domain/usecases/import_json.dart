import 'dart:convert';

import '../entities/json_backup.dart';
import '../repositories/backup_restore_repository.dart';

const _supportedIntervals = <String>{
  'daily',
  'weekly',
  'monthly',
  'quarterly',
  'yearly',
};

class ImportJsonResult {
  final int categoryCount;
  final int expenseCount;
  final int recurringCount;
  final int settingsCount;

  const ImportJsonResult({
    required this.categoryCount,
    required this.expenseCount,
    required this.recurringCount,
    required this.settingsCount,
  });
}

class ImportJson {
  final BackupRestoreRepository _backupRestoreRepository;

  ImportJson(this._backupRestoreRepository);

  Future<ImportJsonResult> call(String jsonContent) async {
    final trimmed = jsonContent.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('JSON content is empty.');
    }

    final decoded = _decodeRoot(trimmed);
    final version = _requiredInt(decoded, 'version', path: 'root.version');
    if (version != 1) {
      throw FormatException('Unsupported backup version: $version');
    }

    final categoryList = _requiredList(
      decoded,
      'categories',
      path: 'root.categories',
    );
    final expenseList = _requiredList(
      decoded,
      'expenses',
      path: 'root.expenses',
    );
    final recurringList = _requiredList(
      decoded,
      'recurring_expenses',
      path: 'root.recurring_expenses',
    );
    final settingsMap = _requiredObject(
      decoded,
      'settings',
      path: 'root.settings',
    );

    final categories = [
      for (var i = 0; i < categoryList.length; i++)
        _parseCategory(categoryList[i], index: i),
    ];
    final expenses = [
      for (var i = 0; i < expenseList.length; i++)
        _parseExpense(expenseList[i], index: i),
    ];
    final recurring = [
      for (var i = 0; i < recurringList.length; i++)
        _parseRecurring(recurringList[i], index: i),
    ];
    final settings = _parseSettings(settingsMap);

    await _backupRestoreRepository.restore(
      JsonBackupData(
        categories: categories,
        expenses: expenses,
        recurringExpenses: recurring,
        settings: settings,
      ),
    );

    return ImportJsonResult(
      categoryCount: categories.length,
      expenseCount: expenses.length,
      recurringCount: recurring.length,
      settingsCount: settings.length,
    );
  }

  Map<String, dynamic> _decodeRoot(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is! Map) {
        throw const FormatException('JSON root must be an object.');
      }
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Invalid JSON: $error');
    }
  }

  JsonBackupCategory _parseCategory(dynamic raw, {required int index}) {
    final path = 'root.categories[$index]';
    if (raw is! Map) {
      throw FormatException('$path must be an object.');
    }
    final map = raw.map((key, value) => MapEntry(key.toString(), value));

    return JsonBackupCategory(
      id: _requiredInt(map, 'id', path: '$path.id'),
      name: _requiredNonEmptyString(map, 'name', path: '$path.name'),
      parentId: _optionalInt(map, 'parent_id', path: '$path.parent_id'),
      iconName:
          _optionalString(map, 'icon_name', path: '$path.icon_name') ??
          'category',
      colorValue:
          _optionalInt(map, 'color_value', path: '$path.color_value') ??
          0xFF9E9E9E,
      isSavings:
          _optionalBool(map, 'is_savings', path: '$path.is_savings') ?? false,
      sortOrder: _optionalInt(map, 'sort_order', path: '$path.sort_order') ?? 0,
      createdAt: _requiredDateTime(map, 'created_at', path: '$path.created_at'),
    );
  }

  JsonBackupExpense _parseExpense(dynamic raw, {required int index}) {
    final path = 'root.expenses[$index]';
    if (raw is! Map) {
      throw FormatException('$path must be an object.');
    }
    final map = raw.map((key, value) => MapEntry(key.toString(), value));

    return JsonBackupExpense(
      id: _requiredNonEmptyString(map, 'id', path: '$path.id'),
      amountCents: _requiredInt(
        map,
        'amount_cents',
        path: '$path.amount_cents',
      ),
      description: _requiredNonEmptyString(
        map,
        'description',
        path: '$path.description',
      ),
      categoryId: _requiredInt(map, 'category_id', path: '$path.category_id'),
      date: _requiredDateTime(map, 'date', path: '$path.date'),
      notes: _optionalString(map, 'notes', path: '$path.notes'),
      recurringExpenseId: _optionalString(
        map,
        'recurring_expense_id',
        path: '$path.recurring_expense_id',
      ),
      createdAt: _requiredDateTime(map, 'created_at', path: '$path.created_at'),
      updatedAt: _requiredDateTime(map, 'updated_at', path: '$path.updated_at'),
    );
  }

  JsonBackupRecurringExpense _parseRecurring(
    dynamic raw, {
    required int index,
  }) {
    final path = 'root.recurring_expenses[$index]';
    if (raw is! Map) {
      throw FormatException('$path must be an object.');
    }
    final map = raw.map((key, value) => MapEntry(key.toString(), value));
    final interval = _requiredNonEmptyString(
      map,
      'interval',
      path: '$path.interval',
    );
    if (!_supportedIntervals.contains(interval)) {
      throw FormatException('$path.interval has unsupported value: $interval');
    }

    return JsonBackupRecurringExpense(
      id: _requiredNonEmptyString(map, 'id', path: '$path.id'),
      name: _requiredNonEmptyString(map, 'name', path: '$path.name'),
      amountCents: _requiredInt(
        map,
        'amount_cents',
        path: '$path.amount_cents',
      ),
      categoryId: _requiredInt(map, 'category_id', path: '$path.category_id'),
      interval: interval,
      startDate: _requiredDateTime(map, 'start_date', path: '$path.start_date'),
      endDate: _optionalDateTime(map, 'end_date', path: '$path.end_date'),
      lastGeneratedDate: _optionalDateTime(
        map,
        'last_generated_date',
        path: '$path.last_generated_date',
      ),
      isActive: _requiredBool(map, 'is_active', path: '$path.is_active'),
      createdAt: _requiredDateTime(map, 'created_at', path: '$path.created_at'),
      updatedAt: _requiredDateTime(map, 'updated_at', path: '$path.updated_at'),
    );
  }

  Map<String, String> _parseSettings(Map<String, dynamic> raw) {
    final parsed = <String, String>{};
    for (final entry in raw.entries) {
      final key = entry.key.trim();
      if (key.isEmpty) {
        throw const FormatException('root.settings contains an empty key.');
      }
      final value = entry.value;
      if (value is String) {
        parsed[key] = value;
      } else if (value is num || value is bool) {
        parsed[key] = value.toString();
      } else {
        throw FormatException(
          'root.settings.$key must be a string/number/bool, got ${value.runtimeType}.',
        );
      }
    }
    return parsed;
  }

  List<dynamic> _requiredList(
    Map<String, dynamic> map,
    String key, {
    required String path,
  }) {
    final value = map[key];
    if (value is! List) {
      throw FormatException('$path must be an array.');
    }
    return value;
  }

  Map<String, dynamic> _requiredObject(
    Map<String, dynamic> map,
    String key, {
    required String path,
  }) {
    final value = map[key];
    if (value is! Map) {
      throw FormatException('$path must be an object.');
    }
    return value.map((k, v) => MapEntry(k.toString(), v));
  }

  int _requiredInt(
    Map<String, dynamic> map,
    String key, {
    required String path,
  }) {
    final value = map[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    throw FormatException('$path must be an integer.');
  }

  int? _optionalInt(
    Map<String, dynamic> map,
    String key, {
    required String path,
  }) {
    final value = map[key];
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    throw FormatException('$path must be an integer or null.');
  }

  String _requiredNonEmptyString(
    Map<String, dynamic> map,
    String key, {
    required String path,
  }) {
    final value = map[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$path must be a non-empty string.');
    }
    return value.trim();
  }

  String? _optionalString(
    Map<String, dynamic> map,
    String key, {
    required String path,
  }) {
    final value = map[key];
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    throw FormatException('$path must be a string or null.');
  }

  bool _requiredBool(
    Map<String, dynamic> map,
    String key, {
    required String path,
  }) {
    final value = map[key];
    if (value is bool) {
      return value;
    }
    throw FormatException('$path must be a boolean.');
  }

  bool? _optionalBool(
    Map<String, dynamic> map,
    String key, {
    required String path,
  }) {
    final value = map[key];
    if (value == null) {
      return null;
    }
    if (value is bool) {
      return value;
    }
    throw FormatException('$path must be a boolean or null.');
  }

  DateTime _requiredDateTime(
    Map<String, dynamic> map,
    String key, {
    required String path,
  }) {
    final value = map[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$path must be an ISO date string.');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('$path has invalid date value: $value');
    }
    return parsed;
  }

  DateTime? _optionalDateTime(
    Map<String, dynamic> map,
    String key, {
    required String path,
  }) {
    final value = map[key];
    if (value == null) {
      return null;
    }
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$path must be an ISO date string or null.');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('$path has invalid date value: $value');
    }
    return parsed;
  }
}
