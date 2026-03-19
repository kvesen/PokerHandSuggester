import 'package:flutter_test/flutter_test.dart';
import 'package:poker_hand_suggester/engine/decision_engine.dart';

void main() {
  group('DecisionEngine.decide', () {
    test('recommends FOLD when equity < pot odds', () {
      // pot=100, call=50 → pot odds = 33.3%
      // equity = 20% < 33.3% → FOLD
      final decision = DecisionEngine.decide(
        equity: 0.20,
        pot: 100,
        costToCall: 50,
      );
      expect(decision.action, PlayerAction.fold);
    });

    test('recommends CALL when equity is marginally above pot odds', () {
      // pot=100, call=50 → pot odds ≈ 33.3%
      // equity = 40% ≥ 33.3% but < 33.3%*1.5=50% → CALL
      final decision = DecisionEngine.decide(
        equity: 0.40,
        pot: 100,
        costToCall: 50,
      );
      expect(decision.action, PlayerAction.call);
    });

    test('recommends RAISE when equity significantly exceeds pot odds', () {
      // pot=100, call=50 → pot odds ≈ 33.3%, 1.5x = 50%
      // equity = 70% ≥ 50% → RAISE
      final decision = DecisionEngine.decide(
        equity: 0.70,
        pot: 100,
        costToCall: 50,
      );
      expect(decision.action, PlayerAction.raise);
    });

    test('recommends CALL (check) when costToCall is 0 and equity < 60%', () {
      final decision = DecisionEngine.decide(
        equity: 0.45,
        pot: 100,
        costToCall: 0,
      );
      expect(decision.action, PlayerAction.call);
    });

    test('recommends RAISE when costToCall is 0 and equity >= 60%', () {
      final decision = DecisionEngine.decide(
        equity: 0.65,
        pot: 100,
        costToCall: 0,
      );
      expect(decision.action, PlayerAction.raise);
    });

    test('EV is positive for profitable call', () {
      // equity=50%, pot=100, call=50 → EV = 0.5*100 - 0.5*50 = 25
      final decision = DecisionEngine.decide(
        equity: 0.50,
        pot: 100,
        costToCall: 50,
      );
      expect(decision.expectedValue, closeTo(25, 0.1));
    });

    test('EV is negative for unprofitable call', () {
      // equity=20%, pot=100, call=50 → EV = 0.2*100 - 0.8*50 = 20-40 = -20
      final decision = DecisionEngine.decide(
        equity: 0.20,
        pot: 100,
        costToCall: 50,
      );
      expect(decision.expectedValue, closeTo(-20, 0.1));
    });

    test('potOdds field is set correctly', () {
      final decision = DecisionEngine.decide(
        equity: 0.50,
        pot: 100,
        costToCall: 50,
      );
      // 50 / (100+50) ≈ 0.3333
      expect(decision.potOdds, closeTo(1 / 3, 0.0001));
    });

    test('equity field is stored on Decision', () {
      final decision = DecisionEngine.decide(
        equity: 0.55,
        pot: 200,
        costToCall: 40,
      );
      expect(decision.equity, 0.55);
    });

    test('explanation is non-empty', () {
      final decision = DecisionEngine.decide(
        equity: 0.50,
        pot: 100,
        costToCall: 30,
      );
      expect(decision.explanation, isNotEmpty);
    });

    test('equityPercent formats correctly', () {
      final decision = DecisionEngine.decide(
        equity: 0.50,
        pot: 100,
        costToCall: 50,
      );
      expect(decision.equityPercent, '50.0%');
    });

    test('evFormatted prefixes positive EV with +', () {
      final decision = DecisionEngine.decide(
        equity: 0.80,
        pot: 100,
        costToCall: 20,
      );
      expect(decision.evFormatted, startsWith('+'));
    });

    test('evFormatted uses - for negative EV', () {
      final decision = DecisionEngine.decide(
        equity: 0.10,
        pot: 100,
        costToCall: 50,
      );
      expect(decision.evFormatted, startsWith('-'));
    });
  });
}
