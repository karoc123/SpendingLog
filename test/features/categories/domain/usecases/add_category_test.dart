import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spending_log/features/categories/domain/usecases/add_category.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late MockCategoryRepository mockRepository;
  late AddCategory useCase;

  setUpAll(() {
    registerFallbackValue(makeCategory());
  });

  setUp(() {
    mockRepository = MockCategoryRepository();
    useCase = AddCategory(mockRepository);
  });

  test('should call repository.addCategory and return new id', () async {
    final category = makeCategory();
    when(
      () => mockRepository.addCategory(category),
    ).thenAnswer((_) async => 42);

    final result = await useCase(category);

    expect(result, 42);
    verify(() => mockRepository.addCategory(category)).called(1);
  });
}
