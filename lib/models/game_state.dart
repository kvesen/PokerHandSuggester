/// Game state model: captures the full table situation.
library;

import 'card.dart';

/// The current state of the poker table used as input to the decision engine.
class GameState {
  const GameState({
    required this.holeCards,
    this.communityCards = const [],
    required this.potSize,
    required this.betToCall,
    required this.numberOfOpponents,
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

  /// Creates a copy with optional overrides.
  GameState copyWith({
    List<PokerCard>? holeCards,
    List<PokerCard>? communityCards,
    double? potSize,
    double? betToCall,
    int? numberOfOpponents,
  }) {
    return GameState(
      holeCards: holeCards ?? this.holeCards,
      communityCards: communityCards ?? this.communityCards,
      potSize: potSize ?? this.potSize,
      betToCall: betToCall ?? this.betToCall,
      numberOfOpponents: numberOfOpponents ?? this.numberOfOpponents,
    );
  }
}
