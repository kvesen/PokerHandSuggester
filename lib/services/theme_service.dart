/// Theme service: persists and provides the app theme mode.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeKey = 'theme_mode';

/// A [ChangeNotifier] that manages the app's [ThemeMode] and persists it via
/// [SharedPreferences].
class ThemeService extends ChangeNotifier {
  ThemeService._();

  ThemeMode _themeMode = ThemeMode.system;

  /// Current theme mode.
  ThemeMode get themeMode => _themeMode;

  /// Whether dark mode is currently active (or system-preferred dark).
  bool get isDark => _themeMode == ThemeMode.dark;

  /// Creates and initialises a [ThemeService] instance.
  ///
  /// If the preference cannot be loaded (e.g. [SharedPreferences] unavailable),
  /// the service falls back to [ThemeMode.system] silently.
  static Future<ThemeService> create() async {
    final service = ThemeService._();
    try {
      await service._load();
    } catch (e, st) {
      debugPrint(
        'ThemeService: failed to load theme preference — '
        'defaulting to system\n$e\n$st',
      );
    }
    return service;
  }

  /// Creates a [ThemeService] with [ThemeMode.system] without loading from
  /// [SharedPreferences]. Used as a fallback when initialisation fails.
  static ThemeService systemDefault() => ThemeService._();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kThemeKey);
    if (stored != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == stored,
        orElse: () => ThemeMode.system,
      );
    }
  }

  /// Toggles between light and dark mode.
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    notifyListeners();
    await _persist();
  }

  /// Sets an explicit [ThemeMode].
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, _themeMode.name);
  }
}
