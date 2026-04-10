import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spending_log/features/expenses/domain/entities/expense_entity.dart';
import 'package:spending_log/features/categories/domain/entities/category_entity.dart';
import 'package:spending_log/features/settings/domain/usecases/import_csv.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late MockExpenseRepository mockExpenseRepository;
  late MockCategoryRepository mockCategoryRepository;
  late ImportCsv useCase;

  setUpAll(() {
    registerFallbackValue(makeExpense());
    registerFallbackValue(makeCategory());
  });

  setUp(() {
    mockExpenseRepository = MockExpenseRepository();
    mockCategoryRepository = MockCategoryRepository();
    useCase = ImportCsv(mockExpenseRepository, mockCategoryRepository);
  });

  test('should return 0 for empty CSV', () async {
    final result = await useCase('');

    expect(result, 0);
  });

  test('should return 0 for header-only CSV', () async {
    final csv =
        'ID,Amount,Date,Title,Note,Account,Currency,Category,Subcategory\n';

    when(
      () => mockCategoryRepository.getAllCategories(),
    ).thenAnswer((_) async => []);

    final result = await useCase(csv);

    expect(result, 0);
  });

  test('should import a valid expense row', () async {
    final csv =
        'ID,Amount,Date,Title,Note,Account,Currency,Category,Subcategory\n'
        '1,-12.50,2026-01-15,Coffee,Good one,Cash,EUR,Essen,\n';

    final existingCategory = makeCategory(id: 5, name: 'Essen');
    when(
      () => mockCategoryRepository.getAllCategories(),
    ).thenAnswer((_) async => [existingCategory]);
    when(
      () => mockExpenseRepository.addExpense(any()),
    ).thenAnswer((_) async {});

    final result = await useCase(csv);

    expect(result, 1);
    final captured =
        verify(
              () => mockExpenseRepository.addExpense(captureAny()),
            ).captured.single
            as ExpenseEntity;
    expect(captured.amountCents, 1250); // abs of -12.50
    expect(captured.description, 'Coffee');
    expect(captured.categoryId, 5);
  });

  test('should create new category if not exists', () async {
    final csv =
        'ID,Amount,Date,Title,Note,Account,Currency,Category,Subcategory\n'
        '1,-5.00,2026-01-15,Movie,,Cash,EUR,NewCat,\n';

    when(
      () => mockCategoryRepository.getAllCategories(),
    ).thenAnswer((_) async => []);
    when(
      () => mockCategoryRepository.addCategory(any()),
    ).thenAnswer((_) async => 99);
    when(
      () => mockExpenseRepository.addExpense(any()),
    ).thenAnswer((_) async {});

    final result = await useCase(csv);

    expect(result, 1);
    verify(() => mockCategoryRepository.addCategory(any())).called(1);
    final captured =
        verify(
              () => mockExpenseRepository.addExpense(captureAny()),
            ).captured.single
            as ExpenseEntity;
    expect(captured.categoryId, 99);
  });

  test('should handle subcategory creation', () async {
    final csv =
        'ID,Amount,Date,Title,Note,Account,Currency,Category,Subcategory\n'
        '1,-3.00,2026-01-15,Espresso,,Cash,EUR,Food,Coffee\n';

    final parentCat = makeCategory(id: 1, name: 'Food');
    when(
      () => mockCategoryRepository.getAllCategories(),
    ).thenAnswer((_) async => [parentCat]);
    when(
      () => mockCategoryRepository.addCategory(any()),
    ).thenAnswer((_) async => 10);
    when(
      () => mockExpenseRepository.addExpense(any()),
    ).thenAnswer((_) async {});

    final result = await useCase(csv);

    expect(result, 1);
    // Should have created subcategory
    final addedCat =
        verify(
              () => mockCategoryRepository.addCategory(captureAny()),
            ).captured.single
            as CategoryEntity;
    expect(addedCat.name, 'Coffee');
    expect(addedCat.parentId, 1);
  });

  test('should skip rows with invalid amount', () async {
    final csv =
        'ID,Amount,Date,Title,Note,Account,Currency,Category,Subcategory\n'
        '1,invalid,2026-01-15,Test,,Cash,EUR,Food,\n';

    when(
      () => mockCategoryRepository.getAllCategories(),
    ).thenAnswer((_) async => [makeCategory(id: 1, name: 'Food')]);

    final result = await useCase(csv);

    expect(result, 0);
    verifyNever(() => mockExpenseRepository.addExpense(any()));
  });

  test('should skip rows with invalid date', () async {
    final csv =
        'ID,Amount,Date,Title,Note,Account,Currency,Category,Subcategory\n'
        '1,-5.00,not-a-date,Test,,Cash,EUR,Food,\n';

    when(
      () => mockCategoryRepository.getAllCategories(),
    ).thenAnswer((_) async => [makeCategory(id: 1, name: 'Food')]);

    final result = await useCase(csv);

    expect(result, 0);
    verifyNever(() => mockExpenseRepository.addExpense(any()));
  });

  test('should import multiple rows', () async {
    final csv =
        'ID,Amount,Date,Title,Note,Account,Currency,Category,Subcategory\n'
        '1,-5.00,2026-01-15,Coffee,,Cash,EUR,Food,\n'
        '2,-10.00,2026-01-16,Lunch,,Cash,EUR,Food,\n'
        '3,-3.00,2026-01-17,Snack,,Cash,EUR,Food,\n';

    when(
      () => mockCategoryRepository.getAllCategories(),
    ).thenAnswer((_) async => [makeCategory(id: 1, name: 'Food')]);
    when(
      () => mockExpenseRepository.addExpense(any()),
    ).thenAnswer((_) async {});

    final result = await useCase(csv);

    expect(result, 3);
    verify(() => mockExpenseRepository.addExpense(any())).called(3);
  });
}
