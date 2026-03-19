import 'package:flutter_test/flutter_test.dart';
import 'package:poker_hand_suggester/engine/equity_calculator.dart';
import 'package:poker_hand_suggester/models/card.dart';

void main() {
  group('EquityCalculator', () {
    test('EquityResult.equity = win + tie/2', () {
      const result = EquityResult(
        winProbability: 0.5,
        tieProbability: 0.2,
        lossProbability: 0.3,
        iterations: 1000,
      );
      expect(result.equity, closeTo(0.6, 0.0001));
    });

    test('probabilities sum to 1', () {
      final result = EquityCalculator.calculate(
        holeCards: [
          const PokerCard(suit: Suit.spades, rank: Rank.ace),
          const PokerCard(suit: Suit.spades, rank: Rank.king),
        ],
        communityCards: [],
        numOpponents: 1,
        iterations: 500,
        seed: 42,
      );
      final sum =
          result.winProbability + result.tieProbability + result.lossProbability;
      expect(sum, closeTo(1.0, 0.0001));
    });

    test('strong hand has better equity than weak hand', () {
      // Pocket aces vs garbage
      final aces = EquityCalculator.calculate(
        holeCards: [
          const PokerCard(suit: Suit.spades, rank: Rank.ace),
          const PokerCard(suit: Suit.hearts, rank: Rank.ace),
        ],
        communityCards: [],
        numOpponents: 1,
        iterations: 2000,
        seed: 1,
      );

      final twos = EquityCalculator.calculate(
        holeCards: [
          const PokerCard(suit: Suit.spades, rank: Rank.two),
          const PokerCard(suit: Suit.hearts, rank: Rank.seven),
        ],
        communityCards: [],
        numOpponents: 1,
        iterations: 2000,
        seed: 1,
      );

      expect(aces.equity, greaterThan(twos.equity));
    });

    test('with community cards already dealt, still calculates equity', () {
      final result = EquityCalculator.calculate(
        holeCards: [
          const PokerCard(suit: Suit.spades, rank: Rank.ace),
          const PokerCard(suit: Suit.spades, rank: Rank.king),
        ],
        communityCards: [
          const PokerCard(suit: Suit.spades, rank: Rank.queen),
          const PokerCard(suit: Suit.spades, rank: Rank.jack),
          const PokerCard(suit: Suit.hearts, rank: Rank.two),
        ],
        numOpponents: 1,
        iterations: 500,
        seed: 7,
      );
      expect(result.iterations, 500);
      final sum =
          result.winProbability + result.tieProbability + result.lossProbability;
      expect(sum, closeTo(1.0, 0.0001));
    });

    test('iterations count is stored in result', () {
      final result = EquityCalculator.calculate(
        holeCards: [
          const PokerCard(suit: Suit.clubs, rank: Rank.five),
          const PokerCard(suit: Suit.diamonds, rank: Rank.six),
        ],
        communityCards: [],
        numOpponents: 1,
        iterations: 100,
        seed: 0,
      );
      expect(result.iterations, 100);
    });
  });
}
