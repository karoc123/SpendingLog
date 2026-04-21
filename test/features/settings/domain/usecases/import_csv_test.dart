import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spending_log/core/utils/icon_map.dart';
import 'package:spending_log/features/expenses/domain/entities/expense_entity.dart';
import 'package:spending_log/features/categories/domain/entities/category_entity.dart';
import 'package:spending_log/features/settings/domain/usecases/import_csv_monekin.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late MockExpenseRepository mockExpenseRepository;
  late MockCategoryRepository mockCategoryRepository;
  late ImportCsvMonekin useCase;

  setUpAll(() {
    registerFallbackValue(makeExpense());
    registerFallbackValue(makeCategory());
  });

  setUp(() {
    mockExpenseRepository = MockExpenseRepository();
    mockCategoryRepository = MockCategoryRepository();
    useCase = ImportCsvMonekin(mockExpenseRepository, mockCategoryRepository);
    when(
      () => mockExpenseRepository.getAllExpenses(),
    ).thenAnswer((_) async => []);
    when(
      () => mockCategoryRepository.deleteCategory(any()),
    ).thenAnswer((_) async {});
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

  test('should skip positive amounts (credits/refunds)', () async {
    final csv =
        'ID,Amount,Date,Title,Note,Account,Currency,Category,Subcategory\n'
        '1,12.50,2026-01-15,Refund,,Cash,EUR,Food,\n'
        '2,-9.90,2026-01-15,Coffee,,Cash,EUR,Food,\n';

    when(
      () => mockCategoryRepository.getAllCategories(),
    ).thenAnswer((_) async => [makeCategory(id: 1, name: 'Food')]);
    when(
      () => mockExpenseRepository.addExpense(any()),
    ).thenAnswer((_) async {});

    final result = await useCase(csv);

    expect(result, 1);
    verify(() => mockExpenseRepository.addExpense(any())).called(1);
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
    expect(addedCat.colorValue, parentCat.colorValue);
  });

  test('should assign deterministic color to new parent category', () async {
    final csv =
        'ID,Amount,Date,Title,Note,Account,Currency,Category,Subcategory\n'
        '1,-3.00,2026-01-15,Tea,,Cash,EUR,BrandNewParent,\n';

    when(
      () => mockCategoryRepository.getAllCategories(),
    ).thenAnswer((_) async => []);
    when(
      () => mockCategoryRepository.addCategory(any()),
    ).thenAnswer((_) async => 42);
    when(
      () => mockExpenseRepository.addExpense(any()),
    ).thenAnswer((_) async {});

    await useCase(csv);

    final createdParent =
        verify(
              () => mockCategoryRepository.addCategory(captureAny()),
            ).captured.first
            as CategoryEntity;
    expect(availableCategoryColors, contains(createdParent.colorValue));
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

  test(
    'should map same subcategory name under different parents correctly',
    () async {
      final csv =
          'ID,Amount,Date,Title,Note,Account,Currency,Category,Subcategory\n'
          '1,-15.00,2026-01-15,Food item,,Cash,EUR,Food,General\n'
          '2,-120.00,2026-01-16,Housing item,,Cash,EUR,Housing,General\n';

      final food = makeCategory(id: 1, name: 'Food');
      final housing = makeCategory(id: 2, name: 'Housing');

      when(
        () => mockCategoryRepository.getAllCategories(),
      ).thenAnswer((_) async => [food, housing]);
      when(() => mockCategoryRepository.addCategory(any())).thenAnswer((
        inv,
      ) async {
        final category = inv.positionalArguments.first as CategoryEntity;
        return category.parentId == 1 ? 101 : 202;
      });
      when(
        () => mockExpenseRepository.addExpense(any()),
      ).thenAnswer((_) async {});

      final result = await useCase(csv);

      expect(result, 2);

      final createdSubcategories = verify(
        () => mockCategoryRepository.addCategory(captureAny()),
      ).captured.cast<CategoryEntity>();

      expect(createdSubcategories.length, 2);
      expect(createdSubcategories[0].name, 'General');
      expect(createdSubcategories[0].parentId, 1);
      expect(createdSubcategories[1].name, 'General');
      expect(createdSubcategories[1].parentId, 2);

      final importedExpenses = verify(
        () => mockExpenseRepository.addExpense(captureAny()),
      ).captured.cast<ExpenseEntity>();
      expect(importedExpenses.length, 2);
      expect(importedExpenses[0].categoryId, 101);
      expect(importedExpenses[1].categoryId, 202);
    },
  );

  test('should delete only unused seeded default parent categories', () async {
    final csv =
        'ID,Amount,Date,Title,Note,Account,Currency,Category,Subcategory\n'
        '1,-15.00,2026-01-15,Lunch,,Cash,EUR,Essen,\n';

    final seededUsed = makeCategory(id: 1, name: 'Essen');
    final seededUnused = makeCategory(id: 2, name: 'Arbeit');
    final userCategory = makeCategory(id: 99, name: 'Custom');

    when(
      () => mockCategoryRepository.getAllCategories(),
    ).thenAnswer((_) async => [seededUsed, seededUnused, userCategory]);
    when(
      () => mockExpenseRepository.addExpense(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockExpenseRepository.getAllExpenses(),
    ).thenAnswer((_) async => [makeExpense(categoryId: 1)]);

    await useCase(csv);

    verify(() => mockCategoryRepository.deleteCategory(2)).called(1);
    verifyNever(() => mockCategoryRepository.deleteCategory(1));
    verifyNever(() => mockCategoryRepository.deleteCategory(99));
  });
}
