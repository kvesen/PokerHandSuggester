import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_hand_suggester/services/theme_service.dart';
import 'package:poker_hand_suggester/ui/screens/home_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HomeScreen', () {
    testWidgets('renders app title', (tester) async {
      final themeService = await ThemeService.create();

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(themeService: themeService),
        ),
      );
      await tester.pump();

      expect(find.text('Poker Hand\nSuggester'), findsOneWidget);
    });

    testWidgets('renders Scan Table and Manual action buttons', (tester) async {
      final themeService = await ThemeService.create();

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(themeService: themeService),
        ),
      );
      await tester.pump();

      expect(find.text('Scan Table'), findsOneWidget);
      expect(find.text('Manual'), findsOneWidget);
    });

    testWidgets('Scan Table card shows Coming Soon label', (tester) async {
      final themeService = await ThemeService.create();

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(themeService: themeService),
        ),
      );
      await tester.pump();

      expect(find.text('Coming Soon'), findsOneWidget);
    });

    testWidgets('Scan Table card shows snackbar when tapped', (tester) async {
      final themeService = await ThemeService.create();

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(themeService: themeService),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Scan Table'));
      await tester.pumpAndSettle();

      expect(find.text('Scan Table is coming soon!'), findsOneWidget);
    });

    testWidgets('renders version footer text', (tester) async {
      final themeService = await ThemeService.create();

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(themeService: themeService),
        ),
      );
      await tester.pump();

      expect(find.text('Texas Hold\'em · v1.1.0'), findsOneWidget);
    });
  });
}
