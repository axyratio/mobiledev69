import 'package:flutter/material.dart';

/// Light/dark [ThemeData] shared across the whole app.
///
/// FR-17/18 (a manual Dark Mode toggle with a persisted preference) is an
/// Extra Feature not wired up yet — for now both themes are registered on
/// [MaterialApp] and the platform's brightness picks between them.
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true);

  static ThemeData get dark => ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      );
}
