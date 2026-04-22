import 'package:flutter_test/flutter_test.dart';
import 'package:poker_hand_suggester/engine/hand_evaluator.dart';
import 'package:poker_hand_suggester/models/card.dart';

// Helper: build a PokerCard quickly.
PokerCard c(Rank rank, Suit suit) => PokerCard(suit: suit, rank: rank);

void main() {
  group('HandEvaluator', () {
    test('detects royal flush', () {
      final cards = [
        c(Rank.ace, Suit.spades),
        c(Rank.king, Suit.spades),
        c(Rank.queen, Suit.spades),
        c(Rank.jack, Suit.spades),
        c(Rank.ten, Suit.spades),
      ];
      final result = HandEvaluator.evaluate(cards);
      expect(result.ranking, HandRanking.royalFlush);
    });

    test('detects straight flush', () {
      final cards = [
        c(Rank.nine, Suit.hearts),
        c(Rank.eight, Suit.hearts),
        c(Rank.seven, Suit.hearts),
        c(Rank.six, Suit.hearts),
        c(Rank.five, Suit.hearts),
      ];
      final result = HandEvaluator.evaluate(cards);
      expect(result.ranking, HandRanking.straightFlush);
    });

    test('detects four of a kind', () {
      final cards = [
        c(Rank.ace, Suit.spades),
        c(Rank.ace, Suit.hearts),
        c(Rank.ace, Suit.diamonds),
        c(Rank.ace, Suit.clubs),
        c(Rank.king, Suit.spades),
      ];
      final result = HandEvaluator.evaluate(cards);
      expect(result.ranking, HandRanking.fourOfAKind);
    });

    test('detects full house', () {
      final cards = [
        c(Rank.king, Suit.spades),
        c(Rank.king, Suit.hearts),
        c(Rank.king, Suit.diamonds),
        c(Rank.queen, Suit.clubs),
        c(Rank.queen, Suit.spades),
      ];
      final result = HandEvaluator.evaluate(cards);
      expect(result.ranking, HandRanking.fullHouse);
    });

    test('detects flush', () {
      final cards = [
        c(Rank.ace, Suit.clubs),
        c(Rank.ten, Suit.clubs),
        c(Rank.seven, Suit.clubs),
        c(Rank.four, Suit.clubs),
        c(Rank.two, Suit.clubs),
      ];
      final result = HandEvaluator.evaluate(cards);
      expect(result.ranking, HandRanking.flush);
    });

    test('detects straight', () {
      final cards = [
        c(Rank.nine, Suit.spades),
        c(Rank.eight, Suit.hearts),
        c(Rank.seven, Suit.diamonds),
        c(Rank.six, Suit.clubs),
        c(Rank.five, Suit.spades),
      ];
      final result = HandEvaluator.evaluate(cards);
      expect(result.ranking, HandRanking.straight);
    });

    test('detects ace-low straight (A-2-3-4-5)', () {
      final cards = [
        c(Rank.ace, Suit.spades),
        c(Rank.two, Suit.hearts),
        c(Rank.three, Suit.diamonds),
        c(Rank.four, Suit.clubs),
        c(Rank.five, Suit.spades),
      ];
      final result = HandEvaluator.evaluate(cards);
      expect(result.ranking, HandRanking.straight);
    });

    test('detects three of a kind', () {
      final cards = [
        c(Rank.queen, Suit.spades),
        c(Rank.queen, Suit.hearts),
        c(Rank.queen, Suit.diamonds),
        c(Rank.king, Suit.clubs),
        c(Rank.two, Suit.spades),
      ];
      final result = HandEvaluator.evaluate(cards);
      expect(result.ranking, HandRanking.threeOfAKind);
    });

    test('detects two pair', () {
      final cards = [
        c(Rank.jack, Suit.spades),
        c(Rank.jack, Suit.hearts),
        c(Rank.ten, Suit.diamonds),
        c(Rank.ten, Suit.clubs),
        c(Rank.ace, Suit.spades),
      ];
      final result = HandEvaluator.evaluate(cards);
      expect(result.ranking, HandRanking.twoPair);
    });

    test('detects one pair', () {
      final cards = [
        c(Rank.ace, Suit.spades),
        c(Rank.ace, Suit.hearts),
        c(Rank.king, Suit.diamonds),
        c(Rank.queen, Suit.clubs),
        c(Rank.jack, Suit.spades),
      ];
      final result = HandEvaluator.evaluate(cards);
      expect(result.ranking, HandRanking.onePair);
    });

    test('detects high card', () {
      final cards = [
        c(Rank.ace, Suit.spades),
        c(Rank.king, Suit.hearts),
        c(Rank.queen, Suit.diamonds),
        c(Rank.jack, Suit.clubs),
        c(Rank.nine, Suit.spades),
      ];
      final result = HandEvaluator.evaluate(cards);
      expect(result.ranking, HandRanking.highCard);
    });

    test('best hand selected from 7 cards', () {
      // Hole: A♠ K♠   Board: Q♠ J♠ 10♠ 2♥ 3♦ → royal flush in spades
      final cards = [
        c(Rank.ace, Suit.spades),
        c(Rank.king, Suit.spades),
        c(Rank.queen, Suit.spades),
        c(Rank.jack, Suit.spades),
        c(Rank.ten, Suit.spades),
        c(Rank.two, Suit.hearts),
        c(Rank.three, Suit.diamonds),
      ];
      final result = HandEvaluator.evaluate(cards);
      expect(result.ranking, HandRanking.royalFlush);
    });

    test('higher ranking beats lower ranking', () {
      final flush = HandEvaluator.evaluate([
        c(Rank.ace, Suit.clubs),
        c(Rank.ten, Suit.clubs),
        c(Rank.seven, Suit.clubs),
        c(Rank.four, Suit.clubs),
        c(Rank.two, Suit.clubs),
      ]);
      final straight = HandEvaluator.evaluate([
        c(Rank.nine, Suit.spades),
        c(Rank.eight, Suit.hearts),
        c(Rank.seven, Suit.diamonds),
        c(Rank.six, Suit.clubs),
        c(Rank.five, Suit.spades),
      ]);
      expect(flush.compareTo(straight), greaterThan(0));
    });

    test('HandResult compareTo is consistent', () {
      final rf = HandEvaluator.evaluate([
        c(Rank.ace, Suit.spades),
        c(Rank.king, Suit.spades),
        c(Rank.queen, Suit.spades),
        c(Rank.jack, Suit.spades),
        c(Rank.ten, Suit.spades),
      ]);
      final hc = HandEvaluator.evaluate([
        c(Rank.two, Suit.hearts),
        c(Rank.four, Suit.diamonds),
        c(Rank.six, Suit.clubs),
        c(Rank.eight, Suit.spades),
        c(Rank.king, Suit.hearts),
      ]);
      expect(rf.compareTo(hc), greaterThan(0));
      expect(hc.compareTo(rf), lessThan(0));
    });

    // ---- Edge-case tests --------------------------------------------------

    test('straight flush ranks above four of a kind', () {
      final sf = HandEvaluator.evaluate([
        c(Rank.nine, Suit.hearts),
        c(Rank.eight, Suit.hearts),
        c(Rank.seven, Suit.hearts),
        c(Rank.six, Suit.hearts),
        c(Rank.five, Suit.hearts),
      ]);
      final quads = HandEvaluator.evaluate([
        c(Rank.ace, Suit.spades),
        c(Rank.ace, Suit.hearts),
        c(Rank.ace, Suit.diamonds),
        c(Rank.ace, Suit.clubs),
        c(Rank.king, Suit.spades),
      ]);
      expect(sf.compareTo(quads), greaterThan(0));
    });

    test('full house — higher trips wins', () {
      final kingsOverTwos = HandEvaluator.evaluate([
        c(Rank.king, Suit.spades),
        c(Rank.king, Suit.hearts),
        c(Rank.king, Suit.diamonds),
        c(Rank.two, Suit.clubs),
        c(Rank.two, Suit.spades),
      ]);
      final queensOverAces = HandEvaluator.evaluate([
        c(Rank.queen, Suit.spades),
        c(Rank.queen, Suit.hearts),
        c(Rank.queen, Suit.diamonds),
        c(Rank.ace, Suit.clubs),
        c(Rank.ace, Suit.spades),
      ]);
      // K-K-K-2-2 beats Q-Q-Q-A-A (trips K > trips Q)
      expect(kingsOverTwos.compareTo(queensOverAces), greaterThan(0));
    });

    test('two pair ranks above one pair', () {
      final twoPair = HandEvaluator.evaluate([
        c(Rank.jack, Suit.spades),
        c(Rank.jack, Suit.hearts),
        c(Rank.ten, Suit.diamonds),
        c(Rank.ten, Suit.clubs),
        c(Rank.ace, Suit.spades),
      ]);
      final onePair = HandEvaluator.evaluate([
        c(Rank.ace, Suit.spades),
        c(Rank.ace, Suit.hearts),
        c(Rank.king, Suit.diamonds),
        c(Rank.queen, Suit.clubs),
        c(Rank.jack, Suit.spades),
      ]);
      expect(twoPair.compareTo(onePair), greaterThan(0));
    });

    test('high card — ace-high beats king-high', () {
      final aceHigh = HandEvaluator.evaluate([
        c(Rank.ace, Suit.spades),
        c(Rank.king, Suit.hearts),
        c(Rank.queen, Suit.diamonds),
        c(Rank.jack, Suit.clubs),
        c(Rank.nine, Suit.spades),
      ]);
      final kingHigh = HandEvaluator.evaluate([
        c(Rank.king, Suit.spades),
        c(Rank.queen, Suit.hearts),
        c(Rank.jack, Suit.diamonds),
        c(Rank.ten, Suit.clubs),
        c(Rank.eight, Suit.spades),
      ]);
      expect(aceHigh.compareTo(kingHigh), greaterThan(0));
    });

    test('ace-low straight ranks below a normal straight', () {
      final aceLow = HandEvaluator.evaluate([
        c(Rank.ace, Suit.spades),
        c(Rank.two, Suit.hearts),
        c(Rank.three, Suit.diamonds),
        c(Rank.four, Suit.clubs),
        c(Rank.five, Suit.spades),
      ]);
      final sixHighStraight = HandEvaluator.evaluate([
        c(Rank.six, Suit.spades),
        c(Rank.five, Suit.hearts),
        c(Rank.four, Suit.diamonds),
        c(Rank.three, Suit.clubs),
        c(Rank.two, Suit.spades),
      ]);
      // Both are straights, but 6-high beats 5-high (ace-low)
      expect(sixHighStraight.compareTo(aceLow), greaterThan(0));
    });

    test(
      '7-card hand: best 5-of-7 beats a lesser 5-card combo from same set',
      () {
        // Hole: 9♥ 8♥   Board: 7♥ 6♥ 5♥ 2♦ 3♣ → best 5 is 9-8-7-6-5 straight flush
        final cards = [
          c(Rank.nine, Suit.hearts),
          c(Rank.eight, Suit.hearts),
          c(Rank.seven, Suit.hearts),
          c(Rank.six, Suit.hearts),
          c(Rank.five, Suit.hearts),
          c(Rank.two, Suit.diamonds),
          c(Rank.three, Suit.clubs),
        ];
        final result = HandEvaluator.evaluate(cards);
        expect(result.ranking, HandRanking.straightFlush);
      },
    );
  });
}
