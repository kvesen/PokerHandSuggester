/// Card model: Suit, Rank, and PokerCard.
library;

/// The four suits in a standard deck.
enum Suit { hearts, diamonds, clubs, spades }

/// The thirteen ranks in a standard deck, ordered by value (two = lowest).
enum Rank {
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
  ace,
}

/// A single playing card. Named [PokerCard] to avoid collision with Flutter's
/// [Card] widget.
class PokerCard {
  const PokerCard({required this.suit, required this.rank});

  final Suit suit;
  final Rank rank;

  /// Numeric value of the rank (2-14, where ace = 14).
  int get value => rank.index + 2;

  /// Returns a standard deck of 52 unique cards.
  static List<PokerCard> fullDeck() {
    return [
      for (final suit in Suit.values)
        for (final rank in Rank.values) PokerCard(suit: suit, rank: rank),
    ];
  }

  @override
  bool operator ==(Object other) =>
      other is PokerCard && other.suit == suit && other.rank == rank;

  @override
  int get hashCode => Object.hash(suit, rank);

  @override
  String toString() => '${rank.name}Of${suit.name}';
}
