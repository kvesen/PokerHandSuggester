import 'package:flutter_test/flutter_test.dart';
import 'package:poker_hand_suggester/engine/decision_engine.dart';
import 'package:poker_hand_suggester/models/position.dart';

void main() {
  group('DecisionEngine — position awareness', () {
    // pot=100, call=50 → pot odds ≈ 33.3%
    // equity = 45%  →  potOdds * 1.5 (no position) = 50%
    //   BTN multiplier 1.15 → threshold = 1.5/1.15 ≈ 1.304 → 33.3%*1.304 ≈ 43.5%
    //     → 45% > 43.5%  → RAISE on BTN
    //   UTG multiplier 0.80 → threshold = 1.5/0.80 = 1.875 → 33.3%*1.875 ≈ 62.5%
    //     → 45% < 62.5%  → CALL on UTG
    test('Button raises where UTG calls (same equity & pot odds)', () {
      const equity = 0.45;
      const pot = 100.0;
      const call = 50.0;

      final btnDecision = DecisionEngine.decide(
        equity: equity,
        pot: pot,
        costToCall: call,
        heroPosition: TablePosition.button,
      );
      expect(btnDecision.action, PlayerAction.raise,
          reason: 'Button should raise with 45% equity');

      final utgDecision = DecisionEngine.decide(
        equity: equity,
        pot: pot,
        costToCall: call,
        heroPosition: TablePosition.utg,
      );
      expect(utgDecision.action, PlayerAction.call,
          reason: 'UTG should only call with 45% equity');
    });

    test('null position produces same result as before (backward compat)', () {
      const equity = 0.70;
      const pot = 100.0;
      const call = 50.0;

      final withNull = DecisionEngine.decide(
        equity: equity,
        pot: pot,
        costToCall: call,
      );
      final noPosition = DecisionEngine.decide(
        equity: equity,
        pot: pot,
        costToCall: call,
        heroPosition: null,
      );

      expect(withNull.action, noPosition.action);
      expect(withNull.potOdds, closeTo(noPosition.potOdds, 0.0001));
      expect(withNull.expectedValue, closeTo(noPosition.expectedValue, 0.01));
    });

    // Free check: equity = 65%, BTN threshold = 0.6/1.15 ≈ 0.522 → raise
    test('Free check — strong hand on Button → raise', () {
      final decision = DecisionEngine.decide(
        equity: 0.65,
        pot: 100,
        costToCall: 0,
        heroPosition: TablePosition.button,
      );
      expect(decision.action, PlayerAction.raise);
    });

    // Free check: equity = 55%, UTG threshold = 0.6/0.80 = 0.75 → NOT >= 0.75 → call
    test('Free check — 55% equity UTG → call (threshold raised by position)', () {
      final decision = DecisionEngine.decide(
        equity: 0.55,
        pot: 100,
        costToCall: 0,
        heroPosition: TablePosition.utg,
      );
      expect(decision.action, PlayerAction.call);
    });

    // Free check: equity = 55%, no position, threshold = 0.6 → 55% < 60% → call
    test('Free check — 55% equity no position → call', () {
      final decision = DecisionEngine.decide(
        equity: 0.55,
        pot: 100,
        costToCall: 0,
      );
      expect(decision.action, PlayerAction.call);
    });

    // Free check: equity = 75%, BTN threshold ≈ 0.522 → raise
    test('Free check — strong hand BTN (75%) → raise', () {
      final decision = DecisionEngine.decide(
        equity: 0.75,
        pot: 100,
        costToCall: 0,
        heroPosition: TablePosition.button,
      );
      expect(decision.action, PlayerAction.raise);
    });

    // Free check: equity = 75%, UTG threshold = 0.75 → borderline (not strictly < 0.75) → raise
    test('Free check — strong hand UTG (75%) → raise (equity meets threshold)', () {
      final decision = DecisionEngine.decide(
        equity: 0.75,
        pot: 100,
        costToCall: 0,
        heroPosition: TablePosition.utg,
      );
      expect(decision.action, PlayerAction.raise);
    });

    test('Explanation includes position note when position provided', () {
      final decision = DecisionEngine.decide(
        equity: 0.70,
        pot: 100,
        costToCall: 50,
        heroPosition: TablePosition.button,
      );
      expect(decision.explanation, contains('BTN'));
    });

    test('Explanation does NOT include position note when position is null', () {
      final decision = DecisionEngine.decide(
        equity: 0.70,
        pot: 100,
        costToCall: 50,
      );
      // Should not mention any position abbreviations
      expect(decision.explanation, isNot(contains('BTN')));
      expect(decision.explanation, isNot(contains('UTG')));
      expect(decision.explanation, isNot(contains('position')));
    });

    test('positionMultiplier returns correct values', () {
      expect(positionMultiplier(TablePosition.utg), closeTo(0.80, 0.001));
      expect(positionMultiplier(TablePosition.button), closeTo(1.15, 0.001));
      expect(positionMultiplier(TablePosition.hijack), closeTo(1.00, 0.001));
      expect(positionMultiplier(TablePosition.smallBlind), closeTo(0.90, 0.001));
    });

    test('positionLabel returns short readable strings', () {
      expect(positionLabel(TablePosition.utg), 'UTG');
      expect(positionLabel(TablePosition.button), 'BTN');
      expect(positionLabel(TablePosition.cutoff), 'CO');
      expect(positionLabel(TablePosition.smallBlind), 'SB');
      expect(positionLabel(TablePosition.bigBlind), 'BB');
    });

    test('positionDescription returns non-empty strings for all positions', () {
      for (final pos in TablePosition.values) {
        expect(positionDescription(pos), isNotEmpty,
            reason: 'positionDescription($pos) should not be empty');
      }
    });

    test('All positions produce valid decisions', () {
      for (final pos in TablePosition.values) {
        final decision = DecisionEngine.decide(
          equity: 0.50,
          pot: 100,
          costToCall: 30,
          heroPosition: pos,
        );
        expect(decision.action, isNotNull);
        expect(decision.explanation, isNotEmpty);
      }
    });
  });
}
