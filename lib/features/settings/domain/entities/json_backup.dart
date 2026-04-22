class JsonBackupData {
  final List<JsonBackupCategory> categories;
  final List<JsonBackupExpense> expenses;
  final List<JsonBackupRecurringExpense> recurringExpenses;
  final Map<String, String> settings;

  const JsonBackupData({
    required this.categories,
    required this.expenses,
    required this.recurringExpenses,
    required this.settings,
  });
}

class JsonBackupCategory {
  final int id;
  final String name;
  final int? parentId;
  final String iconName;
  final int colorValue;
  final bool isSavings;
  final int sortOrder;
  final DateTime createdAt;

  const JsonBackupCategory({
    required this.id,
    required this.name,
    this.parentId,
    required this.iconName,
    required this.colorValue,
    required this.isSavings,
    required this.sortOrder,
    required this.createdAt,
  });
}

class JsonBackupExpense {
  final String id;
  final int amountCents;
  final String description;
  final int categoryId;
  final DateTime date;
  final String? notes;
  final String? recurringExpenseId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JsonBackupExpense({
    required this.id,
    required this.amountCents,
    required this.description,
    required this.categoryId,
    required this.date,
    this.notes,
    this.recurringExpenseId,
    required this.createdAt,
    required this.updatedAt,
  });
}

class JsonBackupRecurringExpense {
  final String id;
  final String name;
  final int amountCents;
  final int categoryId;
  final String interval;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? lastGeneratedDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JsonBackupRecurringExpense({
    required this.id,
    required this.name,
    required this.amountCents,
    required this.categoryId,
    required this.interval,
    required this.startDate,
    this.endDate,
    this.lastGeneratedDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
}
