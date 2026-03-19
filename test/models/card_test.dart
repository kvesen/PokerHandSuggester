import 'package:flutter_test/flutter_test.dart';
import 'package:poker_hand_suggester/models/card.dart';

void main() {
  group('PokerCard', () {
    test('value returns correct integer for rank', () {
      expect(const PokerCard(suit: Suit.hearts, rank: Rank.two).value, 2);
      expect(const PokerCard(suit: Suit.spades, rank: Rank.ace).value, 14);
      expect(const PokerCard(suit: Suit.clubs, rank: Rank.king).value, 13);
      expect(const PokerCard(suit: Suit.diamonds, rank: Rank.ten).value, 10);
    });

    test('equality works correctly', () {
      const card1 = PokerCard(suit: Suit.hearts, rank: Rank.ace);
      const card2 = PokerCard(suit: Suit.hearts, rank: Rank.ace);
      const card3 = PokerCard(suit: Suit.spades, rank: Rank.ace);

      expect(card1 == card2, isTrue);
      expect(card1 == card3, isFalse);
    });

    test('hashCode is consistent with equality', () {
      const card1 = PokerCard(suit: Suit.hearts, rank: Rank.king);
      const card2 = PokerCard(suit: Suit.hearts, rank: Rank.king);
      expect(card1.hashCode == card2.hashCode, isTrue);
    });

    test('fullDeck returns 52 unique cards', () {
      final deck = PokerCard.fullDeck();
      expect(deck.length, 52);
      // All cards are unique
      final unique = deck.toSet();
      expect(unique.length, 52);
    });

    test('fullDeck contains all suits', () {
      final deck = PokerCard.fullDeck();
      for (final suit in Suit.values) {
        expect(deck.where((c) => c.suit == suit).length, 13);
      }
    });

    test('fullDeck contains all ranks', () {
      final deck = PokerCard.fullDeck();
      for (final rank in Rank.values) {
        expect(deck.where((c) => c.rank == rank).length, 4);
      }
    });

    test('toString returns expected format', () {
      const card = PokerCard(suit: Suit.hearts, rank: Rank.ace);
      expect(card.toString(), 'aceOfhearts');
    });
  });

  group('Suit enum', () {
    test('has four suits', () {
      expect(Suit.values.length, 4);
    });
  });

  group('Rank enum', () {
    test('has thirteen ranks', () {
      expect(Rank.values.length, 13);
    });

    test('two is index 0, ace is index 12', () {
      expect(Rank.two.index, 0);
      expect(Rank.ace.index, 12);
    });
  });
}
