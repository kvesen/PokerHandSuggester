import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_hand_suggester/engine/decision_engine.dart';
import 'package:poker_hand_suggester/engine/equity_calculator.dart';
import 'package:poker_hand_suggester/models/card.dart';
import 'package:poker_hand_suggester/models/game_state.dart';
import 'package:poker_hand_suggester/services/theme_service.dart';
import 'package:poker_hand_suggester/ui/screens/home_screen.dart';
import 'package:poker_hand_suggester/ui/screens/manual_input_screen.dart';
import 'package:poker_hand_suggester/ui/screens/results_screen.dart';
import 'package:poker_hand_suggester/ui/widgets/card_selector.dart';
import 'package:poker_hand_suggester/ui/widgets/card_widget.dart';
import 'package:poker_hand_suggester/widgets/card_tile.dart';
import 'package:poker_hand_suggester/widgets/suggestion_card.dart';

void main() {
  group('Home screen', () {
    late Directory tempDir;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(tempDir.path);
    });

    tearDown(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    testWidgets('renders without throwing and shows heading', (tester) async {
      final themeService = await ThemeService.create();
      await tester.pumpWidget(
        MaterialApp(home: HomeScreen(themeService: themeService)),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Heading is present.
      expect(find.text('Poker\nBuddy'), findsOneWidget);
      // Primary action button is present.
      expect(find.text('Manual Input'), findsOneWidget);
    });

    testWidgets('home screen meets android tap target guideline',
        (tester) async {
      final handle = tester.ensureSemantics();
      addTearDown(handle.dispose);
      final themeService = await ThemeService.create();
      await tester.pumpWidget(
        MaterialApp(home: HomeScreen(themeService: themeService)),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      await expectLater(
        tester,
        meetsGuideline(androidTapTargetGuideline),
      );
    });

    testWidgets('home screen meets iOS tap target guideline', (tester) async {
      final handle = tester.ensureSemantics();
      addTearDown(handle.dispose);
      final themeService = await ThemeService.create();
      await tester.pumpWidget(
        MaterialApp(home: HomeScreen(themeService: themeService)),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      await expectLater(
        tester,
        meetsGuideline(iOSTapTargetGuideline),
      );
    });

    testWidgets('home screen meets labeled tap target guideline',
        (tester) async {
      final handle = tester.ensureSemantics();
      addTearDown(handle.dispose);
      final themeService = await ThemeService.create();
      await tester.pumpWidget(
        MaterialApp(home: HomeScreen(themeService: themeService)),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      await expectLater(
        tester,
        meetsGuideline(labeledTapTargetGuideline),
      );
    });
  });

  group('Card picker', () {
    testWidgets('card selector renders all 52 cards', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CardSelector(
                selectedCards: const [],
                onCardToggled: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.widgetList<CardWidget>(find.byType(CardWidget)).length, 52);
    });

    testWidgets('selecting a card triggers onCardToggled callback',
        (tester) async {
      PokerCard? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CardSelector(
                selectedCards: const [],
                onCardToggled: (c) => selected = c,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tappable = find.byWidgetPredicate(
        (w) => w is CardWidget && w.onTap != null,
      );
      await tester.tap(tappable.first);
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
    });

    testWidgets('already-selected card is shown as selected', (tester) async {
      const card = PokerCard(suit: Suit.spades, rank: Rank.ace);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CardSelector(
                selectedCards: const [card],
                onCardToggled: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardWidgets =
          tester.widgetList<CardWidget>(find.byType(CardWidget)).toList();
      final ace = cardWidgets.firstWhere((w) => w.card == card);
      expect(ace.selected, isTrue);
    });

    testWidgets('duplicate cards are disabled — disabled card has no onTap',
        (tester) async {
      // Put Ace of Spades in disabled list (already used elsewhere).
      const usedCard = PokerCard(suit: Suit.spades, rank: Rank.ace);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CardSelector(
                selectedCards: const [],
                disabledCards: const [usedCard],
                onCardToggled: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardWidgets =
          tester.widgetList<CardWidget>(find.byType(CardWidget)).toList();
      final disabled = cardWidgets.firstWhere((w) => w.card == usedCard);
      // Disabled card must not have an onTap handler.
      expect(disabled.onTap, isNull);
    });

    testWidgets('ManualInputScreen shows card selector on launch',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(home: ManualInputScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CardSelector), findsOneWidget);
    });
  });

  group('Suggestion card', () {
    testWidgets('SuggestionCard shows RAISE label for raise decision',
        (tester) async {
      const decision = Decision(
        action: PlayerAction.raise,
        equity: 0.65,
        potOdds: 0.17,
        expectedValue: 47.5,
        explanation: 'Strong hand.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuggestionCard(decision: decision),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('RAISE'), findsOneWidget);
    });

    testWidgets('SuggestionCard shows FOLD label for fold decision',
        (tester) async {
      const decision = Decision(
        action: PlayerAction.fold,
        equity: 0.20,
        potOdds: 0.50,
        expectedValue: -15.0,
        explanation: 'Weak hand.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuggestionCard(decision: decision),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('FOLD'), findsOneWidget);
    });

    testWidgets('suggestion updates (AnimatedSwitcher) when decision changes',
        (tester) async {
      // Start with FOLD decision on ResultsScreen.
      const holeCards = [
        PokerCard(suit: Suit.spades, rank: Rank.two),
        PokerCard(suit: Suit.hearts, rank: Rank.three),
      ];
      const gameState = GameState(
        holeCards: holeCards,
        communityCards: [],
        potSize: 100,
        betToCall: 20,
        numberOfOpponents: 2,
      );
      const foldDecision = Decision(
        action: PlayerAction.fold,
        equity: 0.20,
        potOdds: 0.17,
        expectedValue: -10.0,
        explanation: 'Weak — fold.',
      );
      const raiseDecision = Decision(
        action: PlayerAction.raise,
        equity: 0.75,
        potOdds: 0.17,
        expectedValue: 55.0,
        explanation: 'Strong — raise.',
      );
      const equity = EquityResult(
        winProbability: 0.20,
        tieProbability: 0.05,
        lossProbability: 0.75,
        iterations: 100,
      );

      SharedPreferences.setMockInitialValues({});

      // Show ResultsScreen with FOLD.
      await tester.pumpWidget(
        MaterialApp(
          home: ResultsScreen(
            gameState: gameState,
            equityResult: equity,
            decision: foldDecision,
            isSaved: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('FOLD'), findsOneWidget);

      // Rebuild with RAISE decision to verify suggestion updates.
      await tester.pumpWidget(
        MaterialApp(
          home: ResultsScreen(
            gameState: gameState,
            equityResult: equity,
            decision: raiseDecision,
            isSaved: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('RAISE'), findsOneWidget);
    });
  });

  group('CardTile widget', () {
    testWidgets('empty slot renders add icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardTile(onTap: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('filled slot renders CardWidget', (tester) async {
      const card = PokerCard(suit: Suit.hearts, rank: Rank.ace);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardTile(card: card, onTap: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CardWidget), findsOneWidget);
    });

    testWidgets('tapping CardTile calls onTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardTile(onTap: () => tapped = true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CardTile));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
