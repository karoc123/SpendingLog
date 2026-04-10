import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spending_log/features/categories/domain/usecases/update_category.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late MockCategoryRepository mockRepository;
  late UpdateCategory useCase;

  setUp(() {
    mockRepository = MockCategoryRepository();
    useCase = UpdateCategory(mockRepository);
  });

  test('should call repository.updateCategory', () async {
    final category = makeCategory();
    when(
      () => mockRepository.updateCategory(category),
    ).thenAnswer((_) async {});

    await useCase(category);

    verify(() => mockRepository.updateCategory(category)).called(1);
  });
}
