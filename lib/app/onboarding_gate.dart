import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

class OnboardingResult {
  final String localeCode;
  final String themeMode;
  final bool importDefaultCategories;

  const OnboardingResult({
    required this.localeCode,
    required this.themeMode,
    required this.importDefaultCategories,
  });
}

class OnboardingGate extends StatefulWidget {
  final String initialLocaleCode;
  final String initialThemeMode;
  final Future<void> Function(OnboardingResult result) onComplete;

  const OnboardingGate({
    super.key,
    required this.initialLocaleCode,
    required this.initialThemeMode,
    required this.onComplete,
  });

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  late String _selectedLocale;
  late String _selectedTheme;
  bool _importDefaults = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedLocale = widget.initialLocaleCode;
    _selectedTheme = widget.initialThemeMode;
  }

  AppLocalizations? get _l10n => AppLocalizations.of(context);

  String _text({
    required String deFallback,
    required String enFallback,
    String? localized,
  }) {
    if (localized != null && localized.isNotEmpty) return localized;
    return _selectedLocale == 'en' ? enFallback : deFallback;
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _text(
                      deFallback: 'Einrichtung',
                      enFallback: 'Setup',
                      localized: _l10n?.setupTitle,
                    ),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _text(
                      deFallback:
                          'Bitte waehle Sprache, Theme und Standardkategorien.',
                      enFallback:
                          'Please choose language, theme, and default categories.',
                      localized: _l10n?.setupDescription,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _l10n?.language ??
                        _text(deFallback: 'Sprache', enFallback: 'Language'),
                    style: Theme.of(context).textTheme.titleSmall,
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
                    selected: {_selectedLocale},
                    onSelectionChanged: _isSaving
                        ? null
                        : (selection) {
                            setState(() {
                              _selectedLocale = selection.first;
                            });
                          },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _l10n?.themeMode ??
                        _text(deFallback: 'Theme', enFallback: 'Theme'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment<String>(
                        value: 'system',
                        label: Text(
                          _l10n?.system ??
                              _text(deFallback: 'System', enFallback: 'System'),
                        ),
                      ),
                      ButtonSegment<String>(
                        value: 'light',
                        label: Text(
                          _l10n?.light ??
                              _text(deFallback: 'Hell', enFallback: 'Light'),
                        ),
                      ),
                      ButtonSegment<String>(
                        value: 'dark',
                        label: Text(
                          _l10n?.dark ??
                              _text(deFallback: 'Dunkel', enFallback: 'Dark'),
                        ),
                      ),
                    ],
                    selected: {_selectedTheme},
                    onSelectionChanged: _isSaving
                        ? null
                        : (selection) {
                            setState(() {
                              _selectedTheme = selection.first;
                            });
                          },
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    value: _importDefaults,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _text(
                        deFallback: 'Standardkategorien hinzufügen',
                        enFallback: 'Add default categories',
                        localized: _l10n?.addDefaultCategories,
                      ),
                    ),
                    subtitle: Text(
                      _text(
                        deFallback:
                            'Importiert Kategorien mit passenden Unterkategorien.',
                        enFallback:
                            'Imports categories with matching subcategories.',
                        localized: _l10n?.addDefaultCategoriesDescription,
                      ),
                    ),
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() {
                              _importDefaults = value ?? false;
                            });
                          },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSaving
                          ? null
                          : () async {
                              setState(() => _isSaving = true);
                              try {
                                await widget.onComplete(
                                  OnboardingResult(
                                    localeCode: _selectedLocale,
                                    themeMode: _selectedTheme,
                                    importDefaultCategories: _importDefaults,
                                  ),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _isSaving = false);
                                }
                              }
                            },
                      child: Text(
                        _isSaving
                            ? _text(
                                deFallback: 'Speichere...',
                                enFallback: 'Saving...',
                                localized: _l10n?.saving,
                              )
                            : _text(
                                deFallback: 'Weiter',
                                enFallback: 'Continue',
                                localized: _l10n?.continueLabel,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
