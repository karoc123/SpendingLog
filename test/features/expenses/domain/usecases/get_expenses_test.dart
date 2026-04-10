import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spending_log/features/expenses/domain/usecases/get_expenses.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late MockExpenseRepository mockRepository;
  late GetExpenses useCase;

  setUp(() {
    mockRepository = MockExpenseRepository();
    useCase = GetExpenses(mockRepository);
  });

  group('call', () {
    test('should return all expenses from repository', () async {
      final expenses = [makeExpense(id: '1'), makeExpense(id: '2')];
      when(
        () => mockRepository.getAllExpenses(),
      ).thenAnswer((_) async => expenses);

      final result = await useCase();

      expect(result, expenses);
      verify(() => mockRepository.getAllExpenses()).called(1);
    });
  });

  group('watch', () {
    test('should return stream of all expenses', () {
      final expenses = [makeExpense()];
      when(
        () => mockRepository.watchAllExpenses(),
      ).thenAnswer((_) => Stream.value(expenses));

      expectLater(useCase.watch(), emits(expenses));
    });
  });

  group('inRange', () {
    test('should return expenses in the given date range', () async {
      final start = DateTime(2026, 1, 1);
      final end = DateTime(2026, 1, 31);
      final expenses = [makeExpense()];
      when(
        () => mockRepository.getExpensesInRange(start, end),
      ).thenAnswer((_) async => expenses);

      final result = await useCase.inRange(start, end);

      expect(result, expenses);
    });
  });

  group('watchInRange', () {
    test('should return stream of expenses in range', () {
      final start = DateTime(2026, 1, 1);
      final end = DateTime(2026, 1, 31);
      final expenses = [makeExpense()];
      when(
        () => mockRepository.watchExpensesInRange(start, end),
      ).thenAnswer((_) => Stream.value(expenses));

      expectLater(useCase.watchInRange(start, end), emits(expenses));
    });
  });

  group('byCategory', () {
    test('should return expenses filtered by category and range', () async {
      final start = DateTime(2026, 1, 1);
      final end = DateTime(2026, 1, 31);
      final expenses = [makeExpense(categoryId: 3)];
      when(
        () => mockRepository.getExpensesByCategory(3, start, end),
      ).thenAnswer((_) async => expenses);

      final result = await useCase.byCategory(3, start, end);

      expect(result, expenses);
    });
  });
}
