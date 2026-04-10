import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spending_log/features/recurring/domain/usecases/delete_recurring_expense.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late MockRecurringExpenseRepository mockRepository;
  late DeleteRecurringExpense useCase;

  setUp(() {
    mockRepository = MockRecurringExpenseRepository();
    useCase = DeleteRecurringExpense(mockRepository);
  });

  test(
    'should call repository.deleteRecurringExpense with the given id',
    () async {
      when(
        () => mockRepository.deleteRecurringExpense('r1'),
      ).thenAnswer((_) async {});

      await useCase('r1');

      verify(() => mockRepository.deleteRecurringExpense('r1')).called(1);
    },
  );
}
