import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spending_log/features/statistics/domain/usecases/get_spending_by_category.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late MockExpenseRepository mockExpenseRepository;
  late MockCategoryRepository mockCategoryRepository;
  late GetSpendingByCategory useCase;

  setUp(() {
    mockExpenseRepository = MockExpenseRepository();
    mockCategoryRepository = MockCategoryRepository();
    useCase = GetSpendingByCategory(
      mockExpenseRepository,
      mockCategoryRepository,
    );
  });

  final start = DateTime(2026, 1, 1);
  final end = DateTime(2026, 1, 31);

  group('call', () {
    test('should return empty list when no expenses', () async {
      when(
        () => mockExpenseRepository.getExpensesInRange(start, end),
      ).thenAnswer((_) async => []);
      when(
        () => mockCategoryRepository.getAllCategories(),
      ).thenAnswer((_) async => []);

      final result = await useCase(start, end);

      expect(result, isEmpty);
    });

    test('should aggregate spending by parent category', () async {
      final parentCat = makeCategory(
        id: 1,
        name: 'Food',
        colorValue: 0xFF4CAF50,
      );
      final subCat = makeCategory(id: 2, name: 'Coffee', parentId: 1);
      final expenses = [
        makeExpense(id: '1', amountCents: 500, categoryId: 1),
        makeExpense(id: '2', amountCents: 300, categoryId: 2), // rolls up
      ];

      when(
        () => mockExpenseRepository.getExpensesInRange(start, end),
      ).thenAnswer((_) async => expenses);
      when(
        () => mockCategoryRepository.getAllCategories(),
      ).thenAnswer((_) async => [parentCat, subCat]);

      final result = await useCase(start, end);

      expect(result, hasLength(1));
      expect(result.first.categoryId, 1);
      expect(result.first.totalCents, 800);
      expect(result.first.transactionCount, 2);
    });

    test('should sort by totalCents ascending', () async {
      final cat1 = makeCategory(id: 1, name: 'Food');
      final cat2 = makeCategory(id: 2, name: 'Transport');
      final expenses = [
        makeExpense(id: '1', amountCents: 1000, categoryId: 2),
        makeExpense(id: '2', amountCents: 500, categoryId: 1),
      ];

      when(
        () => mockExpenseRepository.getExpensesInRange(start, end),
      ).thenAnswer((_) async => expenses);
      when(
        () => mockCategoryRepository.getAllCategories(),
      ).thenAnswer((_) async => [cat1, cat2]);

      final result = await useCase(start, end);

      expect(result.first.categoryName, 'Food');
      expect(result.last.categoryName, 'Transport');
    });
  });

  group('subcategoryBreakdown', () {
    test('should return spending per subcategory', () async {
      final parent = makeCategory(id: 1, name: 'Food');
      final sub1 = makeCategory(id: 2, name: 'Coffee', parentId: 1);
      final sub2 = makeCategory(id: 3, name: 'Restaurant', parentId: 1);
      final expenses = [
        makeExpense(id: '1', amountCents: 350, categoryId: 2),
        makeExpense(id: '2', amountCents: 2000, categoryId: 3),
        makeExpense(id: '3', amountCents: 500, categoryId: 1), // direct parent
        makeExpense(
          id: '4',
          amountCents: 800,
          categoryId: 99,
        ), // other category
      ];

      when(
        () => mockExpenseRepository.getExpensesInRange(start, end),
      ).thenAnswer((_) async => expenses);
      when(
        () => mockCategoryRepository.getAllCategories(),
      ).thenAnswer((_) async => [parent, sub1, sub2]);

      final result = await useCase.subcategoryBreakdown(1, start, end);

      expect(result, hasLength(3));
      final ids = result.map((r) => r.categoryId).toSet();
      expect(ids, containsAll([1, 2, 3]));
    });

    test('should not include expenses from unrelated categories', () async {
      final parent = makeCategory(id: 1, name: 'Food');
      final other = makeCategory(id: 5, name: 'Transport');
      final expenses = [makeExpense(id: '1', amountCents: 500, categoryId: 5)];

      when(
        () => mockExpenseRepository.getExpensesInRange(start, end),
      ).thenAnswer((_) async => expenses);
      when(
        () => mockCategoryRepository.getAllCategories(),
      ).thenAnswer((_) async => [parent, other]);

      final result = await useCase.subcategoryBreakdown(1, start, end);

      expect(result, isEmpty);
    });
  });
}
