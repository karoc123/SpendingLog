/// Pure Dart entity for a recurring expense rule.
class RecurringExpenseEntity {
  final String id;
  final String name;
  final int amountCents;
  final int categoryId;
  final RecurringInterval interval;
  final DateTime startDate;
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
  monthly,
  yearly;

  static RecurringInterval fromString(String value) {
    switch (value) {
      case 'monthly':
        return RecurringInterval.monthly;
      case 'yearly':
        return RecurringInterval.yearly;
      default:
        throw ArgumentError('Unknown interval: $value');
    }
  }
}
