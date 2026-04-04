import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poker_hand_suggester/models/card.dart';
import 'package:poker_hand_suggester/ui/widgets/card_selector.dart';
import 'package:poker_hand_suggester/ui/widgets/card_widget.dart';

void main() {
  Widget buildSelector({
    List<PokerCard> selected = const [],
    void Function(PokerCard)? onToggled,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CardSelector(
            selectedCards: selected,
            onCardToggled: onToggled ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('CardSelector', () {
    testWidgets('renders all 52 cards', (tester) async {
      await tester.pumpWidget(buildSelector());
      await tester.pump();

      // 52 CardWidget instances from the grid (plus 0 selected chips).
      final cards = tester.widgetList<CardWidget>(find.byType(CardWidget));
      expect(cards.length, 52);
    });

    testWidgets('selected cards are visually distinct (selected=true)', (tester) async {
      const selected = [PokerCard(suit: Suit.spades, rank: Rank.ace)];
      await tester.pumpWidget(buildSelector(selected: selected));
      await tester.pump();

      final cardWidgets = tester.widgetList<CardWidget>(find.byType(CardWidget)).toList();
      final selectedWidget = cardWidgets.firstWhere(
        (w) => w.card == selected.first,
      );
      expect(selectedWidget.selected, isTrue);
    });

    testWidgets('non-selected cards have selected=false', (tester) async {
      const selected = [PokerCard(suit: Suit.spades, rank: Rank.ace)];
      await tester.pumpWidget(buildSelector(selected: selected));
      await tester.pump();

      final cardWidgets = tester.widgetList<CardWidget>(find.byType(CardWidget)).toList();
      final unselected = cardWidgets.firstWhere(
        (w) => w.card != selected.first,
      );
      expect(unselected.selected, isFalse);
    });

    testWidgets('tapping a card triggers onCardToggled', (tester) async {
      PokerCard? toggled;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CardSelector(
                selectedCards: const [],
                onCardToggled: (card) => toggled = card,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap the first card widget that has a tap handler (onTap != null).
      final firstTappable = find.byWidgetPredicate(
        (w) => w is CardWidget && w.onTap != null,
      );
      await tester.tap(firstTappable.first);
      await tester.pump();

      expect(toggled, isNotNull);
    });

    testWidgets('grid has a Semantics label', (tester) async {
      await tester.pumpWidget(buildSelector());
      await tester.pump();

      expect(
        find.bySemanticsLabel('Card selection grid'),
        findsOneWidget,
      );
    });

    testWidgets('text input field is rendered', (tester) async {
      await tester.pumpWidget(buildSelector());
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
