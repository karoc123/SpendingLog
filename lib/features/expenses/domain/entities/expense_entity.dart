/// Pure Dart entity representing an expense.
class ExpenseEntity {
  final String id;
  final int amountCents;
  final String description;
  final int categoryId;
  final DateTime date;
  final String? notes;
  final String? recurringExpenseId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExpenseEntity({
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

  bool get isRecurring => recurringExpenseId != null;

  ExpenseEntity copyWith({
    String? id,
    int? amountCents,
    String? description,
    int? categoryId,
    DateTime? date,
    String? Function()? notes,
    String? Function()? recurringExpenseId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseEntity(
      id: id ?? this.id,
      amountCents: amountCents ?? this.amountCents,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      notes: notes != null ? notes() : this.notes,
      recurringExpenseId: recurringExpenseId != null
          ? recurringExpenseId()
          : this.recurringExpenseId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
