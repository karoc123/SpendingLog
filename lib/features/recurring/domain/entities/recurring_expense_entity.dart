/// Pure Dart entity for a recurring expense rule.
class RecurringExpenseEntity {
  final String id;
  final String name;
  final int amountCents;
  final int categoryId;
  final RecurringInterval interval;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? lastGeneratedDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RecurringExpenseEntity({
    required this.id,
    required this.name,
    required this.amountCents,
    required this.categoryId,
    required this.interval,
    required this.startDate,
    this.endDate,
    this.lastGeneratedDate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  RecurringExpenseEntity copyWith({
    String? id,
    String? name,
    int? amountCents,
    int? categoryId,
    RecurringInterval? interval,
    DateTime? startDate,
    DateTime? Function()? endDate,
    DateTime? Function()? lastGeneratedDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecurringExpenseEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      amountCents: amountCents ?? this.amountCents,
      categoryId: categoryId ?? this.categoryId,
      interval: interval ?? this.interval,
      startDate: startDate ?? this.startDate,
      endDate: endDate != null ? endDate() : this.endDate,
      lastGeneratedDate: lastGeneratedDate != null
          ? lastGeneratedDate()
          : this.lastGeneratedDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringExpenseEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum RecurringInterval {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly;

  static RecurringInterval fromString(String value) {
    switch (value) {
      case 'daily':
        return RecurringInterval.daily;
      case 'weekly':
        return RecurringInterval.weekly;
      case 'monthly':
        return RecurringInterval.monthly;
      case 'quarterly':
        return RecurringInterval.quarterly;
      case 'yearly':
        return RecurringInterval.yearly;
      default:
        throw ArgumentError('Unknown interval: $value');
    }
  }
}
