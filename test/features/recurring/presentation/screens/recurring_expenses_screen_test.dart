import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spending_log/features/recurring/presentation/screens/recurring_expenses_screen.dart';
import 'package:spending_log/features/recurring/domain/entities/recurring_expense_entity.dart';
import 'package:spending_log/features/expenses/presentation/providers/expense_providers.dart';
import 'package:spending_log/core/providers/core_providers.dart';

import '../../../../helpers/test_helpers.dart';
import '../../../../helpers/widget_test_helpers.dart';

void main() {
  final testRecurring = [
    makeRecurring(
      id: 'r1',
      name: 'Netflix',
      amountCents: 1599,
      interval: RecurringInterval.monthly,
    ),
    makeRecurring(
      id: 'r2',
      name: 'Insurance',
      amountCents: 30000,
      interval: RecurringInterval.yearly,
    ),
  ];

  final testCategories = [makeCategory(id: 1, name: 'Freizeit')];

  List<Override> buildOverrides() {
    return [
      recurringExpenseListProvider.overrideWith(
        (ref) => Stream.value(testRecurring),
      ),
      allCategoriesProvider.overrideWith((ref) => Stream.value(testCategories)),
      currencySymbolProvider.overrideWith((ref) => Stream.value('€')),
    ];
  }

  testWidgets('RecurringExpensesScreen renders list items', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        const RecurringExpensesScreen(),
        overrides: buildOverrides(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('Insurance'), findsOneWidget);
  });

  testWidgets('RecurringExpensesScreen has FAB to add', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        const RecurringExpensesScreen(),
        overrides: buildOverrides(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('Recurring create form shows next transaction preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        const RecurringExpensesScreen(),
        overrides: buildOverrides(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Nächste Transaktion'), findsOneWidget);
  });

  testWidgets('RecurringExpensesScreen shows empty state when no items', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        const RecurringExpensesScreen(),
        overrides: [
          recurringExpenseListProvider.overrideWith((ref) => Stream.value([])),
          allCategoriesProvider.overrideWith(
            (ref) => Stream.value(testCategories),
          ),
          currencySymbolProvider.overrideWith((ref) => Stream.value('€')),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // Should show empty state or at least not crash
    expect(find.text('Netflix'), findsNothing);
  });

  testWidgets(
    'Recurring screen shows category actions when no categories exist',
    (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const RecurringExpensesScreen(),
          overrides: [
            recurringExpenseListProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
            allCategoriesProvider.overrideWith((ref) => Stream.value([])),
            currencySymbolProvider.overrideWith((ref) => Stream.value('€')),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Standardkategorien hinzufügen'), findsOneWidget);
      expect(find.text('Kategorien verwalten'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    },
  );
}
