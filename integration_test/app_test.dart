import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spending_log/app/app.dart';
import 'package:spending_log/core/database/app_database.dart';
import 'package:spending_log/core/providers/core_providers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Happy path: add expense, see it in list', (tester) async {
    // Use in-memory database for integration tests.
    final db = AppDatabase.memory();
    addTearDown(() => db.close());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const SpendingLogApp(),
      ),
    );

    // Wait for the app to load (localization, database, etc.).
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // The Home tab should be selected by default.
    // 1. Enter an amount.
    final amountFields = find.byType(TextField);
    expect(amountFields, findsWidgets);
    await tester.enterText(amountFields.first, '15,50');
    await tester.pump();

    // 2. Enter a description.
    final textFields = find.byType(TextField);
    // Second text field is typically the description.
    if (textFields.evaluate().length > 1) {
      await tester.enterText(textFields.at(1), 'Integration Test Coffee');
      await tester.pump();
    }

    // 3. Tap the save button (look for FilledButton or ElevatedButton).
    final saveButton = find.byType(FilledButton).evaluate().isNotEmpty
        ? find.byType(FilledButton).first
        : find.byType(ElevatedButton).first;
    await tester.tap(saveButton);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // 4. Verify the expense appears in the list.
    expect(find.text('Integration Test Coffee'), findsOneWidget);

    // 5. Navigate to Statistics tab.
    await tester.tap(find.byIcon(Icons.pie_chart_outline));
    await tester.pump(const Duration(seconds: 2));

    // Statistics screen should be visible.
    expect(find.byType(AppBar), findsOneWidget);

    // 6. Navigate to Settings tab.
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    // Settings screen should render without errors.
    expect(find.byType(ListTile), findsWidgets);
  });
}
