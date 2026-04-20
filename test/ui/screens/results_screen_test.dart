import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_hand_suggester/engine/decision_engine.dart';
import 'package:poker_hand_suggester/engine/equity_calculator.dart';
import 'package:poker_hand_suggester/models/card.dart';
import 'package:poker_hand_suggester/models/game_state.dart';
import 'package:poker_hand_suggester/models/position.dart';
import 'package:poker_hand_suggester/ui/screens/results_screen.dart';
import 'package:poker_hand_suggester/ui/widgets/decision_badge.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const holeCards = [
    PokerCard(suit: Suit.spades, rank: Rank.ace),
    PokerCard(suit: Suit.hearts, rank: Rank.king),
  ];

  GameState buildGameState({List<PokerCard> community = const []}) {
    return GameState(
      holeCards: holeCards,
      communityCards: community,
      potSize: 100,
      betToCall: 20,
      numberOfOpponents: 2,
    );
  }

  EquityResult buildEquityResult({double win = 0.65, double tie = 0.05}) {
    return EquityResult(
      winProbability: win,
      tieProbability: tie,
      lossProbability: 1 - win - tie,
      iterations: 1000,
    );
  }

  Decision buildDecision({PlayerAction action = PlayerAction.raise}) {
    return Decision(
      action: action,
      equity: 0.65,
      potOdds: 0.167,
      expectedValue: 47.5,
      explanation: 'Strong hand, raise for value.',
    );
  }

  Widget buildScreen({
    PlayerAction action = PlayerAction.raise,
    TablePosition? heroPosition,
  }) {
    final gameState = buildGameState();
    final equityResult = buildEquityResult();
    final decision = buildDecision(action: action);

    return MaterialApp(
      home: ResultsScreen(
        gameState: gameState,
        equityResult: equityResult,
        decision: decision,
        isSaved: false, // Avoid Hive dependency in tests.
      ),
    );
  }

  group('ResultsScreen', () {
    testWidgets('displays the RAISE decision badge', (tester) async {
      await tester.pumpWidget(buildScreen(action: PlayerAction.raise));
      await tester.pump();

      expect(find.byType(DecisionBadge), findsOneWidget);
      expect(find.text('RAISE'), findsOneWidget);
    });

    testWidgets('displays the FOLD decision badge', (tester) async {
      await tester.pumpWidget(buildScreen(action: PlayerAction.fold));
      await tester.pump();

      expect(find.text('FOLD'), findsOneWidget);
    });

    testWidgets('displays the CALL decision badge', (tester) async {
      await tester.pumpWidget(buildScreen(action: PlayerAction.call));
      await tester.pump();

      expect(find.text('CALL'), findsOneWidget);
    });

    testWidgets('shows equity stat label', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Equity'), findsOneWidget);
    });

    testWidgets('shows pot odds stat label', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Pot Odds'), findsOneWidget);
    });

    testWidgets('shows EV stat label', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('EV'), findsOneWidget);
    });

    testWidgets('displays the explanation text', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Strong hand, raise for value.'), findsOneWidget);
    });

    testWidgets('shows "Why this decision?" heading', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Why this decision?'), findsOneWidget);
    });

    testWidgets('shows Continue Hand button when not showdown', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Continue Hand'), findsOneWidget);
    });

    testWidgets('decision badge has Semantics liveRegion', (tester) async {
      await tester.pumpWidget(buildScreen(action: PlayerAction.raise));
      await tester.pump();

      expect(
        find.bySemanticsLabel('Decision: RAISE'),
        findsOneWidget,
      );
    });

    testWidgets('stats have Semantics labels', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(
        find.bySemanticsLabel(RegExp(r'^Equity:')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^Pot Odds:')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^EV:')),
        findsOneWidget,
      );
    });

    testWidgets('shows position info when hero position is in game state',
        (tester) async {
      final gameState = const GameState(
        holeCards: holeCards,
        communityCards: [],
        potSize: 100,
        betToCall: 20,
        numberOfOpponents: 2,
        heroPosition: TablePosition.button,
      );
      final equityResult = buildEquityResult();
      final decision = buildDecision();

      await tester.pumpWidget(
        MaterialApp(
          home: ResultsScreen(
            gameState: gameState,
            equityResult: equityResult,
            decision: decision,
            isSaved: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Position'), findsOneWidget);
      expect(find.text('BTN'), findsOneWidget);
    });
  });
}
