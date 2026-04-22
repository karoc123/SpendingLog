import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final AppDatabase _db;

  CategoryRepositoryImpl(this._db);

  CategoryEntity _toEntity(Category row) => CategoryEntity(
    id: row.id,
    name: row.name,
    parentId: row.parentId,
    iconName: row.iconName,
    colorValue: row.colorValue,
    isSavings: row.isSavings,
    sortOrder: row.sortOrder,
    createdAt: row.createdAt,
  );

  CategoriesCompanion _toCompanion(CategoryEntity c) => CategoriesCompanion(
    id: c.id == 0 ? const Value.absent() : Value(c.id),
    name: Value(c.name),
    parentId: Value(c.parentId),
    iconName: Value(c.iconName),
    colorValue: Value(c.colorValue),
    isSavings: Value(c.isSavings),
    sortOrder: Value(c.sortOrder),
    createdAt: Value(c.createdAt),
  );

  @override
  Future<List<CategoryEntity>> getAllCategories() async =>
      (await _db.getAllCategories()).map(_toEntity).toList();

  @override
  Stream<List<CategoryEntity>> watchAllCategories() =>
      _db.watchAllCategories().map((rows) => rows.map(_toEntity).toList());

  @override
  Future<List<CategoryEntity>> getParentCategories() async =>
      (await _db.getParentCategories()).map(_toEntity).toList();

  @override
  Future<List<CategoryEntity>> getSubcategories(int parentId) async =>
      (await _db.getSubcategories(parentId)).map(_toEntity).toList();

  @override
  Future<int> addCategory(CategoryEntity category) {
    return _db.insertCategory(_toCompanion(category));
  }

  @override
  Future<void> updateCategory(CategoryEntity category) async {
    await _db.updateCategory(_toCompanion(category));
  }

  @override
  Future<void> deleteCategory(int id) async {
    await _db.deleteCategory(id);
  }

  @override
  Future<void> reassignExpenses(int fromCategoryId, int toCategoryId) {
    return _db.reassignExpensesToCategory(fromCategoryId, toCategoryId);
  }

  @override
  Future<void> deleteExpensesByCategory(int categoryId) async {
    await _db.deleteExpensesByCategory(categoryId);
  }
}
