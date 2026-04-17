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

    // ---- Edge-case tests --------------------------------------------------

    test('pocket aces preflop equity > 80% against one opponent', () {
      final result = EquityCalculator.calculate(
        holeCards: [
          const PokerCard(suit: Suit.spades, rank: Rank.ace),
          const PokerCard(suit: Suit.hearts, rank: Rank.ace),
        ],
        communityCards: [],
        numOpponents: 1,
        iterations: 2000,
        seed: 99,
      );
      expect(result.equity, greaterThan(0.80));
    });

    test('equity decreases as number of opponents increases', () {
      const holeCards = [
        PokerCard(suit: Suit.spades, rank: Rank.ace),
        PokerCard(suit: Suit.hearts, rank: Rank.ace),
      ];
      final oneOpponent = EquityCalculator.calculate(
        holeCards: holeCards,
        communityCards: [],
        numOpponents: 1,
        iterations: 2000,
        seed: 42,
      );
      final fourOpponents = EquityCalculator.calculate(
        holeCards: holeCards,
        communityCards: [],
        numOpponents: 4,
        iterations: 2000,
        seed: 42,
      );
      expect(oneOpponent.equity, greaterThan(fourOpponents.equity));
    });

    test('river (5 community cards) — result is determined (win or loss or tie)', () {
      // With all 5 community cards known, every simulation should yield the
      // same outcome, so one of the probabilities should be 1.0.
      final result = EquityCalculator.calculate(
        holeCards: [
          const PokerCard(suit: Suit.spades, rank: Rank.ace),
          const PokerCard(suit: Suit.spades, rank: Rank.king),
        ],
        communityCards: [
          const PokerCard(suit: Suit.spades, rank: Rank.queen),
          const PokerCard(suit: Suit.spades, rank: Rank.jack),
          const PokerCard(suit: Suit.spades, rank: Rank.ten),
          const PokerCard(suit: Suit.hearts, rank: Rank.two),
          const PokerCard(suit: Suit.hearts, rank: Rank.three),
        ],
        numOpponents: 1,
        iterations: 100,
        seed: 7,
      );
      // Win probability should be 1.0 (royal flush beats everything)
      expect(result.winProbability, closeTo(1.0, 0.0001));
    });

    test('pocket pair vs overcards — pair is roughly 50-50', () {
      // 2-2 vs A-K offsuit is a classic "coin flip" (pair is slight favourite)
      final result = EquityCalculator.calculate(
        holeCards: [
          const PokerCard(suit: Suit.spades, rank: Rank.two),
          const PokerCard(suit: Suit.hearts, rank: Rank.two),
        ],
        communityCards: [],
        numOpponents: 1,
        iterations: 3000,
        seed: 11,
      );
      // Pair is typically 52-55% favourite; keep range wide for Monte Carlo variance
      expect(result.equity, greaterThan(0.40));
      expect(result.equity, lessThan(0.70));
    });

    test('split-pot scenario produces non-zero tie probability', () {
      // Identical hole cards in different suits can tie frequently on certain boards.
      // Use a board that makes the best hand entirely on the community cards.
      final result = EquityCalculator.calculate(
        holeCards: [
          const PokerCard(suit: Suit.spades, rank: Rank.two),
          const PokerCard(suit: Suit.hearts, rank: Rank.three),
        ],
        communityCards: [
          const PokerCard(suit: Suit.diamonds, rank: Rank.ace),
          const PokerCard(suit: Suit.clubs, rank: Rank.ace),
          const PokerCard(suit: Suit.spades, rank: Rank.ace),
          const PokerCard(suit: Suit.hearts, rank: Rank.ace),
          const PokerCard(suit: Suit.diamonds, rank: Rank.king),
        ],
        numOpponents: 1,
        iterations: 500,
        seed: 5,
      );
      // With four aces on the board the best hand is quad aces + king kicker,
      // which is the same for everyone → all ties.
      expect(result.tieProbability, greaterThan(0.0));
    });

    group('adaptive early termination', () {
      test('targetStandardError: null runs all iterations (current behavior)', () {
        final result = EquityCalculator.calculate(
          holeCards: [
            const PokerCard(suit: Suit.spades, rank: Rank.ace),
            const PokerCard(suit: Suit.hearts, rank: Rank.ace),
          ],
          communityCards: [],
          numOpponents: 1,
          iterations: 1000,
          seed: 42,
          targetStandardError: null,
        );
        expect(result.iterations, 1000);
      });

      test('loose targetStandardError stops early for obvious hand (pocket aces)', () {
        final result = EquityCalculator.calculate(
          holeCards: [
            const PokerCard(suit: Suit.spades, rank: Rank.ace),
            const PokerCard(suit: Suit.hearts, rank: Rank.ace),
          ],
          communityCards: [],
          numOpponents: 1,
          iterations: 10000,
          seed: 42,
          targetStandardError: 0.02,
        );
        // Pocket aces converges quickly; should stop well before 10000
        expect(result.iterations, lessThan(10000));
        // Equity should still be reasonable
        expect(result.equity, greaterThan(0.75));
      });

      test('tight targetStandardError runs near ceiling for marginal hand', () {
        // A marginal hand (2h-3h preflop) against one opponent should need
        // many iterations to converge to a very tight SE of 0.001
        final result = EquityCalculator.calculate(
          holeCards: [
            const PokerCard(suit: Suit.hearts, rank: Rank.two),
            const PokerCard(suit: Suit.hearts, rank: Rank.three),
          ],
          communityCards: [],
          numOpponents: 1,
          iterations: 5000,
          seed: 42,
          targetStandardError: 0.001,
        );
        // With such a tight target, should run all 5000 iterations
        expect(result.iterations, 5000);
      });
    });
  });
}
