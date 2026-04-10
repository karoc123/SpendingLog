import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spending_log/features/expenses/domain/usecases/delete_expense.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late MockExpenseRepository mockRepository;
  late DeleteExpense useCase;

  setUp(() {
    mockRepository = MockExpenseRepository();
    useCase = DeleteExpense(mockRepository);
  });

  test('should call repository.deleteExpense with the given id', () async {
    when(() => mockRepository.deleteExpense('abc')).thenAnswer((_) async {});

    await useCase('abc');

    verify(() => mockRepository.deleteExpense('abc')).called(1);
  });
}
