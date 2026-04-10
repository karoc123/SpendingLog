import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spending_log/features/recurring/domain/entities/recurring_expense_entity.dart';
import 'package:spending_log/features/recurring/domain/usecases/get_committed_amount.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late MockRecurringExpenseRepository mockRepository;
  late GetCommittedAmount useCase;

  setUp(() {
    mockRepository = MockRecurringExpenseRepository();
    useCase = GetCommittedAmount(mockRepository);
  });

  test('should sum all monthly recurring amounts', () async {
    final rules = [
      makeRecurring(
        id: '1',
        amountCents: 1000,
        interval: RecurringInterval.monthly,
      ),
      makeRecurring(
        id: '2',
        amountCents: 500,
        interval: RecurringInterval.monthly,
      ),
    ];
    when(
      () => mockRepository.getActiveRecurringExpenses(),
    ).thenAnswer((_) async => rules);

    final result = await useCase(now: DateTime(2026, 4, 15));

    expect(result, 1500);
  });

  test('should include yearly amounts only in matching month', () async {
    final rules = [
      makeRecurring(
        id: '1',
        amountCents: 12000,
        interval: RecurringInterval.yearly,
        startDate: DateTime(2025, 4, 1), // April
      ),
    ];
    when(
      () => mockRepository.getActiveRecurringExpenses(),
    ).thenAnswer((_) async => rules);

    final result = await useCase(now: DateTime(2026, 4, 15));

    expect(result, 12000);
  });

  test('should exclude yearly amounts in non-matching month', () async {
    final rules = [
      makeRecurring(
        id: '1',
        amountCents: 12000,
        interval: RecurringInterval.yearly,
        startDate: DateTime(2025, 6, 1), // June
      ),
    ];
    when(
      () => mockRepository.getActiveRecurringExpenses(),
    ).thenAnswer((_) async => rules);

    final result = await useCase(now: DateTime(2026, 4, 15));

    expect(result, 0);
  });

  test('should combine monthly and matching yearly', () async {
    final rules = [
      makeRecurring(
        id: '1',
        amountCents: 1000,
        interval: RecurringInterval.monthly,
      ),
      makeRecurring(
        id: '2',
        amountCents: 5000,
        interval: RecurringInterval.yearly,
        startDate: DateTime(2025, 4, 1),
      ),
    ];
    when(
      () => mockRepository.getActiveRecurringExpenses(),
    ).thenAnswer((_) async => rules);

    final result = await useCase(now: DateTime(2026, 4, 15));

    expect(result, 6000);
  });

  test('should return 0 when no active recurring expenses', () async {
    when(
      () => mockRepository.getActiveRecurringExpenses(),
    ).thenAnswer((_) async => []);

    final result = await useCase(now: DateTime(2026, 4, 15));

    expect(result, 0);
  });
}
