import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spending_log/features/expenses/presentation/screens/home_screen.dart';
import 'package:spending_log/features/expenses/presentation/providers/expense_providers.dart';
import 'package:spending_log/features/expenses/domain/entities/expense_entity.dart';
import 'package:spending_log/features/categories/domain/entities/category_entity.dart';
import 'package:spending_log/core/providers/core_providers.dart';
import 'package:spending_log/features/expenses/domain/usecases/add_expense.dart';
import 'package:spending_log/features/expenses/domain/usecases/delete_expense.dart';
import 'package:spending_log/features/expenses/domain/usecases/update_expense.dart';

import '../../../../helpers/test_helpers.dart';
import '../../../../helpers/widget_test_helpers.dart';

class MockAddExpense extends Mock implements AddExpense {}

class MockDeleteExpense extends Mock implements DeleteExpense {}

class MockUpdateExpense extends Mock implements UpdateExpense {}

void main() {
  late MockAddExpense mockAddExpense;
  late MockDeleteExpense mockDeleteExpense;
  late MockUpdateExpense mockUpdateExpense;

  setUpAll(() {
    registerFallbackValue(makeExpense());
  });

  setUp(() {
    mockAddExpense = MockAddExpense();
    mockDeleteExpense = MockDeleteExpense();
    mockUpdateExpense = MockUpdateExpense();

    when(() => mockAddExpense(any())).thenAnswer((_) async {});
    when(() => mockDeleteExpense(any())).thenAnswer((_) async {});
    when(() => mockUpdateExpense(any())).thenAnswer((_) async {});
  });

  final testCategories = <CategoryEntity>[
    makeCategory(id: 1, name: 'Lebensmittel'),
    makeCategory(id: 2, name: 'Kaffee', parentId: 1),
    makeCategory(id: 3, name: 'Freizeit'),
  ];

  final testExpenses = <ExpenseEntity>[
    makeExpense(
      id: 'e1',
      amountCents: 1250,
      description: 'Kaffee',
      categoryId: 2,
    ),
  ];

  List<Override> buildOverrides() {
    return [
      allCategoriesProvider.overrideWith((ref) => Stream.value(testCategories)),
      expenseListProvider.overrideWith((ref) => Stream.value(testExpenses)),
      currentMonthExpensesProvider.overrideWith(
        (ref) => Stream.value(testExpenses),
      ),
      committedAmountProvider.overrideWith((ref) async => 0),
      currencySymbolProvider.overrideWith((ref) => Stream.value('€')),
      addExpenseProvider.overrideWithValue(mockAddExpense),
      deleteExpenseProvider.overrideWithValue(mockDeleteExpense),
      updateExpenseProvider.overrideWithValue(mockUpdateExpense),
    ];
  }

  testWidgets('HomeScreen renders amount field and category picker', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(const HomeScreen(), overrides: buildOverrides()),
    );
    await tester.pumpAndSettle();

    // Amount text field should be present
    expect(find.byType(TextField), findsWidgets);

    // Category picker field should be shown
    expect(find.text('Bitte Kategorie wählen'), findsOneWidget);
  });

  testWidgets('HomeScreen picks subcategory through modal', (tester) async {
    await tester.pumpWidget(
      buildTestApp(const HomeScreen(), overrides: buildOverrides()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bitte Kategorie wählen'));
    await tester.pumpAndSettle();

    expect(find.text('Lebensmittel'), findsOneWidget);
    expect(find.text('Freizeit'), findsOneWidget);

    await tester.tap(find.text('Lebensmittel'));
    await tester.pumpAndSettle();

    expect(find.text('Kaffee'), findsWidgets);

    await tester.tap(find.text('Kaffee').last);
    await tester.pumpAndSettle();

    expect(find.text('Lebensmittel -> Kaffee'), findsOneWidget);
  });

  testWidgets('HomeScreen shows recent expenses', (tester) async {
    await tester.pumpWidget(
      buildTestApp(const HomeScreen(), overrides: buildOverrides()),
    );
    await tester.pumpAndSettle();

    // The expense description should appear in the list
    expect(find.text('Kaffee'), findsWidgets);
  });

  testWidgets('HomeScreen Save button exists', (tester) async {
    await tester.pumpWidget(
      buildTestApp(const HomeScreen(), overrides: buildOverrides()),
    );
    await tester.pumpAndSettle();

    // Should have a save/add button (icon or text)
    expect(
      find.byType(ElevatedButton).evaluate().isNotEmpty ||
          find.byType(FilledButton).evaluate().isNotEmpty ||
          find.byIcon(Icons.save).evaluate().isNotEmpty ||
          find.byIcon(Icons.check).evaluate().isNotEmpty ||
          find.byIcon(Icons.add).evaluate().isNotEmpty,
      isTrue,
    );
  });
}
