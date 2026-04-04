import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_hand_suggester/services/theme_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeService', () {
    test('default theme mode is system', () async {
      final service = await ThemeService.create();
      expect(service.themeMode, ThemeMode.system);
    });

    test('isDark returns false for system default', () async {
      final service = await ThemeService.create();
      expect(service.isDark, isFalse);
    });

    test('toggleTheme switches from system to dark', () async {
      final service = await ThemeService.create();
      await service.toggleTheme();
      expect(service.themeMode, ThemeMode.dark);
      expect(service.isDark, isTrue);
    });

    test('toggleTheme switches from dark back to light', () async {
      final service = await ThemeService.create();
      await service.toggleTheme(); // system → dark
      await service.toggleTheme(); // dark → light
      expect(service.themeMode, ThemeMode.light);
      expect(service.isDark, isFalse);
    });

    test('setThemeMode sets explicit mode', () async {
      final service = await ThemeService.create();
      await service.setThemeMode(ThemeMode.dark);
      expect(service.themeMode, ThemeMode.dark);
    });

    test('setThemeMode is a no-op when mode is already set', () async {
      final service = await ThemeService.create();
      var notified = false;
      service.addListener(() => notified = true);
      await service.setThemeMode(ThemeMode.system);
      expect(notified, isFalse);
    });

    test('persists theme mode across instances', () async {
      final first = await ThemeService.create();
      await first.setThemeMode(ThemeMode.dark);

      // Second instance reads same SharedPreferences.
      final second = await ThemeService.create();
      expect(second.themeMode, ThemeMode.dark);
    });

    test('systemDefault returns system theme without loading prefs', () {
      final service = ThemeService.systemDefault();
      expect(service.themeMode, ThemeMode.system);
    });

    test('notifies listeners on theme change', () async {
      final service = await ThemeService.create();
      var callCount = 0;
      service.addListener(() => callCount++);
      await service.toggleTheme();
      expect(callCount, 1);
    });
  });
}
