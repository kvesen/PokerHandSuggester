import 'package:flutter_test/flutter_test.dart';
import 'package:poker_hand_suggester/models/hand_range.dart';
import 'package:poker_hand_suggester/models/position.dart';

void main() {
  // ---------------------------------------------------------------------------
  // handLabel
  // ---------------------------------------------------------------------------
  group('handLabel', () {
    test('returns pocket pair labels on the diagonal', () {
      expect(handLabel(0, 0), 'AA');
      expect(handLabel(1, 1), 'KK');
      expect(handLabel(4, 4), 'TT');
      expect(handLabel(12, 12), '22');
    });

    test('returns suited labels above the diagonal', () {
      expect(handLabel(0, 1), 'AKs');
      expect(handLabel(0, 4), 'ATs');
      expect(handLabel(3, 4), 'JTs');
      expect(handLabel(6, 7), '87s');
      expect(handLabel(11, 12), '32s');
    });

    test('returns offsuit labels below the diagonal', () {
      expect(handLabel(1, 0), 'AKo');
      expect(handLabel(2, 0), 'AQo');
      expect(handLabel(4, 3), 'JTo');
      expect(handLabel(7, 6), '87o');
      expect(handLabel(12, 11), '32o');
    });

    test('suited and offsuit produce correct symmetry', () {
      // AKs vs AKo should share the same rank letters
      expect(handLabel(0, 1).substring(0, 2), handLabel(1, 0).substring(0, 2));
    });
  });

  // ---------------------------------------------------------------------------
  // isSuited / isPocketPair
  // ---------------------------------------------------------------------------
  group('isSuited', () {
    test('returns true for cells above the diagonal', () {
      expect(isSuited(0, 1), isTrue); // AKs
      expect(isSuited(0, 12), isTrue); // A2s
      expect(isSuited(3, 4), isTrue); // JTs
      expect(isSuited(11, 12), isTrue); // 32s
    });

    test('returns false on diagonal and below', () {
      expect(isSuited(0, 0), isFalse); // AA
      expect(isSuited(1, 0), isFalse); // AKo
      expect(isSuited(5, 3), isFalse); // JTo (below)
    });
  });

  group('isPocketPair', () {
    test('returns true on the diagonal', () {
      for (int i = 0; i < 13; i++) {
        expect(
          isPocketPair(i, i),
          isTrue,
          reason: 'cell ($i,$i) should be a pair',
        );
      }
    });

    test('returns false off-diagonal', () {
      expect(isPocketPair(0, 1), isFalse);
      expect(isPocketPair(1, 0), isFalse);
      expect(isPocketPair(5, 7), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // getAction — basic validity
  // ---------------------------------------------------------------------------
  group('getAction', () {
    test('returns a valid RangeAction for every cell and position', () {
      for (final pos in TablePosition.values) {
        for (int r = 0; r < 13; r++) {
          for (int c = 0; c < 13; c++) {
            final action = getAction(pos, r, c);
            expect(
              RangeAction.values.contains(action),
              isTrue,
              reason:
                  'getAction($pos, $r, $c) should return a valid RangeAction',
            );
          }
        }
      }
    });

    test('AA is always a raise from every position', () {
      for (final pos in TablePosition.values) {
        expect(
          getAction(pos, 0, 0),
          RangeAction.raise,
          reason: 'AA should be a raise from $pos',
        );
      }
    });

    test('KK is always a raise from every position', () {
      for (final pos in TablePosition.values) {
        expect(
          getAction(pos, 1, 1),
          RangeAction.raise,
          reason: 'KK should be a raise from $pos',
        );
      }
    });

    test('72o is fold from UTG, MP, and HJ', () {
      // 7 = index 7, 2 = index 12; 72o is row=12, col=7 (below diagonal)
      expect(getAction(TablePosition.utg, 12, 7), RangeAction.fold);
      expect(getAction(TablePosition.mp, 12, 7), RangeAction.fold);
      expect(getAction(TablePosition.hijack, 12, 7), RangeAction.fold);
    });

    test('AKs is raise from all positions', () {
      // AKs = row 0, col 1
      for (final pos in TablePosition.values) {
        expect(
          getAction(pos, 0, 1),
          RangeAction.raise,
          reason: 'AKs should be raise from $pos',
        );
      }
    });

    test('AKo is raise from all positions', () {
      // AKo = row 1, col 0
      for (final pos in TablePosition.values) {
        expect(
          getAction(pos, 1, 0),
          RangeAction.raise,
          reason: 'AKo should be raise from $pos',
        );
      }
    });
  });

  // ---------------------------------------------------------------------------
  // UTG is tighter than BTN
  // ---------------------------------------------------------------------------
  group('UTG tighter than BTN', () {
    test('BTN raises more hands than UTG', () {
      int utgRaise = 0;
      int btnRaise = 0;
      for (int r = 0; r < 13; r++) {
        for (int c = 0; c < 13; c++) {
          if (getAction(TablePosition.utg, r, c) == RangeAction.raise)
            utgRaise++;
          if (getAction(TablePosition.button, r, c) == RangeAction.raise)
            btnRaise++;
        }
      }
      expect(
        btnRaise,
        greaterThan(utgRaise),
        reason: 'BTN should raise more hands than UTG',
      );
    });

    test('BTN plays more hands (raise+call) than UTG', () {
      int utgPlay = 0;
      int btnPlay = 0;
      for (int r = 0; r < 13; r++) {
        for (int c = 0; c < 13; c++) {
          final utgAction = getAction(TablePosition.utg, r, c);
          final btnAction = getAction(TablePosition.button, r, c);
          if (utgAction != RangeAction.fold) utgPlay++;
          if (btnAction != RangeAction.fold) btnPlay++;
        }
      }
      expect(
        btnPlay,
        greaterThan(utgPlay),
        reason: 'BTN should play more hands than UTG',
      );
    });

    test('CO plays more hands than UTG', () {
      int utgPlay = 0;
      int coPlay = 0;
      for (int r = 0; r < 13; r++) {
        for (int c = 0; c < 13; c++) {
          if (getAction(TablePosition.utg, r, c) != RangeAction.fold) utgPlay++;
          if (getAction(TablePosition.cutoff, r, c) != RangeAction.fold)
            coPlay++;
        }
      }
      expect(coPlay, greaterThan(utgPlay));
    });
  });

  // ---------------------------------------------------------------------------
  // openingPercentage
  // ---------------------------------------------------------------------------
  group('openingPercentage', () {
    test('UTG returns ~15%', () {
      expect(openingPercentage(TablePosition.utg), closeTo(15.0, 1.0));
    });

    test('BTN returns ~45%', () {
      expect(openingPercentage(TablePosition.button), closeTo(45.0, 2.0));
    });

    test('returns non-zero for every position', () {
      for (final pos in TablePosition.values) {
        expect(
          openingPercentage(pos),
          greaterThan(0),
          reason: 'openingPercentage($pos) should be > 0',
        );
      }
    });

    test('percentages increase from UTG to BTN', () {
      final utg = openingPercentage(TablePosition.utg);
      final mp = openingPercentage(TablePosition.mp);
      final hj = openingPercentage(TablePosition.hijack);
      final co = openingPercentage(TablePosition.cutoff);
      final btn = openingPercentage(TablePosition.button);
      expect(mp, greaterThan(utg));
      expect(hj, greaterThan(mp));
      expect(co, greaterThan(hj));
      expect(btn, greaterThan(co));
    });

    test('all percentages are within 10–50%', () {
      for (final pos in TablePosition.values) {
        final pct = openingPercentage(pos);
        expect(pct, greaterThan(9.0));
        expect(pct, lessThan(51.0));
      }
    });
  });

  // ---------------------------------------------------------------------------
  // BB 3-bet premiums
  // ---------------------------------------------------------------------------
  group('BB special cases', () {
    test('BB 3-bets AA', () {
      expect(getAction(TablePosition.bigBlind, 0, 0), RangeAction.raise);
    });

    test('BB calls with medium pairs', () {
      // TT = index 4
      expect(getAction(TablePosition.bigBlind, 4, 4), RangeAction.call);
    });

    test('BB calls with suited connectors', () {
      // JTs = row 3, col 4
      expect(getAction(TablePosition.bigBlind, 3, 4), RangeAction.call);
      // 98s = row 5, col 6
      expect(getAction(TablePosition.bigBlind, 5, 6), RangeAction.call);
    });
  });
}
