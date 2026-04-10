import '../entities/category_entity.dart';

abstract class CategoryRepository {
  Future<List<CategoryEntity>> getAllCategories();
  Stream<List<CategoryEntity>> watchAllCategories();
  Future<List<CategoryEntity>> getParentCategories();
  Future<List<CategoryEntity>> getSubcategories(int parentId);
  Future<int> addCategory(CategoryEntity category);
  Future<void> updateCategory(CategoryEntity category);
  Future<void> deleteCategory(int id);
  Future<void> reassignExpenses(int fromCategoryId, int toCategoryId);
  Future<void> deleteExpensesByCategory(int categoryId);
}
