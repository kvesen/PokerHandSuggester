/// Centralised Material 3 theme definitions.
library;

import 'package:flutter/material.dart';

/// Provides light and dark [ThemeData] instances for the app.
abstract final class AppTheme {
  /// Primary seed color -- deep poker-felt green.
  static const Color _seed = Color(0xFF1B5E3B);

  static ThemeData light() => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      );

  static ThemeData dark() => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      );
}
