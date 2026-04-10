import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spending_log/features/recurring/domain/usecases/add_recurring_expense.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late MockRecurringExpenseRepository mockRepository;
  late AddRecurringExpense useCase;

  setUp(() {
    mockRepository = MockRecurringExpenseRepository();
    useCase = AddRecurringExpense(mockRepository);
  });

  test('should call repository.addRecurringExpense', () async {
    final recurring = makeRecurring();
    when(
      () => mockRepository.addRecurringExpense(recurring),
    ).thenAnswer((_) async {});

    await useCase(recurring);

    verify(() => mockRepository.addRecurringExpense(recurring)).called(1);
  });
}
