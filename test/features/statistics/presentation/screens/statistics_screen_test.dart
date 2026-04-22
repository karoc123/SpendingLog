import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spending_log/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:spending_log/features/statistics/presentation/providers/statistics_providers.dart';
import 'package:spending_log/features/statistics/domain/usecases/get_spending_by_category.dart';
import 'package:spending_log/features/statistics/domain/usecases/get_spending_summary.dart';
import 'package:spending_log/features/expenses/presentation/providers/expense_providers.dart';
import 'package:spending_log/core/providers/core_providers.dart';

import '../../../../helpers/test_helpers.dart';
import '../../../../helpers/widget_test_helpers.dart';

void main() {
  final testSpending = [
    CategorySpending(
      categoryId: 1,
      categoryName: 'Lebensmittel',
      colorValue: 0xFF4CAF50,
      iconName: 'shopping_cart',
      totalCents: 5000,
      transactionCount: 3,
    ),
    CategorySpending(
      categoryId: 2,
      categoryName: 'Freizeit',
      colorValue: 0xFF2196F3,
      iconName: 'sports_esports',
      totalCents: 2000,
      transactionCount: 1,
    ),
  ];

  const testSummary = SpendingSummary(
    totalCents: 7000,
    topCategoryName: '1',
    transactionCount: 4,
  );

  List<Override> buildOverrides() {
    return [
      spendingByCategoryProvider.overrideWith((ref) async => testSpending),
      spendingSummaryProvider.overrideWith((ref) async => testSummary),
      currencySymbolProvider.overrideWith((ref) => Stream.value('€')),
      currentMonthExpensesProvider.overrideWith((ref) => Stream.value([])),
      allCategoriesProvider.overrideWith(
        (ref) => Stream.value([
          makeCategory(id: 1, name: 'Lebensmittel'),
          makeCategory(id: 2, name: 'Freizeit'),
        ]),
      ),
    ];
  }

  testWidgets('StatisticsScreen renders app bar', (tester) async {
    await tester.pumpWidget(
      buildTestApp(const StatisticsScreen(), overrides: buildOverrides()),
    );
    // Use pump with duration because fl_chart has ongoing animations.
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('StatisticsScreen shows category spending', (tester) async {
    await tester.pumpWidget(
      buildTestApp(const StatisticsScreen(), overrides: buildOverrides()),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Lebensmittel'), findsWidgets);
    expect(find.text('Freizeit'), findsWidgets);
  });

  testWidgets('StatisticsScreen shows total amount', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        const StatisticsScreen(),
        overrides: [
          ...buildOverrides(),
          filteredStatsExpensesProvider.overrideWith((ref, filter) async {
            return [
              makeExpense(id: 'sum-1', amountCents: 5000, categoryId: 1),
              makeExpense(id: 'sum-2', amountCents: 2000, categoryId: 2),
            ];
          }),
        ],
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    // 7000 cents = 70.00, should appear somewhere
    expect(find.textContaining('70'), findsWidgets);
  });

  testWidgets('StatisticsScreen shows expenses and savings bar legend', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        const StatisticsScreen(),
        overrides: [
          ...buildOverrides(),
          filteredStatsExpensesProvider.overrideWith((ref, filter) async {
            return [
              makeExpense(id: 'bar-1', amountCents: 3000, categoryId: 1),
              makeExpense(id: 'bar-2', amountCents: 1500, categoryId: 2),
            ];
          }),
        ],
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Sparen'), findsOneWidget);
    expect(find.text('Ausgaben'), findsWidgets);
  });

  testWidgets('StatisticsScreen shows filtered total, count and active label', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        const StatisticsScreen(),
        overrides: [
          ...buildOverrides(),
          filteredStatsExpensesProvider.overrideWith((ref, filter) async {
            return [
              makeExpense(id: 'filtered-1', amountCents: 5000, categoryId: 1),
              makeExpense(id: 'filtered-2', amountCents: 2500, categoryId: 1),
            ];
          }),
          selectedParentChartCategoryProvider.overrideWith((ref) => 1),
        ],
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Lebensmittel'), findsWidgets);
    expect(find.textContaining('75'), findsWidgets);
    expect(find.text('2'), findsWidgets);
  });

  testWidgets('Statistics back first undoes sub drill, then parent drill', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        const StatisticsScreen(),
        overrides: [
          spendingByCategoryProvider.overrideWith((ref) async => const []),
          subcategorySpendingProvider.overrideWith(
            (ref, parentId) async => const [],
          ),
          spendingSummaryProvider.overrideWith((ref) async => testSummary),
          filteredStatsExpensesProvider.overrideWith((ref, filter) async {
            return [];
          }),
          currencySymbolProvider.overrideWith((ref) => Stream.value('€')),
          currentMonthExpensesProvider.overrideWith((ref) => Stream.value([])),
          allCategoriesProvider.overrideWith(
            (ref) => Stream.value([
              makeCategory(id: 1, name: 'Parent Active'),
              makeCategory(id: 2, name: 'Child Active', parentId: 1),
            ]),
          ),
          selectedParentChartCategoryProvider.overrideWith((ref) => 1),
          selectedSubChartCategoryProvider.overrideWith((ref) => 2),
        ],
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Child Active'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Child Active'), findsNothing);
    expect(find.text('Parent Active'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Parent Active'), findsNothing);
  });
}
