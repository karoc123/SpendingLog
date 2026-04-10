import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spending_log/features/categories/domain/usecases/get_categories.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late MockCategoryRepository mockRepository;
  late GetCategories useCase;

  setUp(() {
    mockRepository = MockCategoryRepository();
    useCase = GetCategories(mockRepository);
  });

  group('call', () {
    test('should return all categories from repository', () async {
      final categories = [makeCategory(id: 1), makeCategory(id: 2)];
      when(
        () => mockRepository.getAllCategories(),
      ).thenAnswer((_) async => categories);

      final result = await useCase();

      expect(result, categories);
    });
  });

  group('watch', () {
    test('should return stream of all categories', () {
      final categories = [makeCategory()];
      when(
        () => mockRepository.watchAllCategories(),
      ).thenAnswer((_) => Stream.value(categories));

      expectLater(useCase.watch(), emits(categories));
    });
  });

  group('parents', () {
    test('should return only parent categories', () async {
      final parents = [makeCategory(id: 1)];
      when(
        () => mockRepository.getParentCategories(),
      ).thenAnswer((_) async => parents);

      final result = await useCase.parents();

      expect(result, parents);
    });
  });

  group('subcategories', () {
    test('should return subcategories for given parent', () async {
      final subs = [makeCategory(id: 10, parentId: 1)];
      when(
        () => mockRepository.getSubcategories(1),
      ).thenAnswer((_) async => subs);

      final result = await useCase.subcategories(1);

      expect(result, subs);
    });
  });
}
