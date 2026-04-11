import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../core/providers/core_providers.dart';
import '../l10n/generated/app_localizations.dart';
import 'router.dart';
import 'theme.dart';

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
      }
    } catch (_) {
      // Keep locked on failure.
    } finally {
      _isAuthenticating = false;
    }
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
