import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spending_log/features/recurring/domain/usecases/update_recurring_expense.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late MockRecurringExpenseRepository mockRepository;
  late UpdateRecurringExpense useCase;

  setUp(() {
    mockRepository = MockRecurringExpenseRepository();
    useCase = UpdateRecurringExpense(mockRepository);
  });

  test('should call repository.updateRecurringExpense', () async {
    final recurring = makeRecurring();
    when(
      () => mockRepository.updateRecurringExpense(recurring),
    ).thenAnswer((_) async {});

    await useCase(recurring);

    verify(() => mockRepository.updateRecurringExpense(recurring)).called(1);
  });
}
