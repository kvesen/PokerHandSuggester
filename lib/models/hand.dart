/// Hand model: holds hole cards and community cards.
library;

import 'card.dart';

/// Represents all cards in play for one hand evaluation.
class Hand {
  const Hand({required this.holeCards, this.communityCards = const []});

  /// The two private cards dealt to the player.
  final List<PokerCard> holeCards;

  /// The shared community cards (0–5).
  final List<PokerCard> communityCards;

  /// All cards visible for this hand (hole + community).
  List<PokerCard> get allCards => [...holeCards, ...communityCards];

  /// Creates a copy with optional overrides.
  Hand copyWith({List<PokerCard>? holeCards, List<PokerCard>? communityCards}) {
    return Hand(
      holeCards: holeCards ?? this.holeCards,
      communityCards: communityCards ?? this.communityCards,
    );
  }
}
