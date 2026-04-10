import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spending_log/features/categories/domain/usecases/delete_category.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late MockCategoryRepository mockRepository;
  late DeleteCategory useCase;

  setUp(() {
    mockRepository = MockCategoryRepository();
    useCase = DeleteCategory(mockRepository);
  });

  group('reassign action', () {
    test('should reassign expenses then delete category', () async {
      when(
        () => mockRepository.reassignExpenses(1, 2),
      ).thenAnswer((_) async {});
      when(() => mockRepository.deleteCategory(1)).thenAnswer((_) async {});

      await useCase(
        1,
        action: DeleteCategoryAction.reassign,
        reassignToCategoryId: 2,
      );

      verifyInOrder([
        () => mockRepository.reassignExpenses(1, 2),
        () => mockRepository.deleteCategory(1),
      ]);
    });
  });

  group('deleteExpenses action', () {
    test('should delete expenses then delete category', () async {
      when(
        () => mockRepository.deleteExpensesByCategory(1),
      ).thenAnswer((_) async {});
      when(() => mockRepository.deleteCategory(1)).thenAnswer((_) async {});

      await useCase(1, action: DeleteCategoryAction.deleteExpenses);

      verifyInOrder([
        () => mockRepository.deleteExpensesByCategory(1),
        () => mockRepository.deleteCategory(1),
      ]);
    });

    test('should not call reassignExpenses when deleting expenses', () async {
      when(
        () => mockRepository.deleteExpensesByCategory(1),
      ).thenAnswer((_) async {});
      when(() => mockRepository.deleteCategory(1)).thenAnswer((_) async {});

      await useCase(1, action: DeleteCategoryAction.deleteExpenses);

      verifyNever(() => mockRepository.reassignExpenses(any(), any()));
    });
  });
}
