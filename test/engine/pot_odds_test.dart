import 'package:flutter_test/flutter_test.dart';
import 'package:poker_hand_suggester/engine/pot_odds.dart';

void main() {
  group('PotOdds.calculate', () {
    test('returns correct fraction for typical values', () {
      // pot=100, call=50 → 50/150 ≈ 0.3333
      expect(
        PotOdds.calculate(pot: 100, costToCall: 50),
        closeTo(1 / 3, 0.0001),
      );
    });

    test('returns 0 when costToCall is 0', () {
      expect(PotOdds.calculate(pot: 200, costToCall: 0), 0);
    });

    test('returns 0 when pot and costToCall are 0', () {
      expect(PotOdds.calculate(pot: 0, costToCall: 0), 0);
    });

    test('returns 0.5 when pot equals costToCall', () {
      expect(PotOdds.calculate(pot: 50, costToCall: 50), closeTo(0.5, 0.0001));
    });

    test('returns close to 1 when costToCall is much larger than pot', () {
      // pot=10, call=990 → 990/1000 = 0.99
      expect(
        PotOdds.calculate(pot: 10, costToCall: 990),
        closeTo(0.99, 0.0001),
      );
    });

    test('returns close to 0 when costToCall is much smaller than pot', () {
      // pot=990, call=10 → 10/1000 = 0.01
      expect(
        PotOdds.calculate(pot: 990, costToCall: 10),
        closeTo(0.01, 0.0001),
      );
    });
  });

  group('PotOdds.requiredEquity', () {
    test('matches calculate result', () {
      expect(
        PotOdds.requiredEquity(pot: 100, costToCall: 50),
        PotOdds.calculate(pot: 100, costToCall: 50),
      );
    });

    test('is 25% for 1:3 pot odds (pot=150, call=50)', () {
      // call=50, pot+call=200 → 50/200 = 0.25
      expect(
        PotOdds.requiredEquity(pot: 150, costToCall: 50),
        closeTo(0.25, 0.0001),
      );
    });

    // ---- Edge-case tests --------------------------------------------------

    test('betToCall=0 returns exactly 0.0', () {
      expect(PotOdds.calculate(pot: 500, costToCall: 0), 0.0);
      expect(PotOdds.requiredEquity(pot: 500, costToCall: 0), 0.0);
    });

    test('large pot / small bet → very low pot odds', () {
      // pot=990, call=10 → 10/1000 = 1%
      final odds = PotOdds.calculate(pot: 990, costToCall: 10);
      expect(odds, closeTo(0.01, 0.0001));
    });

    test('small pot / large bet → very high pot odds', () {
      // pot=10, call=990 → 990/1000 = 99%
      final odds = PotOdds.calculate(pot: 10, costToCall: 990);
      expect(odds, closeTo(0.99, 0.0001));
    });
  });
}
