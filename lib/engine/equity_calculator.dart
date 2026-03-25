/// Monte Carlo equity calculator.
library;

import 'dart:math';

import '../models/card.dart';
import 'hand_evaluator.dart';
import '../utils/constants.dart';

/// The result of a Monte Carlo equity simulation.
class EquityResult {
  const EquityResult({
    required this.winProbability,
    required this.tieProbability,
    required this.lossProbability,
    required this.iterations,
  });

  /// Fraction of simulations where the player wins outright.
  final double winProbability;

  /// Fraction of simulations that end in a tie (split pot).
  final double tieProbability;

  /// Fraction of simulations where the player loses.
  final double lossProbability;

  /// Number of Monte Carlo iterations run.
  final int iterations;

  /// Overall equity = wins + half of ties.
  double get equity => winProbability + tieProbability / 2;

  @override
  String toString() =>
      'Win: ${(winProbability * 100).toStringAsFixed(1)}% '
      'Tie: ${(tieProbability * 100).toStringAsFixed(1)}% '
      'Loss: ${(lossProbability * 100).toStringAsFixed(1)}%';
}

/// Estimates hand equity via Monte Carlo simulation.
class EquityCalculator {
  /// Runs a Monte Carlo simulation.
  ///
  /// [holeCards]      – the player's two private cards.
  /// [communityCards] – currently visible community cards (0–5).
  /// [numOpponents]   – number of active opponents.
  /// [iterations]     – number of random runouts to simulate.
  /// [seed]           – optional RNG seed for reproducibility in tests.
  static EquityResult calculate({
    required List<PokerCard> holeCards,
    required List<PokerCard> communityCards,
    required int numOpponents,
    int iterations = kDefaultSimulationIterations,
    int? seed,
  }) {
    assert(holeCards.length == 2);
    assert(communityCards.length <= 5);
    assert(numOpponents >= 1);

    final rng = seed != null ? Random(seed) : Random();

    // Build the remaining deck (exclude known cards).
    final knownCards = {...holeCards, ...communityCards};
    final deck =
        PokerCard.fullDeck().where((c) => !knownCards.contains(c)).toList();

    final int communityNeeded = 5 - communityCards.length;
    final int cardsPerOpponent = 2;
    final int totalCardsNeeded = communityNeeded + numOpponents * cardsPerOpponent;

    // Guard: not enough cards to run simulation (degenerate state).
    if (deck.length < totalCardsNeeded) {
      return const EquityResult(
        winProbability: 0,
        tieProbability: 0,
        lossProbability: 1,
        iterations: 0,
      );
    }

    int wins = 0;
    int ties = 0;
    int losses = 0;

    for (int i = 0; i < iterations; i++) {
      // Partial Fisher-Yates: only randomise the slots we actually use.
      final shuffled = List<PokerCard>.of(deck);
      for (int s = 0; s < totalCardsNeeded; s++) {
        final j = s + rng.nextInt(shuffled.length - s);
        final tmp = shuffled[s];
        shuffled[s] = shuffled[j];
        shuffled[j] = tmp;
      }

      // Deal community cards.
      final simCommunity = [
        ...communityCards,
        ...shuffled.sublist(0, communityNeeded),
      ];

      // Deal opponent hole cards.
      final opponentResults = <HandResult>[];
      for (int o = 0; o < numOpponents; o++) {
        final start = communityNeeded + o * cardsPerOpponent;
        final oppHole = shuffled.sublist(start, start + cardsPerOpponent);
        opponentResults.add(
          HandEvaluator.evaluate([...oppHole, ...simCommunity]),
        );
      }

      final playerResult =
          HandEvaluator.evaluate([...holeCards, ...simCommunity]);

      final bestOpponent =
          opponentResults.reduce((a, b) => a.compareTo(b) >= 0 ? a : b);

      final cmp = playerResult.compareTo(bestOpponent);
      if (cmp > 0) {
        wins++;
      } else if (cmp == 0) {
        ties++;
      } else {
        losses++;
      }
    }

    return EquityResult(
      winProbability: wins / iterations,
      tieProbability: ties / iterations,
      lossProbability: losses / iterations,
      iterations: iterations,
    );
  }
}
