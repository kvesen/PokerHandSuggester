/// Game state model: captures the full table situation.
library;

import 'card.dart';
import 'game_mode.dart';
import 'position.dart';

/// The current state of the poker table used as input to the decision engine.
class GameState {
  const GameState({
    required this.holeCards,
    this.communityCards = const [],
    required this.potSize,
    required this.betToCall,
    required this.numberOfOpponents,
    this.heroPosition,
    this.villainPositions,
    this.gameMode,
  });

  /// The player's two private hole cards.
  final List<PokerCard> holeCards;

  /// Community cards currently on the board (0–5).
  final List<PokerCard> communityCards;

  /// The total amount already in the pot (in chips / currency units).
  final double potSize;

  /// The amount the player must call to stay in the hand.
  final double betToCall;

  /// Number of active opponents (excluding the player).
  final int numberOfOpponents;

  /// The hero's table position (optional).
  final TablePosition? heroPosition;

  /// The villain seats (optional).
  final List<TablePosition>? villainPositions;

  /// The selected game mode / playing style (optional).
  final GameMode? gameMode;

  /// Creates a copy with optional overrides.
  ///
  /// To explicitly clear [heroPosition] or [villainPositions], pass
  /// `clearHeroPosition: true` / `clearVillainPositions: true`.
  GameState copyWith({
    List<PokerCard>? holeCards,
    List<PokerCard>? communityCards,
    double? potSize,
    double? betToCall,
    int? numberOfOpponents,
    TablePosition? heroPosition,
    List<TablePosition>? villainPositions,
    GameMode? gameMode,
    bool clearHeroPosition = false,
    bool clearVillainPositions = false,
    bool clearGameMode = false,
  }) {
    return GameState(
      holeCards: holeCards ?? this.holeCards,
      communityCards: communityCards ?? this.communityCards,
      potSize: potSize ?? this.potSize,
      betToCall: betToCall ?? this.betToCall,
      numberOfOpponents: numberOfOpponents ?? this.numberOfOpponents,
      heroPosition: clearHeroPosition
          ? null
          : (heroPosition ?? this.heroPosition),
      villainPositions: clearVillainPositions
          ? null
          : (villainPositions ?? this.villainPositions),
      gameMode: clearGameMode ? null : (gameMode ?? this.gameMode),
    );
  }
}
