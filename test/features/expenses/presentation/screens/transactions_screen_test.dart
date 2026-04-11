import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spending_log/features/expenses/presentation/screens/transactions_screen.dart';
import 'package:spending_log/features/expenses/presentation/providers/expense_providers.dart';
import 'package:spending_log/features/categories/domain/entities/category_entity.dart';
import 'package:spending_log/features/expenses/domain/entities/expense_entity.dart';
import 'package:spending_log/core/providers/core_providers.dart';

import '../../../../helpers/test_helpers.dart';
import '../../../../helpers/widget_test_helpers.dart';

void main() {
  final testCategories = <CategoryEntity>[
    makeCategory(id: 1, name: 'Lebensmittel'),
    makeCategory(id: 2, name: 'Kaffee', parentId: 1),
    makeCategory(id: 3, name: 'Freizeit'),
  ];

  final testExpenses = <ExpenseEntity>[
    makeExpense(
      id: 'e1',
      description: 'Latte',
      categoryId: 2,
      amountCents: 450,
    ),
  ];

  List<Override> buildOverrides() {
    return [
      allCategoriesProvider.overrideWith((ref) => Stream.value(testCategories)),
      expenseListProvider.overrideWith((ref) => Stream.value(testExpenses)),
      currencySymbolProvider.overrideWith((ref) => Stream.value('€')),
    ];
  }

  testWidgets(
    'TransactionsScreen opens category modal filter with all option',
    (tester) async {
      await tester.pumpWidget(
        buildTestApp(const TransactionsScreen(), overrides: buildOverrides()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Alle').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Alle'), findsWidgets);
      expect(find.text('Lebensmittel'), findsOneWidget);
    },
  );
}
