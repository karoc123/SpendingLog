import '../repositories/category_repository.dart';

enum DeleteCategoryAction { reassign, deleteExpenses }

class DeleteCategory {
  final CategoryRepository _repository;

  DeleteCategory(this._repository);

  /// Deletes a category. If [action] is [DeleteCategoryAction.reassign],
  /// moves all expenses to [reassignToCategoryId]. If
  /// [DeleteCategoryAction.deleteExpenses], deletes those expenses.
  Future<void> call(
    int categoryId, {
    required DeleteCategoryAction action,
    int? reassignToCategoryId,
  }) async {
    if (action == DeleteCategoryAction.reassign) {
      assert(reassignToCategoryId != null);
      await _repository.reassignExpenses(categoryId, reassignToCategoryId!);
    } else {
      await _repository.deleteExpensesByCategory(categoryId);
    }
    await _repository.deleteCategory(categoryId);
  }
}
