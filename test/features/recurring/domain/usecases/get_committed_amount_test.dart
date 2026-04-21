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

  test('should calculate daily committed amount for current month', () async {
    final rules = [
      makeRecurring(
        id: 'd1',
        amountCents: 100,
        interval: RecurringInterval.daily,
        startDate: DateTime(2026, 4, 1),
      ),
    ];
    when(
      () => mockRepository.getActiveRecurringExpenses(),
    ).thenAnswer((_) async => rules);

    final result = await useCase(now: DateTime(2026, 4, 15));

    expect(result, 3000); // 30 days in April * 100
  });

  test('should calculate weekly committed amount for current month', () async {
    final rules = [
      makeRecurring(
        id: 'w1',
        amountCents: 1000,
        interval: RecurringInterval.weekly,
        startDate: DateTime(2026, 4, 1),
      ),
    ];
    when(
      () => mockRepository.getActiveRecurringExpenses(),
    ).thenAnswer((_) async => rules);

    final result = await useCase(now: DateTime(2026, 4, 15));

    expect(result, 5000); // 1st, 8th, 15th, 22nd, 29th
  });

  test(
    'should include quarterly amount when quarter aligns in month',
    () async {
      final rules = [
        makeRecurring(
          id: 'q1',
          amountCents: 9000,
          interval: RecurringInterval.quarterly,
          startDate: DateTime(2026, 1, 5),
        ),
      ];
      when(
        () => mockRepository.getActiveRecurringExpenses(),
      ).thenAnswer((_) async => rules);

      final result = await useCase(now: DateTime(2026, 4, 15));

      expect(result, 9000); // next quarter occurrence in April
    },
  );

  test('should exclude occurrences at or after end date', () async {
    final rules = [
      makeRecurring(
        id: 'end1',
        amountCents: 100,
        interval: RecurringInterval.daily,
        startDate: DateTime(2026, 4, 1),
        endDate: DateTime(2026, 4, 11),
      ),
    ];
    when(
      () => mockRepository.getActiveRecurringExpenses(),
    ).thenAnswer((_) async => rules);

    final result = await useCase(now: DateTime(2026, 4, 15));

    expect(result, 1000); // 1st..10th, end date is exclusive
  });

  test('should return 0 when no active recurring expenses', () async {
    when(
      () => mockRepository.getActiveRecurringExpenses(),
    ).thenAnswer((_) async => []);

    final result = await useCase(now: DateTime(2026, 4, 15));

    expect(result, 0);
  });
}
