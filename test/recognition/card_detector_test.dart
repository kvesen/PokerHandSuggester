import 'package:flutter_test/flutter_test.dart';
import 'package:poker_hand_suggester/models/card.dart';
import 'package:poker_hand_suggester/recognition/card_detector.dart';

void main() {
  group('CardDetector.labelToPokerCard', () {
    // -------------------------------------------------------------------------
    // Valid labels — all ranks
    // -------------------------------------------------------------------------

    test('parses ace_spades', () {
      final card = CardDetector.labelToPokerCard('ace_spades');
      expect(card, PokerCard(suit: Suit.spades, rank: Rank.ace));
    });

    test('parses king_hearts', () {
      final card = CardDetector.labelToPokerCard('king_hearts');
      expect(card, PokerCard(suit: Suit.hearts, rank: Rank.king));
    });

    test('parses queen_diamonds', () {
      final card = CardDetector.labelToPokerCard('queen_diamonds');
      expect(card, PokerCard(suit: Suit.diamonds, rank: Rank.queen));
    });

    test('parses jack_clubs', () {
      final card = CardDetector.labelToPokerCard('jack_clubs');
      expect(card, PokerCard(suit: Suit.clubs, rank: Rank.jack));
    });

    test('parses 10_spades', () {
      final card = CardDetector.labelToPokerCard('10_spades');
      expect(card, PokerCard(suit: Suit.spades, rank: Rank.ten));
    });

    test('parses 9_hearts', () {
      final card = CardDetector.labelToPokerCard('9_hearts');
      expect(card, PokerCard(suit: Suit.hearts, rank: Rank.nine));
    });

    test('parses 8_diamonds', () {
      final card = CardDetector.labelToPokerCard('8_diamonds');
      expect(card, PokerCard(suit: Suit.diamonds, rank: Rank.eight));
    });

    test('parses 7_clubs', () {
      final card = CardDetector.labelToPokerCard('7_clubs');
      expect(card, PokerCard(suit: Suit.clubs, rank: Rank.seven));
    });

    test('parses 6_spades', () {
      final card = CardDetector.labelToPokerCard('6_spades');
      expect(card, PokerCard(suit: Suit.spades, rank: Rank.six));
    });

    test('parses 5_hearts', () {
      final card = CardDetector.labelToPokerCard('5_hearts');
      expect(card, PokerCard(suit: Suit.hearts, rank: Rank.five));
    });

    test('parses 4_diamonds', () {
      final card = CardDetector.labelToPokerCard('4_diamonds');
      expect(card, PokerCard(suit: Suit.diamonds, rank: Rank.four));
    });

    test('parses 3_clubs', () {
      final card = CardDetector.labelToPokerCard('3_clubs');
      expect(card, PokerCard(suit: Suit.clubs, rank: Rank.three));
    });

    test('parses 2_spades', () {
      final card = CardDetector.labelToPokerCard('2_spades');
      expect(card, PokerCard(suit: Suit.spades, rank: Rank.two));
    });

    // -------------------------------------------------------------------------
    // Valid labels — all suits
    // -------------------------------------------------------------------------

    test('parses ace_spades (spades suit)', () {
      final card = CardDetector.labelToPokerCard('ace_spades');
      expect(card?.suit, Suit.spades);
    });

    test('parses ace_hearts (hearts suit)', () {
      final card = CardDetector.labelToPokerCard('ace_hearts');
      expect(card?.suit, Suit.hearts);
    });

    test('parses ace_diamonds (diamonds suit)', () {
      final card = CardDetector.labelToPokerCard('ace_diamonds');
      expect(card?.suit, Suit.diamonds);
    });

    test('parses ace_clubs (clubs suit)', () {
      final card = CardDetector.labelToPokerCard('ace_clubs');
      expect(card?.suit, Suit.clubs);
    });

    // -------------------------------------------------------------------------
    // Case-insensitive
    // -------------------------------------------------------------------------

    test('parses label with uppercase', () {
      final card = CardDetector.labelToPokerCard('ACE_SPADES');
      expect(card, PokerCard(suit: Suit.spades, rank: Rank.ace));
    });

    test('parses label with mixed case', () {
      final card = CardDetector.labelToPokerCard('King_Hearts');
      expect(card, PokerCard(suit: Suit.hearts, rank: Rank.king));
    });

    // -------------------------------------------------------------------------
    // All 52 labels round-trip
    // -------------------------------------------------------------------------

    test('parses all 52 labels from card_labels.txt format', () {
      const labels = [
        'ace_spades', '2_spades', '3_spades', '4_spades', '5_spades',
        '6_spades', '7_spades', '8_spades', '9_spades', '10_spades',
        'jack_spades', 'queen_spades', 'king_spades',
        'ace_hearts', '2_hearts', '3_hearts', '4_hearts', '5_hearts',
        '6_hearts', '7_hearts', '8_hearts', '9_hearts', '10_hearts',
        'jack_hearts', 'queen_hearts', 'king_hearts',
        'ace_diamonds', '2_diamonds', '3_diamonds', '4_diamonds', '5_diamonds',
        '6_diamonds', '7_diamonds', '8_diamonds', '9_diamonds', '10_diamonds',
        'jack_diamonds', 'queen_diamonds', 'king_diamonds',
        'ace_clubs', '2_clubs', '3_clubs', '4_clubs', '5_clubs',
        '6_clubs', '7_clubs', '8_clubs', '9_clubs', '10_clubs',
        'jack_clubs', 'queen_clubs', 'king_clubs',
      ];

      final cards = labels.map(CardDetector.labelToPokerCard).toList();
      expect(cards.every((c) => c != null), isTrue,
          reason: 'Every label should map to a valid PokerCard');
      expect(cards.toSet().length, 52,
          reason: 'All 52 labels should produce distinct cards');
    });

    // -------------------------------------------------------------------------
    // Invalid labels → null
    // -------------------------------------------------------------------------

    test('returns null for empty string', () {
      expect(CardDetector.labelToPokerCard(''), isNull);
    });

    test('returns null for label without underscore', () {
      expect(CardDetector.labelToPokerCard('acespades'), isNull);
    });

    test('returns null for unknown rank', () {
      expect(CardDetector.labelToPokerCard('joker_spades'), isNull);
    });

    test('returns null for unknown suit', () {
      expect(CardDetector.labelToPokerCard('ace_stars'), isNull);
    });

    test('returns null for too many parts', () {
      expect(CardDetector.labelToPokerCard('ace_of_spades'), isNull);
    });

    test('returns null for garbage input', () {
      expect(CardDetector.labelToPokerCard('hello_world'), isNull);
    });

    test('does not throw on very long strings', () {
      expect(
        () => CardDetector.labelToPokerCard('x' * 10000),
        returnsNormally,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // DetectionResult
  // ---------------------------------------------------------------------------

  group('DetectionResult', () {
    test('isSuccessful is true when detectedCards is non-empty', () {
      final result = DetectionResult(
        detectedCards: [PokerCard(suit: Suit.spades, rank: Rank.ace)],
        unrecognizedTexts: [],
      );
      expect(result.isSuccessful, isTrue);
    });

    test('isSuccessful is false when detectedCards is empty', () {
      const result = DetectionResult(
        detectedCards: [],
        unrecognizedTexts: [],
      );
      expect(result.isSuccessful, isFalse);
    });

    test('defaults detections to empty list', () {
      const result = DetectionResult(
        detectedCards: [],
        unrecognizedTexts: [],
      );
      expect(result.detections, isEmpty);
    });
  });
}

