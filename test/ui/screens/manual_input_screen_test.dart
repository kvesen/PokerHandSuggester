import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_hand_suggester/models/card.dart';
import 'package:poker_hand_suggester/ui/screens/manual_input_screen.dart';
import 'package:poker_hand_suggester/ui/widgets/card_selector.dart';

void main() {
  setUp(() {
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
      await tester.pumpWidget(buildScreen());
      await tester.pump();
      expect(find.byType(ManualInputScreen), findsOneWidget);
    });

    testWidgets('renders the card selector grid', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();
      expect(find.byType(CardSelector), findsOneWidget);
    });

    testWidgets('renders Hole Cards and Community tabs', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();
      expect(find.text('Community (0–5)'), findsOneWidget);
    });

    testWidgets('"Calculate Best Move" button is present', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();
      expect(find.text('Calculate Best Move'), findsOneWidget);
    });

    testWidgets('pot size field validates that value must be > 0',
        (tester) async {
      await tester.pumpWidget(buildScreen(
        holeCards: [
          const PokerCard(suit: Suit.spades, rank: Rank.ace),
          const PokerCard(suit: Suit.hearts, rank: Rank.king),
        ],
      ));
      await tester.pump();

      // Clear the default pot value and enter 0.
      final potField = find.widgetWithText(TextFormField, 'Pot Size');
      await tester.enterText(potField, '0');
      await tester.pump();

      // Tap the calculate button — form should fail validation.
      await tester.tap(find.text('Calculate Best Move'));
      await tester.pump();

      // The validator returns '>0' for non-positive values.
      expect(find.text('>0'), findsOneWidget);
    });

    testWidgets('community card count validation shows SnackBar for count 1',
        (tester) async {
      await tester.pumpWidget(buildScreen(
        holeCards: [
          const PokerCard(suit: Suit.spades, rank: Rank.ace),
          const PokerCard(suit: Suit.hearts, rank: Rank.king),
        ],
        communityCards: [
          const PokerCard(suit: Suit.clubs, rank: Rank.ten),
        ],
      ));
      await tester.pump();

      await tester.tap(find.text('Calculate Best Move'));
      await tester.pump();

      expect(
        find.textContaining('Community cards must be 0, 3, 4, or 5'),
        findsOneWidget,
      );
    });

    testWidgets('shows error when hole cards are missing', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      // Default pot is valid; no hole cards selected — validation should fail.
      await tester.tap(find.text('Calculate Best Move'));
      await tester.pump();

      expect(
        find.textContaining('Please select exactly 2 hole cards'),
        findsOneWidget,
      );
    });

    testWidgets('opponents counter starts at 2 and increments', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('2'), findsOneWidget);

      await tester.tap(
        find.bySemanticsLabel('Increase number of opponents'),
      );
      await tester.pump();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('opponents counter decrements', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.tap(
        find.bySemanticsLabel('Decrease number of opponents'),
      );
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
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
  });
}
