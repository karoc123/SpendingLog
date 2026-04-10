import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spending_log/features/expenses/domain/usecases/update_expense.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late MockExpenseRepository mockRepository;
  late UpdateExpense useCase;

  setUp(() {
    mockRepository = MockExpenseRepository();
    useCase = UpdateExpense(mockRepository);
  });

  test('should call repository.updateExpense with the given expense', () async {
    final expense = makeExpense();
    when(() => mockRepository.updateExpense(expense)).thenAnswer((_) async {});

    await useCase(expense);

    verify(() => mockRepository.updateExpense(expense)).called(1);
  });
}
