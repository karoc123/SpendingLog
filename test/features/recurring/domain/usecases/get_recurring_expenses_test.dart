import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spending_log/features/recurring/domain/usecases/get_recurring_expenses.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late MockRecurringExpenseRepository mockRepository;
  late GetRecurringExpenses useCase;

  setUp(() {
    mockRepository = MockRecurringExpenseRepository();
    useCase = GetRecurringExpenses(mockRepository);
  });

  group('call', () {
    test('should return all recurring expenses', () async {
      final recurring = [makeRecurring(id: '1'), makeRecurring(id: '2')];
      when(
        () => mockRepository.getAllRecurringExpenses(),
      ).thenAnswer((_) async => recurring);

      final result = await useCase();

      expect(result, recurring);
    });
  });

  group('watch', () {
    test('should return stream of all recurring expenses', () {
      final recurring = [makeRecurring()];
      when(
        () => mockRepository.watchAllRecurringExpenses(),
      ).thenAnswer((_) => Stream.value(recurring));

      expectLater(useCase.watch(), emits(recurring));
    });
  });

  group('active', () {
    test('should return only active recurring expenses', () async {
      final active = [makeRecurring(isActive: true)];
      when(
        () => mockRepository.getActiveRecurringExpenses(),
      ).thenAnswer((_) async => active);

      final result = await useCase.active();

      expect(result, active);
    });
  });
}
