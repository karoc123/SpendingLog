import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../core/database/app_database.dart';
import '../core/providers/core_providers.dart';
import '../l10n/generated/app_localizations.dart';
import 'router.dart';
import 'theme.dart';

const _requiredOnboardingVersion = '1';

class SpendingLogApp extends ConsumerStatefulWidget {
  const SpendingLogApp({super.key});

  @override
  ConsumerState<SpendingLogApp> createState() => _SpendingLogAppState();
}

class _SpendingLogAppState extends ConsumerState<SpendingLogApp>
    with WidgetsBindingObserver {
  static const _inactivityTimeout = Duration(minutes: 15);

  ProviderSubscription<AsyncValue<bool>>? _biometricsSubscription;
  DateTime? _lastPausedAt;
  bool _isLocked = false;
  bool _isAuthenticating = false;
  bool _didColdStartCheck = false;
  bool _isOnboardingRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _biometricsSubscription = ref.listenManual<AsyncValue<bool>>(
      biometricsEnabledProvider,
      (previous, next) {
        if (next.value == true) {
          _checkBiometricLockRequirement(isColdStart: !_didColdStartCheck);
          return;
        }
        if (next.value == false && _isLocked && mounted) {
          setState(() => _isLocked = false);
        }
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometricLockRequirement(isColdStart: true);
      _ensureOnboardingCompleted();
    });
  }

  @override
  void dispose() {
    _biometricsSubscription?.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _lastPausedAt = DateTime.now();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _checkBiometricLockRequirement(isColdStart: false);
    }
  }

  Future<void> _checkBiometricLockRequirement({
    required bool isColdStart,
  }) async {
    if (!mounted) return;

    final biometricsEnabled =
        ref.read(biometricsEnabledProvider).value ?? false;
    if (!biometricsEnabled || kIsWeb) {
      if (_isLocked && mounted) {
        setState(() => _isLocked = false);
      }
      return;
    }

    final now = DateTime.now();
    final shouldLockByTimeout =
        _lastPausedAt != null &&
        now.difference(_lastPausedAt!) >= _inactivityTimeout;
    final shouldLockByColdStart = isColdStart && !_didColdStartCheck;
    _didColdStartCheck = true;

    if (!shouldLockByColdStart && !shouldLockByTimeout) return;

    if (mounted) {
      setState(() => _isLocked = true);
    }
    await _authenticateAndUnlock();
  }

  Future<void> _authenticateAndUnlock() async {
    if (!mounted || _isAuthenticating) return;
    _isAuthenticating = true;

    try {
      final auth = LocalAuthentication();
      final canAuth = await auth.canCheckBiometrics;
      final isSupported = await auth.isDeviceSupported();

      if (!canAuth || !isSupported) {
        return;
      }

      final ok = await auth.authenticate(
        localizedReason:
            AppLocalizations.of(context)?.biometricReason ??
            'Bitte authentifizieren Sie sich',
      );

      if (ok && mounted) {
        setState(() => _isLocked = false);
        await _ensureOnboardingCompleted();
      }
    } catch (_) {
      // Keep locked on failure.
    } finally {
      _isAuthenticating = false;
    }
  }

  Future<void> _ensureOnboardingCompleted() async {
    if (!mounted || _isLocked || _isOnboardingRunning) return;

    final getSetting = ref.read(getSettingProvider);
    final updateSetting = ref.read(updateSettingProvider);

    final onboardingCompleted =
        (await getSetting.call('onboarding_completed')) == 'true';
    final onboardingVersion = await getSetting.call('onboarding_version');
    final needsOnboarding =
        !onboardingCompleted || onboardingVersion != _requiredOnboardingVersion;
    if (!needsOnboarding || !mounted) {
      return;
    }

    _isOnboardingRunning = true;
    try {
      final localeSetting =
          await getSetting.call('locale') ??
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      final themeSetting = await getSetting.call('theme_mode') ?? 'system';

      final result = await _showOnboardingDialog(
        localeCode: localeSetting == 'en' ? 'en' : 'de',
        themeMode: _normalizeThemeMode(themeSetting),
      );

      if (!mounted || result == null) return;

      await updateSetting.call('locale', result.localeCode);
      await updateSetting.call('theme_mode', result.themeMode);

      if (result.importDefaultCategories) {
        final db = ref.read(databaseProvider);
        final hasCategories = (await db.getAllCategories()).isNotEmpty;
        if (!hasCategories) {
          await _seedDefaultCategories(db, result.localeCode);
        }
      }

      await updateSetting.call(
        'onboarding_version',
        _requiredOnboardingVersion,
      );
      await updateSetting.call('onboarding_completed', 'true');
    } finally {
      _isOnboardingRunning = false;
    }
  }

  Future<void> _seedDefaultCategories(AppDatabase db, String localeCode) async {
    final assetPath = localeCode == 'en'
        ? 'assets/default_categories/en_defaults.json'
        : 'assets/default_categories/de_defaults.json';
    final jsonString = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    final categories = decoded['categories'];
    if (categories is! List) return;

    for (var parentIndex = 0; parentIndex < categories.length; parentIndex++) {
      final parentJson = categories[parentIndex];
      if (parentJson is! Map<String, dynamic>) continue;

      final parentName = (parentJson['name'] as String?)?.trim();
      if (parentName == null || parentName.isEmpty) continue;

      final parentIcon =
          (parentJson['icon_name'] as String?)?.trim().isNotEmpty == true
          ? parentJson['icon_name'] as String
          : 'category';
      final parentColor = _parseColorValue(parentJson['color_value']);

      final parentId = await db.insertCategory(
        CategoriesCompanion.insert(
          name: parentName,
          iconName: Value(parentIcon),
          colorValue: Value(parentColor),
          sortOrder: Value(parentIndex),
          createdAt: Value(DateTime.now()),
        ),
      );

      final subcategories = parentJson['subcategories'];
      if (subcategories is! List) continue;

      for (var subIndex = 0; subIndex < subcategories.length; subIndex++) {
        final subJson = subcategories[subIndex];
        if (subJson is! Map<String, dynamic>) continue;

        final subName = (subJson['name'] as String?)?.trim();
        if (subName == null || subName.isEmpty) continue;

        final subIcon =
            (subJson['icon_name'] as String?)?.trim().isNotEmpty == true
            ? subJson['icon_name'] as String
            : parentIcon;

        await db.insertCategory(
          CategoriesCompanion.insert(
            name: subName,
            parentId: Value(parentId),
            iconName: Value(subIcon),
            colorValue: Value(parentColor),
            sortOrder: Value(subIndex),
            createdAt: Value(DateTime.now()),
          ),
        );
      }
    }
  }

  int _parseColorValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0xFF9E9E9E;
  }

  String _normalizeThemeMode(String value) {
    if (value == 'light' || value == 'dark') return value;
    return 'system';
  }

  Future<_OnboardingResult?> _showOnboardingDialog({
    required String localeCode,
    required String themeMode,
  }) {
    var selectedLocale = localeCode;
    var selectedTheme = themeMode;
    var importDefaults = true;

    String t(String de, String en) {
      return selectedLocale == 'en' ? en : de;
    }

    return showDialog<_OnboardingResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(t('Einrichtung', 'Setup')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t(
                        'Bitte waehle Sprache, Theme und Standardkategorien.',
                        'Please choose language, theme, and default categories.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t('Sprache', 'Language'),
                      style: Theme.of(ctx).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment<String>(
                          value: 'de',
                          label: Text('Deutsch'),
                        ),
                        ButtonSegment<String>(
                          value: 'en',
                          label: Text('English'),
                        ),
                      ],
                      selected: {selectedLocale},
                      onSelectionChanged: (selection) {
                        setDialogState(() {
                          selectedLocale = selection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t('Theme', 'Theme'),
                      style: Theme.of(ctx).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment<String>(
                          value: 'system',
                          label: Text(t('System', 'System')),
                        ),
                        ButtonSegment<String>(
                          value: 'light',
                          label: Text(t('Hell', 'Light')),
                        ),
                        ButtonSegment<String>(
                          value: 'dark',
                          label: Text(t('Dunkel', 'Dark')),
                        ),
                      ],
                      selected: {selectedTheme},
                      onSelectionChanged: (selection) {
                        setDialogState(() {
                          selectedTheme = selection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      value: importDefaults,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        t(
                          'Standardkategorien hinzufuegen',
                          'Add default categories',
                        ),
                      ),
                      subtitle: Text(
                        t(
                          'Importiert Kategorien mit passenden Unterkategorien.',
                          'Imports categories with matching subcategories.',
                        ),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          importDefaults = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(
                      _OnboardingResult(
                        localeCode: selectedLocale,
                        themeMode: selectedTheme,
                        importDefaultCategories: importDefaults,
                      ),
                    );
                  },
                  child: Text(t('Weiter', 'Continue')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeAsync = ref.watch(themeModeSettingProvider);
    final localeAsync = ref.watch(localeSettingProvider);
    final biometricsEnabled =
        ref.watch(biometricsEnabledProvider).value ?? false;

    final themeModeStr = themeAsync.value ?? 'system';
    final themeMode = switch (themeModeStr) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    final localeStr = localeAsync.value ?? 'de';
    final locale = Locale(localeStr);

    return MaterialApp.router(
      title: 'SpendingLog',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: appRouter,
      builder: (context, child) {
        if (!biometricsEnabled || !_isLocked || kIsWeb) {
          return child ?? const SizedBox.shrink();
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            child ?? const SizedBox.shrink(),
            ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)?.biometricAuth ??
                            'Biometrische Authentifizierung',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)?.biometricReason ??
                            'Bitte authentifizieren Sie sich',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _isAuthenticating
                            ? null
                            : () => _authenticateAndUnlock(),
                        icon: const Icon(Icons.fingerprint),
                        label: Text(
                          _isAuthenticating
                              ? 'Authentifizierung...'
                              : (AppLocalizations.of(context)?.biometricAuth ??
                                    'Authentifizieren'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OnboardingResult {
  final String localeCode;
  final String themeMode;
  final bool importDefaultCategories;

  const _OnboardingResult({
    required this.localeCode,
    required this.themeMode,
    required this.importDefaultCategories,
  });
}
