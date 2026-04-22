import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_hand_suggester/services/theme_service.dart';
import 'package:poker_hand_suggester/ui/screens/home_screen.dart';

void main() {
  late Directory _tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(_tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await _tempDir.delete(recursive: true);
  });

  group('HomeScreen', () {
    testWidgets('renders app title', (tester) async {
      final themeService = await ThemeService.create();

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(themeService: themeService),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Poker\nBuddy'), findsOneWidget);
    });

    testWidgets('renders Manual Input action button', (tester) async {
      final themeService = await ThemeService.create();

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(themeService: themeService),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Manual Input'), findsOneWidget);
    });

    testWidgets('renders version footer text', (tester) async {
      final themeService = await ThemeService.create();

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(themeService: themeService),
        ),
      );
      await tester.pumpAndSettle();

      // Before PackageInfo resolves, the footer shows just 'Texas Hold\'em'
      expect(find.text('Texas Hold\'em'), findsOneWidget);
    });
  });
}
