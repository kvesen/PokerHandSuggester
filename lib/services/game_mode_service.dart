/// Game mode service: persists and provides the selected game mode.
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_mode.dart';

const _kGameModeKey = 'game_mode';

/// Persists and retrieves the user's preferred [GameMode] via
/// [SharedPreferences].
class GameModeService {
  GameModeService._();

  GameMode _gameMode = GameMode.cashGame;

  /// The currently persisted game mode.
  GameMode get gameMode => _gameMode;

  /// Creates and initialises a [GameModeService] instance.
  ///
  /// If the preference cannot be loaded (e.g. [SharedPreferences] unavailable),
  /// the service falls back to [GameMode.cashGame] silently.
  static Future<GameModeService> create() async {
    final service = GameModeService._();
    try {
      await service._load();
    } catch (e, st) {
      debugPrint(
        'GameModeService: failed to load game mode preference — '
        'defaulting to cashGame\n$e\n$st',
      );
    }
    return service;
  }

  /// Creates a [GameModeService] with [GameMode.cashGame] without loading from
  /// [SharedPreferences]. Used as a fallback when initialisation fails.
  static GameModeService cashGameDefault() => GameModeService._();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kGameModeKey);
    if (stored != null) {
      _gameMode = GameMode.values.firstWhere(
        (m) => m.name == stored,
        orElse: () => GameMode.cashGame,
      );
    }
  }

  /// Persists [mode] as the new game mode preference.
  Future<void> setGameMode(GameMode mode) async {
    if (_gameMode == mode) return;
    _gameMode = mode;
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGameModeKey, _gameMode.name);
  }
}
