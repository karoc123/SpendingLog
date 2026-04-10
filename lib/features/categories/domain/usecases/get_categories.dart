import '../entities/category_entity.dart';
import '../repositories/category_repository.dart';

class GetCategories {
  final CategoryRepository _repository;

  GetCategories(this._repository);

  Future<List<CategoryEntity>> call() {
    return _repository.getAllCategories();
  }

  Stream<List<CategoryEntity>> watch() {
    return _repository.watchAllCategories();
  }

  Future<List<CategoryEntity>> parents() {
    return _repository.getParentCategories();
  }

  Future<List<CategoryEntity>> subcategories(int parentId) {
    return _repository.getSubcategories(parentId);
  }
}
