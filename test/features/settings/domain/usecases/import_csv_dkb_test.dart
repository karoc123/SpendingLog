import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spending_log/features/settings/domain/usecases/import_csv_dkb.dart';
import 'package:spending_log/features/expenses/domain/entities/expense_entity.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late MockExpenseRepository mockExpenseRepository;
  late MockCategoryRepository mockCategoryRepository;
  late ImportCsvDkb useCase;

  setUpAll(() {
    registerFallbackValue(makeExpense());
    registerFallbackValue(makeCategory());
  });

  setUp(() {
    mockExpenseRepository = MockExpenseRepository();
    mockCategoryRepository = MockCategoryRepository();
    useCase = ImportCsvDkb(mockExpenseRepository, mockCategoryRepository);

    when(
      () => mockExpenseRepository.addExpense(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockExpenseRepository.findLatestExpenseByDescription(any()),
    ).thenAnswer((_) async => null);
  });

  test(
    'reuses existing Import category instead of creating recipient category',
    () async {
      when(
        () => mockCategoryRepository.getAllCategories(),
      ).thenAnswer((_) async => [makeCategory(id: 7, name: 'Import')]);

      final imported = await useCase(
        _dkbCsv([
          [
            '10.04.26',
            '10.04.26',
            'Gebucht',
            'A',
            'Coffee Shop',
            'Latte',
            'Ausgang',
            'DE123',
            '-12,50',
          ],
        ]),
      );

      expect(imported, 1);
      verifyNever(() => mockCategoryRepository.addCategory(any()));
      verify(
        () => mockExpenseRepository.addExpense(
          any(
            that: isA<ExpenseEntity>().having(
              (expense) => expense.categoryId,
              'categoryId',
              7,
            ),
          ),
        ),
      ).called(1);
    },
  );

  test(
    'creates Import category once and reuses it for multiple rows',
    () async {
      when(
        () => mockCategoryRepository.getAllCategories(),
      ).thenAnswer((_) async => []);
      when(
        () => mockCategoryRepository.addCategory(any()),
      ).thenAnswer((_) async => 99);

      final imported = await useCase(
        _dkbCsv([
          [
            '10.04.26',
            '10.04.26',
            'Gebucht',
            'A',
            'Coffee Shop',
            'Latte',
            'Ausgang',
            'DE123',
            '-12,50',
          ],
          [
            '11.04.26',
            '11.04.26',
            'Gebucht',
            'A',
            'Bakery',
            'Bread',
            'Ausgang',
            'DE123',
            '-4,20',
          ],
        ]),
      );

      expect(imported, 2);
      verify(() => mockCategoryRepository.addCategory(any())).called(1);
      verify(() => mockExpenseRepository.addExpense(any())).called(2);
    },
  );
}

String _dkbCsv(List<List<String>> rows) {
  const header =
      'Buchungsdatum;Wertstellung;Status;Zahlungspflichtiger;Zahlungsempfänger*in;Verwendungszweck;Umsatztyp;IBAN;Betrag(€)';
  return [
    'DKB',
    'Saldo',
    header,
    ...rows.map((row) => row.join(';')),
  ].join('\n');
}
