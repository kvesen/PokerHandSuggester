import 'package:flutter_test/flutter_test.dart';
import 'package:poker_hand_suggester/engine/decision_engine.dart';
import 'package:poker_hand_suggester/models/game_mode.dart';

void main() {
  group('DecisionEngine.decide with GameMode', () {
    // -----------------------------------------------------------------------
    // Backward compatibility — null gameMode must behave identically to the
    // existing cash game constants (kRaiseEquityMultiple=1.5, threshold=0.6).
    // -----------------------------------------------------------------------

    test('null gameMode produces same result as cashGame mode', () {
      const equity = 0.40;
      const pot = 100.0;
      const costToCall = 50.0;

      final noMode = DecisionEngine.decide(
        equity: equity,
        pot: pot,
        costToCall: costToCall,
      );
      final cashMode = DecisionEngine.decide(
        equity: equity,
        pot: pot,
        costToCall: costToCall,
        gameMode: GameMode.cashGame,
      );

      expect(noMode.action, cashMode.action);
      expect(noMode.potOdds, closeTo(cashMode.potOdds, 0.0001));
      expect(noMode.expectedValue, closeTo(cashMode.expectedValue, 0.0001));
    });

    // -----------------------------------------------------------------------
    // Tournament Bubble — very tight thresholds (raiseMultiple=1.8).
    // -----------------------------------------------------------------------

    test('tournament bubble requires more equity to raise than cash game', () {
      // pot=100, call=50 → pot odds ≈ 33.3%
      // Raise threshold (no pos): 1.8 * 33.3% ≈ 60%
      // With cashGame threshold 1.5 * 33.3% ≈ 50%
      // equity=55% → RAISE in cash game, CALL in bubble

      final cashDecision = DecisionEngine.decide(
        equity: 0.55,
        pot: 100,
        costToCall: 50,
        gameMode: GameMode.cashGame,
      );
      final bubbleDecision = DecisionEngine.decide(
        equity: 0.55,
        pot: 100,
        costToCall: 50,
        gameMode: GameMode.tournamentBubble,
      );

      expect(cashDecision.action, PlayerAction.raise);
      expect(bubbleDecision.action, PlayerAction.call);
    });

    // -----------------------------------------------------------------------
    // Heads-Up — very loose thresholds (raiseMultiple=1.2).
    // -----------------------------------------------------------------------

    test('heads-up raises more aggressively than cash game', () {
      // pot=100, call=50 → pot odds ≈ 33.3%
      // Raise threshold heads-up (no pos): 1.2 * 33.3% ≈ 40%
      // Cash game threshold: 1.5 * 33.3% ≈ 50%
      // equity=45% → CALL in cash game, RAISE in heads-up

      final cashDecision = DecisionEngine.decide(
        equity: 0.45,
        pot: 100,
        costToCall: 50,
        gameMode: GameMode.cashGame,
      );
      final huDecision = DecisionEngine.decide(
        equity: 0.45,
        pot: 100,
        costToCall: 50,
        gameMode: GameMode.headsUp,
      );

      expect(cashDecision.action, PlayerAction.call);
      expect(huDecision.action, PlayerAction.raise);
    });

    // -----------------------------------------------------------------------
    // Free-check threshold scaling.
    // -----------------------------------------------------------------------

    test('bubble free-check: equity=0.65 → CALL (threshold=0.70)', () {
      final decision = DecisionEngine.decide(
        equity: 0.65,
        pot: 100,
        costToCall: 0,
        gameMode: GameMode.tournamentBubble,
      );
      expect(decision.action, PlayerAction.call);
    });

    test('heads-up free-check: equity=0.48 → RAISE (threshold=0.45)', () {
      final decision = DecisionEngine.decide(
        equity: 0.48,
        pot: 100,
        costToCall: 0,
        gameMode: GameMode.headsUp,
      );
      expect(decision.action, PlayerAction.raise);
    });

    test('cash game free-check: equity=0.55 → CALL (threshold=0.60)', () {
      final decision = DecisionEngine.decide(
        equity: 0.55,
        pot: 100,
        costToCall: 0,
        gameMode: GameMode.cashGame,
      );
      expect(decision.action, PlayerAction.call);
    });

    test('cash game free-check: equity=0.65 → RAISE (threshold=0.60)', () {
      final decision = DecisionEngine.decide(
        equity: 0.65,
        pot: 100,
        costToCall: 0,
        gameMode: GameMode.cashGame,
      );
      expect(decision.action, PlayerAction.raise);
    });

    // -----------------------------------------------------------------------
    // Game mode appears in explanation.
    // -----------------------------------------------------------------------

    test('explanation includes game mode label when mode is provided', () {
      final decision = DecisionEngine.decide(
        equity: 0.50,
        pot: 100,
        costToCall: 50,
        gameMode: GameMode.turbo,
      );
      expect(decision.explanation, contains('Turbo / Speed'));
    });

    test('explanation does not mention game mode when null', () {
      final decision = DecisionEngine.decide(
        equity: 0.50,
        pot: 100,
        costToCall: 50,
      );
      // Should not contain any mode labels.
      for (final mode in GameMode.values) {
        expect(decision.explanation, isNot(contains(gameModeLabel(mode))));
      }
    });

    // -----------------------------------------------------------------------
    // Free-check is never FOLD regardless of game mode.
    // -----------------------------------------------------------------------

    test('free check never recommends fold for any game mode', () {
      for (final mode in GameMode.values) {
        for (final equity in [0.05, 0.20, 0.40, 0.60, 0.80]) {
          final decision = DecisionEngine.decide(
            equity: equity,
            pot: 100,
            costToCall: 0,
            gameMode: mode,
          );
          expect(
            decision.action,
            isNot(PlayerAction.fold),
            reason: 'equity=$equity mode=$mode should not fold on free check',
          );
        }
      }
    });

    // -----------------------------------------------------------------------
    // Turbo — looser than cash game.
    // -----------------------------------------------------------------------

    test('turbo mode raises more aggressively than cash game (free check)', () {
      // Turbo threshold 0.50 vs cash game threshold 0.60
      // equity=0.55 → cash=CALL, turbo=RAISE
      final cashDecision = DecisionEngine.decide(
        equity: 0.55,
        pot: 100,
        costToCall: 0,
        gameMode: GameMode.cashGame,
      );
      final turboDecision = DecisionEngine.decide(
        equity: 0.55,
        pot: 100,
        costToCall: 0,
        gameMode: GameMode.turbo,
      );
      expect(cashDecision.action, PlayerAction.call);
      expect(turboDecision.action, PlayerAction.raise);
    });
  });
}
