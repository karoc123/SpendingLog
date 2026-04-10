import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../l10n/generated/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currencySymbol = ref.watch(currencySymbolProvider).value ?? '€';
    final locale = ref.watch(localeSettingProvider).value ?? 'de';
    final biometrics =
        ref.watch(biometricsEnabledProvider).value ?? false;
    final themeMode =
        ref.watch(themeModeSettingProvider).value ?? 'system';

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.settings ?? 'Einstellungen')),
      body: ListView(
        children: [
          // -- Appearance section --
          _SectionHeader(l10n?.appearance ?? 'Erscheinungsbild'),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: Text(l10n?.themeMode ?? 'Design'),
            subtitle: Text(_themeModeLabel(themeMode, l10n)),
            onTap: () => _showThemePicker(context, ref, themeMode),
          ),

          // -- Language section --
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n?.language ?? 'Sprache'),
            subtitle: Text(locale == 'de' ? 'Deutsch' : 'English'),
            onTap: () => _showLanguagePicker(context, ref, locale),
          ),

          // -- Currency section --
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: Text(l10n?.currency ?? 'Währung'),
            subtitle: Text(currencySymbol),
            onTap: () => _showCurrencyPicker(context, ref),
          ),

          const Divider(),

          // -- Security section --
          _SectionHeader(l10n?.security ?? 'Sicherheit'),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: Text(
              l10n?.biometricAuth ?? 'Biometrische Authentifizierung',
            ),
            subtitle: Text(
              kIsWeb
                  ? (l10n?.biometricsUnavailableWeb ??
                        'Auf Web nicht verfügbar')
                  : (biometrics
                        ? (l10n?.enabled ?? 'Aktiviert')
                        : (l10n?.disabled ?? 'Deaktiviert')),
            ),
            value: biometrics,
            onChanged: kIsWeb
                ? null
                : (value) => _toggleBiometrics(context, ref, value),
          ),

          const Divider(),

          // -- Data section --
          _SectionHeader(l10n?.data ?? 'Daten'),
          ListTile(
            leading: const Icon(Icons.category),
            title: Text(l10n?.manageCategories ?? 'Kategorien verwalten'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/categories'),
          ),
          ListTile(
            leading: const Icon(Icons.import_export),
            title: Text(l10n?.exportImport ?? 'Export / Import'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/export'),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(String mode, AppLocalizations? l10n) {
    switch (mode) {
      case 'light':
        return l10n?.light ?? 'Hell';
      case 'dark':
        return l10n?.dark ?? 'Dunkel';
      default:
        return l10n?.system ?? 'System';
    }
  }

  void _showThemePicker(BuildContext context, WidgetRef ref, String current) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n?.themeMode ?? 'Design'),
        children: [
          for (final mode in ['system', 'light', 'dark'])
            ListTile(
              title: Text(_themeModeLabel(mode, l10n)),
              leading: Icon(
                mode == current
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              onTap: () async {
                await ref.read(updateSettingProvider).call('theme_mode', mode);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
        ],
      ),
    );
  }

  void _showLanguagePicker(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) {
    final l10n = AppLocalizations.of(context);
    final languages = [('de', 'Deutsch'), ('en', 'English')];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n?.language ?? 'Sprache'),
        children: [
          for (final lang in languages)
            ListTile(
              title: Text(lang.$2),
              leading: Icon(
                lang.$1 == current
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              onTap: () async {
                await ref.read(updateSettingProvider).call('locale', lang.$1);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
        ],
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, WidgetRef ref) {
    final currencies = [
      ('EUR', '€'),
      ('USD', '\$'),
      ('GBP', '£'),
      ('CHF', 'CHF'),
      ('JPY', '¥'),
    ];
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n?.currency ?? 'Währung'),
        children: currencies.map((c) {
          return SimpleDialogOption(
            onPressed: () async {
              await ref.read(updateSettingProvider).call('currency', c.$1);
              await ref
                  .read(updateSettingProvider)
                  .call('currency_symbol', c.$2);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('${c.$2}  (${c.$1})'),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _toggleBiometrics(
    BuildContext context,
    WidgetRef ref,
    bool enable,
  ) async {
    if (enable) {
      final auth = LocalAuthentication();
      try {
        final canAuth = await auth.canCheckBiometrics;
        final isDeviceSupported = await auth.isDeviceSupported();
        if (!canAuth || !isDeviceSupported) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)?.biometricsNotAvailable ??
                      'Biometrische Authentifizierung nicht verfügbar',
                ),
              ),
            );
          }
          return;
        }
        final authenticated = await auth.authenticate(
          localizedReason:
              AppLocalizations.of(context)?.biometricReason ??
              'Biometrie aktivieren',
        );
        if (!authenticated) return;
      } catch (_) {
        return;
      }
    }
    await ref
        .read(updateSettingProvider)
        .call('biometrics_enabled', enable.toString());
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
