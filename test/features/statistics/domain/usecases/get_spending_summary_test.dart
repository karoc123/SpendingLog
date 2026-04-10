import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spending_log/features/statistics/domain/usecases/get_spending_summary.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late MockExpenseRepository mockRepository;
  late GetSpendingSummary useCase;

  setUp(() {
    mockRepository = MockExpenseRepository();
    useCase = GetSpendingSummary(mockRepository);
  });

  final start = DateTime(2026, 1, 1);
  final end = DateTime(2026, 1, 31);

  test('should return zero summary when no expenses', () async {
    when(
      () => mockRepository.getExpensesInRange(start, end),
    ).thenAnswer((_) async => []);

    final result = await useCase(start, end);

    expect(result.totalCents, 0);
    expect(result.transactionCount, 0);
    expect(result.topCategoryName, '-');
  });

  test('should calculate total and count correctly', () async {
    final expenses = [
      makeExpense(id: '1', amountCents: 500, categoryId: 1),
      makeExpense(id: '2', amountCents: 1000, categoryId: 1),
      makeExpense(id: '3', amountCents: 300, categoryId: 2),
    ];
    when(
      () => mockRepository.getExpensesInRange(start, end),
    ).thenAnswer((_) async => expenses);

    final result = await useCase(start, end);

    expect(result.totalCents, 1800);
    expect(result.transactionCount, 3);
  });

  test('should identify top spending category', () async {
    final expenses = [
      makeExpense(id: '1', amountCents: 500, categoryId: 1),
      makeExpense(id: '2', amountCents: 1000, categoryId: 2),
      makeExpense(id: '3', amountCents: 1500, categoryId: 2),
    ];
    when(
      () => mockRepository.getExpensesInRange(start, end),
    ).thenAnswer((_) async => expenses);

    final result = await useCase(start, end);

    // topCategoryName stores the category ID as string
    expect(result.topCategoryName, '2');
  });
}
