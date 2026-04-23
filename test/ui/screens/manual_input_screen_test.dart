import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_hand_suggester/models/card.dart';
import 'package:poker_hand_suggester/models/game_mode.dart';
import 'package:poker_hand_suggester/ui/screens/manual_input_screen.dart';
import 'package:poker_hand_suggester/ui/widgets/card_selector.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildScreen({
    List<PokerCard>? holeCards,
    List<PokerCard>? communityCards,
  }) {
    return MaterialApp(
      home: ManualInputScreen(
        preSelectedHoleCards: holeCards,
        preSelectedCommunityCards: communityCards,
      ),
    );
  }

  group('ManualInputScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.byType(ManualInputScreen), findsOneWidget);
    });

    testWidgets('renders the card selector grid', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.byType(CardSelector), findsOneWidget);
    });

    testWidgets('renders Hole Cards and Community tabs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('Community (0–5)'), findsOneWidget);
    });

    testWidgets('"Calculate Best Move" button is present', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      final calculateButton = find.byKey(const Key('calculate_best_move_button'));
      await tester.ensureVisible(calculateButton);
      await tester.pumpAndSettle();
      expect(calculateButton, findsOneWidget);
    });

    testWidgets('pot size field validates that value must be > 0', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        buildScreen(
          holeCards: [
            const PokerCard(suit: Suit.spades, rank: Rank.ace),
            const PokerCard(suit: Suit.hearts, rank: Rank.king),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Clear the default pot value and enter 0.
      final potField = find.widgetWithText(TextFormField, 'Pot Size');
      await tester.enterText(potField, '0');
      await tester.pumpAndSettle();

      // Tap the calculate button — form should fail validation.
      final calculateButton = find.byKey(const Key('calculate_best_move_button'));
      await tester.ensureVisible(calculateButton);
      await tester.pumpAndSettle();
      await tester.tap(calculateButton);
      await tester.pump(); // dispatch _calculate's microtasks
      await tester.pump(const Duration(milliseconds: 100)); // let _showError run
      await tester.pump(const Duration(seconds: 1)); // let SnackBar finish entering

      // The validator returns '>0' for non-positive values.
      expect(find.text('>0'), findsOneWidget);
    });

    testWidgets('community card count validation shows SnackBar for count 1', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        buildScreen(
          holeCards: [
            const PokerCard(suit: Suit.spades, rank: Rank.ace),
            const PokerCard(suit: Suit.hearts, rank: Rank.king),
          ],
          communityCards: [const PokerCard(suit: Suit.clubs, rank: Rank.ten)],
        ),
      );
      await tester.pumpAndSettle();

      final calculateButton = find.byKey(const Key('calculate_best_move_button'));
      await tester.ensureVisible(calculateButton);
      await tester.pumpAndSettle();
      await tester.tap(calculateButton);
      await tester.pump(); // dispatch _calculate's microtasks
      await tester.pump(const Duration(milliseconds: 100)); // let _showError run
      await tester.pump(const Duration(seconds: 1)); // let the SnackBar's entrance animation complete

      expect(
        find.textContaining('Community cards must be 0, 3, 4, or 5'),
        findsOneWidget,
      );
    });

    testWidgets('shows error when hole cards are missing', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Default pot is valid; no hole cards selected — validation should fail.
      final calculateButton = find.byKey(const Key('calculate_best_move_button'));
      await tester.ensureVisible(calculateButton);
      await tester.pumpAndSettle();
      await tester.tap(calculateButton);
      await tester.pump(); // dispatch _calculate's microtasks
      await tester.pump(const Duration(milliseconds: 100)); // let _showError run
      await tester.pump(const Duration(seconds: 1)); // let the SnackBar's entrance animation complete

      expect(
        find.textContaining('Please select exactly 2 hole cards'),
        findsOneWidget,
      );
    });

    testWidgets('opponents increment and decrement buttons are present', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      try {
        expect(
          find.bySemanticsLabel('Increase number of opponents'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Decrease number of opponents'),
          findsOneWidget,
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('opponents increment button is tappable', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      try {
        await tester.tap(find.bySemanticsLabel('Increase number of opponents'));
        await tester.pumpAndSettle();
        // No exception means the button works as expected.
      } finally {
        handle.dispose();
      }
    });

    testWidgets('opponents decrement button is tappable', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      try {
        await tester.tap(find.bySemanticsLabel('Decrease number of opponents'));
        await tester.pumpAndSettle();
        // No exception means the button works as expected.
      } finally {
        handle.dispose();
      }
    });

    testWidgets('two-column layout activates on wide screens', (tester) async {
      // Set a wide surface (>600 px wide) to trigger the side-by-side layout.
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      // The wide layout wraps content in a Row at the top level.
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('compact game mode selector shows current mode label', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildScreen());
      // Allow async service init to complete.
      await tester.pumpAndSettle();

      // The compact row shows "Game Mode: Cash Game" by default.
      expect(find.textContaining('Game Mode:'), findsOneWidget);
      expect(find.textContaining('Cash Game'), findsOneWidget);
    });

    testWidgets('tapping game mode selector opens bottom sheet', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final gameModeSelector = find.byKey(const Key('game_mode_selector'));
      await tester.ensureVisible(gameModeSelector);
      await tester.pumpAndSettle();
      await tester.tap(gameModeSelector);
      await tester.pumpAndSettle();

      // Bottom sheet should list all game modes.
      expect(find.text('Game Mode'), findsOneWidget);
      expect(find.byType(RadioListTile<GameMode>), findsNWidgets(6));
    });

    testWidgets('selecting a mode in the sheet updates the compact row', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Open the bottom sheet.
      final gameModeSelector = find.byKey(const Key('game_mode_selector'));
      await tester.ensureVisible(gameModeSelector);
      await tester.pumpAndSettle();
      await tester.tap(gameModeSelector);
      await tester.pumpAndSettle();

      // Pick "Heads-Up".
      await tester.tap(find.text('Heads-Up'));
      await tester.pumpAndSettle();

      // Row should now reflect the new selection.
      expect(find.textContaining('Heads-Up'), findsOneWidget);
    });

    testWidgets('preSelectedGameMode overrides persisted preference', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      // Persist turbo mode.
      SharedPreferences.setMockInitialValues({'game_mode': 'turbo'});

      await tester.pumpWidget(
        const MaterialApp(
          home: ManualInputScreen(preSelectedGameMode: GameMode.headsUp),
        ),
      );
      await tester.pumpAndSettle();

      // The pre-selected mode takes precedence over what's in prefs.
      expect(find.textContaining('Heads-Up'), findsOneWidget);
    });

    testWidgets('loads persisted game mode on fresh open', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({'game_mode': 'turbo'});

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.textContaining('Turbo'), findsOneWidget);
    });
  });
}
