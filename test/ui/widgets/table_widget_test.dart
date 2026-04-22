import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poker_hand_suggester/models/card.dart';
import 'package:poker_hand_suggester/ui/widgets/table_widget.dart';
import 'package:poker_hand_suggester/ui/widgets/card_widget.dart';

void main() {
  const holeCards = [
    PokerCard(suit: Suit.spades, rank: Rank.ace),
    PokerCard(suit: Suit.hearts, rank: Rank.king),
  ];

  const communityCards = [
    PokerCard(suit: Suit.clubs, rank: Rank.ten),
    PokerCard(suit: Suit.diamonds, rank: Rank.jack),
    PokerCard(suit: Suit.hearts, rank: Rank.queen),
  ];

  Widget buildTable({
    List<PokerCard> hole = holeCards,
    List<PokerCard> community = const [],
    double pot = 100,
    int opponents = 2,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 270,
          child: PokerTableWidget(
            holeCards: hole,
            communityCards: community,
            numberOfOpponents: opponents,
            potSize: pot,
          ),
        ),
      ),
    );
  }

  group('PokerTableWidget', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(buildTable());
      await tester.pumpAndSettle();
      expect(find.byType(PokerTableWidget), findsOneWidget);
    });

    testWidgets('displays hole cards', (tester) async {
      await tester.pumpWidget(buildTable());
      await tester.pumpAndSettle();
      // The hole cards are rendered as CardWidgets.
      expect(find.byType(CardWidget), findsWidgets);
    });

    testWidgets('displays community cards when provided', (tester) async {
      await tester.pumpWidget(buildTable(community: communityCards));
      await tester.pumpAndSettle();
      // With community cards there are more CardWidgets (hole + community).
      final cardWidgets = tester.widgetList<CardWidget>(find.byType(CardWidget));
      expect(cardWidgets.length, greaterThanOrEqualTo(communityCards.length));
    });

    testWidgets('displays pot size', (tester) async {
      await tester.pumpWidget(buildTable(pot: 250));
      await tester.pumpAndSettle();
      expect(find.text('250'), findsOneWidget);
    });

    testWidgets('displays zero pot size', (tester) async {
      await tester.pumpWidget(buildTable(pot: 0));
      await tester.pumpAndSettle();
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('renders opponent seat labels', (tester) async {
      await tester.pumpWidget(buildTable(opponents: 3));
      await tester.pumpAndSettle();
      // Each opponent is shown as an OPP seat.
      expect(find.textContaining('OPP'), findsWidgets);
    });
  });
}
