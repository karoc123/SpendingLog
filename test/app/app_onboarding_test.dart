import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:spending_log/app/onboarding_gate.dart';
import 'package:spending_log/core/providers/core_providers.dart';
import 'package:spending_log/features/settings/domain/repositories/settings_repository.dart';
import 'package:spending_log/features/settings/domain/usecases/update_setting.dart';
import 'package:spending_log/l10n/generated/app_localizations.dart';
import 'package:spending_log/app/theme.dart';

class FakeSettingsRepository implements SettingsRepository {
  final Map<String, String> _values;
  final Map<String, StreamController<String?>> _controllers = {};

  FakeSettingsRepository(this._values);

  @override
  Future<String?> getSetting(String key) async => _values[key];

  @override
  Stream<String?> watchSetting(String key) {
    final controller = _controllers.putIfAbsent(
      key,
      () => StreamController<String?>.broadcast(),
    );
    return Stream<String?>.multi((multi) {
      multi.add(_values[key]);
      final subscription = controller.stream.listen(multi.add);
      multi.onCancel = subscription.cancel;
    });
  }

  @override
  Future<void> setSetting(String key, String value) async {
    _values[key] = value;
    _controllers
        .putIfAbsent(key, () => StreamController<String?>.broadcast())
        .add(value);
  }

  @override
  Future<Map<String, String>> getAllSettings() async => Map.of(_values);

  Future<void> dispose() async {
    for (final controller in _controllers.values) {
      await controller.close();
    }
  }
}

class _TestOnboardingHost extends ConsumerWidget {
  const _TestOnboardingHost();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needsOnboarding = ref.watch(needsOnboardingProvider);
    final locale = ref.watch(localeSettingProvider).value ?? 'de';
    final themeMode = ref.watch(themeModeSettingProvider).value ?? 'system';

    return Stack(
      children: [
        const Scaffold(body: SizedBox.expand()),
        if (needsOnboarding)
          OnboardingGate(
            initialLocaleCode: locale,
            initialThemeMode: themeMode,
            onComplete: (result) async {
              final updateSetting = ref.read(updateSettingProvider);
              await updateSetting.call('locale', result.localeCode);
              await updateSetting.call('theme_mode', result.themeMode);
              await updateSetting.call(
                'onboarding_version',
                requiredOnboardingVersion,
              );
              await updateSetting.call('onboarding_completed', 'true');
            },
          ),
      ],
    );
  }
}

void main() {
  Widget buildHost(FakeSettingsRepository settingsRepository) {
    return ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
        updateSettingProvider.overrideWith(
          (ref) => UpdateSetting(ref.watch(settingsRepositoryProvider)),
        ),
      ],
      child: MaterialApp(
        theme: buildLightTheme(),
        locale: const Locale('de'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const _TestOnboardingHost(),
      ),
    );
  }

  testWidgets('shows onboarding when completion flag is false', (tester) async {
    final settingsRepository = FakeSettingsRepository({
      'locale': 'de',
      'theme_mode': 'system',
      'onboarding_completed': 'false',
      'onboarding_version': requiredOnboardingVersion,
    });

    await tester.pumpWidget(buildHost(settingsRepository));
    await tester.pumpAndSettle();

    expect(find.text('Einrichtung'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await settingsRepository.dispose();
  });

  testWidgets('shows onboarding when stored version is outdated', (
    tester,
  ) async {
    final settingsRepository = FakeSettingsRepository({
      'locale': 'de',
      'theme_mode': 'system',
      'onboarding_completed': 'true',
      'onboarding_version': '0',
    });

    await tester.pumpWidget(buildHost(settingsRepository));
    await tester.pumpAndSettle();

    expect(find.text('Einrichtung'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await settingsRepository.dispose();
  });

  testWidgets('saves onboarding selection and hides overlay', (tester) async {
    final settingsRepository = FakeSettingsRepository({
      'locale': 'de',
      'theme_mode': 'system',
      'onboarding_completed': 'false',
      'onboarding_version': '0',
    });

    await tester.pumpWidget(buildHost(settingsRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dunkel'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Standardkategorien hinzufügen'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();

    expect(await settingsRepository.getSetting('locale'), 'en');
    expect(await settingsRepository.getSetting('theme_mode'), 'dark');
    expect(await settingsRepository.getSetting('onboarding_completed'), 'true');
    expect(await settingsRepository.getSetting('onboarding_version'), '1');
    expect(find.text('Einrichtung'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await settingsRepository.dispose();
  });
}
