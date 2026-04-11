import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spending_log/features/settings/presentation/screens/settings_screen.dart';
import 'package:spending_log/core/providers/core_providers.dart';

import '../../../../helpers/widget_test_helpers.dart';

void main() {
  List<Override> buildOverrides() {
    return [
      currencySymbolProvider.overrideWith((ref) => Stream.value('€')),
      localeSettingProvider.overrideWith((ref) => Stream.value('de')),
      themeModeSettingProvider.overrideWith((ref) => Stream.value('system')),
      biometricsEnabledProvider.overrideWith((ref) => Stream.value(false)),
    ];
  }

  testWidgets('SettingsScreen renders section headers', (tester) async {
    await tester.pumpWidget(
      buildTestApp(const SettingsScreen(), overrides: buildOverrides()),
    );
    await tester.pumpAndSettle();

    // Should have main sections visible
    expect(find.byType(ListTile), findsWidgets);
  });

  testWidgets('SettingsScreen renders currency option', (tester) async {
    await tester.pumpWidget(
      buildTestApp(const SettingsScreen(), overrides: buildOverrides()),
    );
    await tester.pumpAndSettle();

    // Should show currency setting somewhere
    expect(find.textContaining('€'), findsWidgets);
  });

  testWidgets('SettingsScreen shows Philosophy dialog', (tester) async {
    await tester.pumpWidget(
      buildTestApp(const SettingsScreen(), overrides: buildOverrides()),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Philosophy'),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Philosophy'));
    await tester.pumpAndSettle();

    expect(find.text('Philosophy'), findsWidgets);
    expect(find.textContaining('kein Tracking'), findsOneWidget);
    expect(find.textContaining('Monekin'), findsWidgets);
  });
}
