/// Pure Dart entity representing a category (no Flutter dependency).
class CategoryEntity {
  final int id;
  final String name;
  final int? parentId;
  final String iconName;
  final int colorValue;
  final bool isSavings;
  final int sortOrder;
  final DateTime createdAt;

  const CategoryEntity({
    required this.id,
    required this.name,
    this.parentId,
    this.iconName = 'category',
    this.colorValue = 0xFF9E9E9E,
    this.isSavings = false,
    this.sortOrder = 0,
    required this.createdAt,
  });

  CategoryEntity copyWith({
    int? id,
    String? name,
    int? Function()? parentId,
    String? iconName,
    int? colorValue,
    bool? isSavings,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId != null ? parentId() : this.parentId,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      isSavings: isSavings ?? this.isSavings,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
