import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import 'package:spending_log/l10n/generated/app_localizations.dart';
import 'package:spending_log/app/theme.dart';

/// Wraps a [widget] in the necessary MaterialApp + ProviderScope
/// for testing, with localization support and optional provider overrides.
Widget buildTestApp(
  Widget widget, {
  List<Override> overrides = const [],
  Locale locale = const Locale('de'),
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: widget,
      theme: buildLightTheme(),
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}
