import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_hand_suggester/models/game_mode.dart';
import 'package:poker_hand_suggester/services/game_mode_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GameModeService', () {
    test('default game mode is cashGame', () async {
      final service = await GameModeService.create();
      expect(service.gameMode, GameMode.cashGame);
    });

    test('setGameMode persists the new mode', () async {
      final service = await GameModeService.create();
      await service.setGameMode(GameMode.headsUp);
      expect(service.gameMode, GameMode.headsUp);
    });

    test('setGameMode is a no-op when mode is already set', () async {
      final service = await GameModeService.create();
      await service.setGameMode(GameMode.cashGame); // already the default
      expect(service.gameMode, GameMode.cashGame);
    });

    test('persists game mode across instances', () async {
      final first = await GameModeService.create();
      await first.setGameMode(GameMode.turbo);

      // Second instance reads same SharedPreferences.
      final second = await GameModeService.create();
      expect(second.gameMode, GameMode.turbo);
    });

    test('cashGameDefault returns cashGame without loading prefs', () {
      final service = GameModeService.cashGameDefault();
      expect(service.gameMode, GameMode.cashGame);
    });

    test('falls back to cashGame for unknown stored value', () async {
      SharedPreferences.setMockInitialValues({'game_mode': 'unknown_mode'});
      final service = await GameModeService.create();
      expect(service.gameMode, GameMode.cashGame);
    });

    test('persists all GameMode values correctly', () async {
      for (final mode in GameMode.values) {
        SharedPreferences.setMockInitialValues({});
        final service = await GameModeService.create();
        await service.setGameMode(mode);

        final reloaded = await GameModeService.create();
        expect(reloaded.gameMode, mode);
      }
    });
  });
}
