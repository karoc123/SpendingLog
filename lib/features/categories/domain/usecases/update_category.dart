import '../entities/category_entity.dart';
import '../repositories/category_repository.dart';

class UpdateCategory {
  final CategoryRepository _repository;

  UpdateCategory(this._repository);

  Future<void> call(CategoryEntity category) {
    return _repository.updateCategory(category);
  }
}
