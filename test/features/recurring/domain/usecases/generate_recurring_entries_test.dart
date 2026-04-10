import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spending_log/features/expenses/domain/entities/expense_entity.dart';
import 'package:spending_log/features/recurring/domain/entities/recurring_expense_entity.dart';
import 'package:spending_log/features/recurring/domain/usecases/generate_recurring_entries.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late MockRecurringExpenseRepository mockRecurringRepository;
  late MockExpenseRepository mockExpenseRepository;
  late GenerateRecurringEntries useCase;

  setUpAll(() {
    registerFallbackValue(makeExpense());
    registerFallbackValue(makeRecurring());
  });

  setUp(() {
    mockRecurringRepository = MockRecurringExpenseRepository();
    mockExpenseRepository = MockExpenseRepository();
    useCase = GenerateRecurringEntries(
      mockRecurringRepository,
      mockExpenseRepository,
    );
  });

  test('should return 0 when there are no active recurring expenses', () async {
    when(
      () => mockRecurringRepository.getActiveRecurringExpenses(),
    ).thenAnswer((_) async => []);

    final result = await useCase(now: DateTime(2026, 4, 15));

    expect(result, 0);
    verifyNever(() => mockExpenseRepository.addExpense(any()));
  });

  test('should generate monthly entries from start date to now', () async {
    final rule = makeRecurring(
      id: 'r1',
      interval: RecurringInterval.monthly,
      startDate: DateTime(2026, 1, 15),
      lastGeneratedDate: null,
    );
    when(
      () => mockRecurringRepository.getActiveRecurringExpenses(),
    ).thenAnswer((_) async => [rule]);
    when(
      () => mockExpenseRepository.addExpense(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockRecurringRepository.updateRecurringExpense(any()),
    ).thenAnswer((_) async {});

    final result = await useCase(now: DateTime(2026, 4, 15));

    // Should generate: Jan 15, Feb 15, Mar 15, Apr 15 = 4 entries
    expect(result, 4);
    verify(() => mockExpenseRepository.addExpense(any())).called(4);
    verify(
      () => mockRecurringRepository.updateRecurringExpense(any()),
    ).called(1);
  });

  test('should generate entries only after last generated date', () async {
    final rule = makeRecurring(
      id: 'r1',
      interval: RecurringInterval.monthly,
      startDate: DateTime(2026, 1, 15),
      lastGeneratedDate: DateTime(2026, 3, 15),
    );
    when(
      () => mockRecurringRepository.getActiveRecurringExpenses(),
    ).thenAnswer((_) async => [rule]);
    when(
      () => mockExpenseRepository.addExpense(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockRecurringRepository.updateRecurringExpense(any()),
    ).thenAnswer((_) async {});

    final result = await useCase(now: DateTime(2026, 4, 15));

    // Should generate: Apr 15 = 1 entry
    expect(result, 1);
  });

  test('should generate yearly entries', () async {
    final rule = makeRecurring(
      id: 'r1',
      interval: RecurringInterval.yearly,
      startDate: DateTime(2024, 6, 1),
      lastGeneratedDate: null,
    );
    when(
      () => mockRecurringRepository.getActiveRecurringExpenses(),
    ).thenAnswer((_) async => [rule]);
    when(
      () => mockExpenseRepository.addExpense(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockRecurringRepository.updateRecurringExpense(any()),
    ).thenAnswer((_) async {});

    final result = await useCase(now: DateTime(2026, 7, 1));

    // Should generate: 2024-06-01, 2025-06-01, 2026-06-01 = 3 entries
    expect(result, 3);
  });

  test('should not generate entries when not yet due', () async {
    final rule = makeRecurring(
      id: 'r1',
      interval: RecurringInterval.monthly,
      startDate: DateTime(2026, 5, 1),
      lastGeneratedDate: null,
    );
    when(
      () => mockRecurringRepository.getActiveRecurringExpenses(),
    ).thenAnswer((_) async => [rule]);

    final result = await useCase(now: DateTime(2026, 4, 15));

    expect(result, 0);
    verifyNever(() => mockExpenseRepository.addExpense(any()));
  });

  test('should update lastGeneratedDate to last generated date', () async {
    final rule = makeRecurring(
      id: 'r1',
      interval: RecurringInterval.monthly,
      startDate: DateTime(2026, 3, 10),
      lastGeneratedDate: null,
    );
    when(
      () => mockRecurringRepository.getActiveRecurringExpenses(),
    ).thenAnswer((_) async => [rule]);
    when(
      () => mockExpenseRepository.addExpense(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockRecurringRepository.updateRecurringExpense(any()),
    ).thenAnswer((_) async {});

    await useCase(now: DateTime(2026, 4, 15));

    final captured =
        verify(
              () =>
                  mockRecurringRepository.updateRecurringExpense(captureAny()),
            ).captured.single
            as RecurringExpenseEntity;

    expect(captured.lastGeneratedDate, DateTime(2026, 4, 10));
  });

  test('should set recurringExpenseId on generated expenses', () async {
    final rule = makeRecurring(
      id: 'r1',
      interval: RecurringInterval.monthly,
      startDate: DateTime(2026, 4, 1),
      lastGeneratedDate: null,
    );
    when(
      () => mockRecurringRepository.getActiveRecurringExpenses(),
    ).thenAnswer((_) async => [rule]);
    when(
      () => mockExpenseRepository.addExpense(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockRecurringRepository.updateRecurringExpense(any()),
    ).thenAnswer((_) async {});

    await useCase(now: DateTime(2026, 4, 1));

    final captured =
        verify(
              () => mockExpenseRepository.addExpense(captureAny()),
            ).captured.single
            as ExpenseEntity;

    expect(captured.recurringExpenseId, 'r1');
    expect(captured.amountCents, 1599);
    expect(captured.description, 'Netflix');
  });
}
