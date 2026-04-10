import '../entities/category_entity.dart';
import '../repositories/category_repository.dart';

class AddCategory {
  final CategoryRepository _repository;

  AddCategory(this._repository);

  Future<int> call(CategoryEntity category) {
    return _repository.addCategory(category);
  }
}
