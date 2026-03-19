import 'package:flutter_test/flutter_test.dart';
import 'package:poker_hand_suggester/models/card.dart';
import 'package:poker_hand_suggester/recognition/card_detector.dart';

void main() {
  group('CardTextParser', () {
    // -------------------------------------------------------------------------
    // Unicode suit notation
    // -------------------------------------------------------------------------

    test('parses A♠ → ace of spades', () {
      final result = CardTextParser.parse(['A♠']);
      expect(result.detectedCards, contains(PokerCard(suit: Suit.spades, rank: Rank.ace)));
    });

    test('parses K♥ → king of hearts', () {
      final result = CardTextParser.parse(['K♥']);
      expect(result.detectedCards, contains(PokerCard(suit: Suit.hearts, rank: Rank.king)));
    });

    test('parses Q♦ → queen of diamonds', () {
      final result = CardTextParser.parse(['Q♦']);
      expect(result.detectedCards, contains(PokerCard(suit: Suit.diamonds, rank: Rank.queen)));
    });

    test('parses J♣ → jack of clubs', () {
      final result = CardTextParser.parse(['J♣']);
      expect(result.detectedCards, contains(PokerCard(suit: Suit.clubs, rank: Rank.jack)));
    });

    test('parses 10♦ → ten of diamonds', () {
      final result = CardTextParser.parse(['10♦']);
      expect(result.detectedCards, contains(PokerCard(suit: Suit.diamonds, rank: Rank.ten)));
    });

    test('parses 10♠ → ten of spades', () {
      final result = CardTextParser.parse(['10♠']);
      expect(result.detectedCards, contains(PokerCard(suit: Suit.spades, rank: Rank.ten)));
    });

    // -------------------------------------------------------------------------
    // Letter suit notation
    // -------------------------------------------------------------------------

    test('parses Ah → ace of hearts', () {
      final result = CardTextParser.parse(['Ah']);
      expect(result.detectedCards, contains(PokerCard(suit: Suit.hearts, rank: Rank.ace)));
    });

    test('parses Ks → king of spades', () {
      final result = CardTextParser.parse(['Ks']);
      expect(result.detectedCards, contains(PokerCard(suit: Suit.spades, rank: Rank.king)));
    });

    test('parses Qd → queen of diamonds', () {
      final result = CardTextParser.parse(['Qd']);
      expect(result.detectedCards, contains(PokerCard(suit: Suit.diamonds, rank: Rank.queen)));
    });

    test('parses Jc → jack of clubs', () {
      final result = CardTextParser.parse(['Jc']);
      expect(result.detectedCards, contains(PokerCard(suit: Suit.clubs, rank: Rank.jack)));
    });

    test('parses Td → ten of diamonds', () {
      final result = CardTextParser.parse(['Td']);
      expect(result.detectedCards, contains(PokerCard(suit: Suit.diamonds, rank: Rank.ten)));
    });

    test('parses 2c → two of clubs', () {
      final result = CardTextParser.parse(['2c']);
      expect(result.detectedCards, contains(PokerCard(suit: Suit.clubs, rank: Rank.two)));
    });

    test('parses 9h → nine of hearts', () {
      final result = CardTextParser.parse(['9h']);
      expect(result.detectedCards, contains(PokerCard(suit: Suit.hearts, rank: Rank.nine)));
    });

    test('parses 7s → seven of spades', () {
      final result = CardTextParser.parse(['7s']);
      expect(result.detectedCards, contains(PokerCard(suit: Suit.spades, rank: Rank.seven)));
    });

    // -------------------------------------------------------------------------
    // Full name notation
    // -------------------------------------------------------------------------

    test('parses "Ace of Spades" → ace of spades', () {
      final result = CardTextParser.parse(['Ace of Spades']);
      expect(result.detectedCards, contains(PokerCard(suit: Suit.spades, rank: Rank.ace)));
    });

    test('parses "King of Hearts" → king of hearts', () {
      final result = CardTextParser.parse(['King of Hearts']);
      expect(result.detectedCards, contains(PokerCard(suit: Suit.hearts, rank: Rank.king)));
    });

    test('parses "queen of diamonds" (lowercase) → queen of diamonds', () {
      final result = CardTextParser.parse(['queen of diamonds']);
      expect(result.detectedCards,
          contains(PokerCard(suit: Suit.diamonds, rank: Rank.queen)));
    });

    test('parses "Jack of Clubs" → jack of clubs', () {
      final result = CardTextParser.parse(['Jack of Clubs']);
      expect(result.detectedCards, contains(PokerCard(suit: Suit.clubs, rank: Rank.jack)));
    });

    // -------------------------------------------------------------------------
    // Multiple cards in one token / multiple tokens
    // -------------------------------------------------------------------------

    test('parses multiple cards from separate tokens', () {
      final result = CardTextParser.parse(['Ah', 'Ks', 'Qd']);
      expect(result.detectedCards.length, 3);
      expect(result.isSuccessful, isTrue);
    });

    test('parses multiple cards embedded in same string', () {
      // Some OCR engines concatenate text — e.g. "AhKs"
      final result = CardTextParser.parse(['AhKs']);
      expect(result.detectedCards,
          containsAll([
            PokerCard(suit: Suit.hearts, rank: Rank.ace),
            PokerCard(suit: Suit.spades, rank: Rank.king),
          ]));
    });

    // -------------------------------------------------------------------------
    // Deduplication
    // -------------------------------------------------------------------------

    test('deduplicates duplicate cards', () {
      final result = CardTextParser.parse(['Ah', 'Ah', 'Ah']);
      expect(
        result.detectedCards
            .where((c) => c == PokerCard(suit: Suit.hearts, rank: Rank.ace))
            .length,
        1,
      );
    });

    test('deduplicates same card in different notation', () {
      // 'Ah' and 'A♥' both represent ace of hearts
      final result = CardTextParser.parse(['Ah', 'A♥']);
      expect(
        result.detectedCards
            .where((c) => c == PokerCard(suit: Suit.hearts, rank: Rank.ace))
            .length,
        1,
      );
    });

    // -------------------------------------------------------------------------
    // Invalid / garbage input
    // -------------------------------------------------------------------------

    test('handles empty list gracefully', () {
      final result = CardTextParser.parse([]);
      expect(result.detectedCards, isEmpty);
      expect(result.isSuccessful, isFalse);
    });

    test('handles empty string token gracefully', () {
      final result = CardTextParser.parse(['', '  ']);
      expect(result.detectedCards, isEmpty);
    });

    test('ignores pure garbage text', () {
      final result = CardTextParser.parse(['hello', 'world', '!!!', '12345']);
      expect(result.detectedCards, isEmpty);
    });

    test('does not crash on very long strings', () {
      final longText = 'x' * 10000;
      expect(() => CardTextParser.parse([longText]), returnsNormally);
    });

    test('does not crash on special characters', () {
      expect(() => CardTextParser.parse(['@#\$%^&*()']), returnsNormally);
    });

    // -------------------------------------------------------------------------
    // Mixed formats in the same scan
    // -------------------------------------------------------------------------

    test('handles mixed formats in the same token list', () {
      final result = CardTextParser.parse([
        'A♠',           // unicode suit
        'Kh',           // letter suit
        'Td',           // T = ten
        '2c',           // numeric rank + letter suit
        'Queen of Hearts', // full name
      ]);

      expect(
        result.detectedCards,
        containsAll([
          PokerCard(suit: Suit.spades, rank: Rank.ace),
          PokerCard(suit: Suit.hearts, rank: Rank.king),
          PokerCard(suit: Suit.diamonds, rank: Rank.ten),
          PokerCard(suit: Suit.clubs, rank: Rank.two),
          PokerCard(suit: Suit.hearts, rank: Rank.queen),
        ]),
      );
      expect(result.isSuccessful, isTrue);
    });

    // -------------------------------------------------------------------------
    // isSuccessful flag
    // -------------------------------------------------------------------------

    test('isSuccessful is true when at least one card is detected', () {
      final result = CardTextParser.parse(['Ah']);
      expect(result.isSuccessful, isTrue);
    });

    test('isSuccessful is false when no cards are detected', () {
      final result = CardTextParser.parse(['garbage']);
      expect(result.isSuccessful, isFalse);
    });

    // -------------------------------------------------------------------------
    // All ranks
    // -------------------------------------------------------------------------

    test('parses all ranks correctly', () {
      final tokens = [
        '2h', '3h', '4h', '5h', '6h', '7h',
        '8h', '9h', 'Th', 'Jh', 'Qh', 'Kh', 'Ah',
      ];
      final result = CardTextParser.parse(tokens);
      expect(result.detectedCards.length, 13);
    });

    // -------------------------------------------------------------------------
    // All suits
    // -------------------------------------------------------------------------

    test('parses all suits correctly', () {
      final tokens = ['Ah', 'Ad', 'Ac', 'As'];
      final result = CardTextParser.parse(tokens);
      expect(result.detectedCards.length, 4);
      expect(
        result.detectedCards.map((c) => c.suit).toSet(),
        {Suit.hearts, Suit.diamonds, Suit.clubs, Suit.spades},
      );
    });
  });
}
