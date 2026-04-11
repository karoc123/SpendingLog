import 'package:flutter/material.dart';

const _defaultThemeId = 'classic';

class AppThemePalette {
  final Color seedColor;
  final Color? lightScaffold;
  final Color? darkScaffold;
  final Color? darkSurface;
  final Color? darkSurfaceLow;
  final Color? darkSurfaceBase;
  final Color? darkSurfaceHigh;
  final Color? darkSurfaceHighest;

  const AppThemePalette({
    required this.seedColor,
    this.lightScaffold,
    this.darkScaffold,
    this.darkSurface,
    this.darkSurfaceLow,
    this.darkSurfaceBase,
    this.darkSurfaceHigh,
    this.darkSurfaceHighest,
  });
}

const _themePalettes = <String, AppThemePalette>{
  _defaultThemeId: AppThemePalette(
    seedColor: Color(0xFF2E7D32),
    darkScaffold: Color(0xFF000000),
    darkSurface: Color(0xFF000000),
    darkSurfaceLow: Color(0xFF111111),
    darkSurfaceBase: Color(0xFF161616),
    darkSurfaceHigh: Color(0xFF1B1B1B),
    darkSurfaceHighest: Color(0xFF202020),
  ),
};

ThemeData buildLightTheme([String themeId = _defaultThemeId]) {
  final palette = _themePalettes[themeId] ?? _themePalettes[_defaultThemeId]!;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: palette.seedColor,
    brightness: Brightness.light,
  );
  return _buildTheme(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: palette.lightScaffold,
  );
}

ThemeData buildDarkTheme([String themeId = _defaultThemeId]) {
  final palette = _themePalettes[themeId] ?? _themePalettes[_defaultThemeId]!;
  final base = ColorScheme.fromSeed(
    seedColor: palette.seedColor,
    brightness: Brightness.dark,
  );
  final colorScheme = base.copyWith(
    surface: palette.darkSurface,
    surfaceContainerLowest: palette.darkSurface,
    surfaceContainerLow: palette.darkSurfaceLow,
    surfaceContainer: palette.darkSurfaceBase,
    surfaceContainerHigh: palette.darkSurfaceHigh,
    surfaceContainerHighest: palette.darkSurfaceHighest,
  );
  return _buildTheme(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: palette.darkScaffold,
    navigationBarBackground: palette.darkScaffold,
    canvasColor: palette.darkScaffold,
  );
}

ThemeData _buildTheme({
  required ColorScheme colorScheme,
  Color? scaffoldBackgroundColor,
  Color? canvasColor,
  Color? navigationBarBackground,
}) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: scaffoldBackgroundColor,
    canvasColor: canvasColor,
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: navigationBarBackground,
    ),
  );
}
