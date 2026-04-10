import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spending_log/features/settings/domain/usecases/export_csv.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late MockExpenseRepository mockExpenseRepository;
  late MockCategoryRepository mockCategoryRepository;
  late ExportCsv useCase;

  setUp(() {
    mockExpenseRepository = MockExpenseRepository();
    mockCategoryRepository = MockCategoryRepository();
    useCase = ExportCsv(mockExpenseRepository, mockCategoryRepository);
  });

  test('should return CSV with header when no expenses exist', () async {
    final start = DateTime(2026, 1, 1);
    final end = DateTime(2026, 1, 31);
    when(
      () => mockExpenseRepository.getExpensesInRange(start, end),
    ).thenAnswer((_) async => []);
    when(
      () => mockCategoryRepository.getAllCategories(),
    ).thenAnswer((_) async => []);

    final result = await useCase(start, end);

    expect(result, contains('ID'));
    expect(result, contains('Amount'));
    expect(result, contains('Category'));
  });

  test('should include expense data in CSV output', () async {
    final start = DateTime(2026, 1, 1);
    final end = DateTime(2026, 1, 31);
    final expense = makeExpense(
      id: 'e1',
      amountCents: 1250,
      description: 'Coffee',
      categoryId: 1,
      date: DateTime(2026, 1, 15),
    );
    final category = makeCategory(id: 1, name: 'Food');

    when(
      () => mockExpenseRepository.getExpensesInRange(start, end),
    ).thenAnswer((_) async => [expense]);
    when(
      () => mockCategoryRepository.getAllCategories(),
    ).thenAnswer((_) async => [category]);

    final result = await useCase(start, end);

    expect(result, contains('e1'));
    expect(result, contains('12.50'));
    expect(result, contains('Coffee'));
    expect(result, contains('Food'));
  });

  test('should handle subcategories with parent category names', () async {
    final start = DateTime(2026, 1, 1);
    final end = DateTime(2026, 1, 31);
    final parent = makeCategory(id: 1, name: 'Food');
    final sub = makeCategory(id: 2, name: 'Coffee', parentId: 1);
    final expense = makeExpense(categoryId: 2);

    when(
      () => mockExpenseRepository.getExpensesInRange(start, end),
    ).thenAnswer((_) async => [expense]);
    when(
      () => mockCategoryRepository.getAllCategories(),
    ).thenAnswer((_) async => [parent, sub]);

    final result = await useCase(start, end);

    expect(result, contains('Food'));
    expect(result, contains('Coffee'));
  });

  test('should mark recurring expenses', () async {
    final start = DateTime(2026, 1, 1);
    final end = DateTime(2026, 1, 31);
    final expense = makeExpense(recurringExpenseId: 'r1', categoryId: 1);
    final category = makeCategory(id: 1, name: 'Bills');

    when(
      () => mockExpenseRepository.getExpensesInRange(start, end),
    ).thenAnswer((_) async => [expense]);
    when(
      () => mockCategoryRepository.getAllCategories(),
    ).thenAnswer((_) async => [category]);

    final result = await useCase(start, end);

    expect(result, contains('true'));
  });
}
