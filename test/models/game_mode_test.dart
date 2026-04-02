import 'package:flutter_test/flutter_test.dart';
import 'package:poker_hand_suggester/models/game_mode.dart';

void main() {
  group('gameModeLabel', () {
    test('returns correct label for each mode', () {
      expect(gameModeLabel(GameMode.cashGame), 'Cash Game');
      expect(gameModeLabel(GameMode.tournamentEarly), 'Tournament (Early)');
      expect(gameModeLabel(GameMode.tournamentBubble), 'Tournament (Bubble)');
      expect(gameModeLabel(GameMode.tournamentFinalTable), 'Tournament (Final Table)');
      expect(gameModeLabel(GameMode.turbo), 'Turbo / Speed');
      expect(gameModeLabel(GameMode.headsUp), 'Heads-Up');
    });
  });

  group('gameModeDescription', () {
    test('returns non-empty description for every mode', () {
      for (final mode in GameMode.values) {
        expect(
          gameModeDescription(mode),
          isNotEmpty,
          reason: 'description for $mode should not be empty',
        );
      }
    });
  });

  group('gameModeRaiseMultiple', () {
    test('cash game returns 1.5', () {
      expect(gameModeRaiseMultiple(GameMode.cashGame), 1.5);
    });

    test('tournament early returns 1.6 (tighter than cash)', () {
      expect(gameModeRaiseMultiple(GameMode.tournamentEarly), 1.6);
      expect(
        gameModeRaiseMultiple(GameMode.tournamentEarly),
        greaterThan(gameModeRaiseMultiple(GameMode.cashGame)),
      );
    });

    test('tournament bubble returns 1.8 (tightest)', () {
      expect(gameModeRaiseMultiple(GameMode.tournamentBubble), 1.8);
    });

    test('tournament final table returns 1.4 (looser than cash)', () {
      expect(gameModeRaiseMultiple(GameMode.tournamentFinalTable), 1.4);
      expect(
        gameModeRaiseMultiple(GameMode.tournamentFinalTable),
        lessThan(gameModeRaiseMultiple(GameMode.cashGame)),
      );
    });

    test('turbo returns 1.3', () {
      expect(gameModeRaiseMultiple(GameMode.turbo), 1.3);
    });

    test('heads-up returns 1.2 (most aggressive)', () {
      expect(gameModeRaiseMultiple(GameMode.headsUp), 1.2);
      expect(
        gameModeRaiseMultiple(GameMode.headsUp),
        lessThan(gameModeRaiseMultiple(GameMode.turbo)),
      );
    });
  });

  group('gameModeFreeCheckThreshold', () {
    test('cash game returns 0.60', () {
      expect(gameModeFreeCheckThreshold(GameMode.cashGame), 0.60);
    });

    test('tournament bubble returns 0.70 (tightest)', () {
      expect(gameModeFreeCheckThreshold(GameMode.tournamentBubble), 0.70);
    });

    test('heads-up returns 0.45 (most aggressive)', () {
      expect(gameModeFreeCheckThreshold(GameMode.headsUp), 0.45);
    });

    test('turbo is more aggressive than cash', () {
      expect(
        gameModeFreeCheckThreshold(GameMode.turbo),
        lessThan(gameModeFreeCheckThreshold(GameMode.cashGame)),
      );
    });
  });

  group('gameModePositionScale', () {
    test('cash game scale is 1.0 (unchanged)', () {
      expect(gameModePositionScale(GameMode.cashGame), 1.0);
    });

    test('tournament bubble scale is 0.80 (much tighter)', () {
      expect(gameModePositionScale(GameMode.tournamentBubble), 0.80);
    });

    test('turbo scale is 1.10 (looser)', () {
      expect(gameModePositionScale(GameMode.turbo), 1.10);
    });

    test('heads-up scale is 1.10 (looser)', () {
      expect(gameModePositionScale(GameMode.headsUp), 1.10);
    });

    test('tight modes have scale < 1.0', () {
      expect(gameModePositionScale(GameMode.tournamentEarly), lessThan(1.0));
      expect(gameModePositionScale(GameMode.tournamentBubble), lessThan(1.0));
    });

    test('aggressive modes have scale > 1.0', () {
      expect(gameModePositionScale(GameMode.turbo), greaterThan(1.0));
      expect(gameModePositionScale(GameMode.headsUp), greaterThan(1.0));
    });
  });
}
