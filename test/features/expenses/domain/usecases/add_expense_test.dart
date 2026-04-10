import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spending_log/features/expenses/domain/usecases/add_expense.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late MockExpenseRepository mockRepository;
  late AddExpense useCase;

  setUp(() {
    mockRepository = MockExpenseRepository();
    useCase = AddExpense(mockRepository);
  });

  test('should call repository.addExpense with the given expense', () async {
    final expense = makeExpense();
    when(() => mockRepository.addExpense(expense)).thenAnswer((_) async {});

    await useCase(expense);

    verify(() => mockRepository.addExpense(expense)).called(1);
  });
}
