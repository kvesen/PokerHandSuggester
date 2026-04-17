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

  /// Number of Monte Carlo iterations actually run.
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
  /// [holeCards]           – the player's two private cards.
  /// [communityCards]      – currently visible community cards (0–5).
  /// [numOpponents]        – number of active opponents.
  /// [iterations]          – maximum number of random runouts to simulate.
  /// [seed]                – optional RNG seed for reproducibility in tests.
  /// [targetStandardError] – if non-null, stop early once the standard error
  ///                         of the win-rate estimate drops to or below this
  ///                         value (minimum [kMinAdaptiveIterations] iters).
  ///                         Pass `null` to always run all [iterations].
  static EquityResult calculate({
    required List<PokerCard> holeCards,
    required List<PokerCard> communityCards,
    required int numOpponents,
    int iterations = kDefaultSimulationIterations,
    int? seed,
    double? targetStandardError,
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

    // Allocate the working buffer once before the loop.
    // After each partial Fisher-Yates shuffle the list remains a valid
    // permutation of the original deck, so we can reuse it across iterations
    // without resetting — each new shuffle randomises from the current state.
    final shuffled = List<PokerCard>.of(deck);

    // Pre-allocate hand lists to avoid per-iteration allocations.
    final playerHand = List<PokerCard>.filled(7, holeCards[0], growable: false);
    final oppHand = List<PokerCard>.filled(7, holeCards[0], growable: false);

    // Populate player hole cards (fixed across all iterations).
    playerHand[0] = holeCards[0];
    playerHand[1] = holeCards[1];

    // Populate known community cards (fixed across all iterations).
    for (int k = 0; k < communityCards.length; k++) {
      playerHand[2 + k] = communityCards[k];
    }

    // Check-interval for adaptive early termination (every N iterations).
    const int kCheckInterval = 500;

    for (int i = 0; i < iterations; i++) {
      // Partial Fisher-Yates: only randomise the slots we actually use.
      // The list stays a permutation of the original deck across iterations,
      // so no reset is needed — continuing the shuffle from the previous state
      // is equivalent to drawing fresh random cards each time.
      for (int s = 0; s < totalCardsNeeded; s++) {
        final j = s + rng.nextInt(shuffled.length - s);
        final tmp = shuffled[s];
        shuffled[s] = shuffled[j];
        shuffled[j] = tmp;
      }

      // Fill simulated community cards into the player hand buffer.
      for (int k = 0; k < communityNeeded; k++) {
        playerHand[2 + communityCards.length + k] = shuffled[k];
      }

      // Deal opponent hole cards and evaluate.
      final opponentResults = <HandResult>[];
      for (int o = 0; o < numOpponents; o++) {
        final start = communityNeeded + o * cardsPerOpponent;
        oppHand[0] = shuffled[start];
        oppHand[1] = shuffled[start + 1];
        for (int k = 0; k < communityNeeded; k++) {
          oppHand[2 + k] = shuffled[k];
        }
        for (int k = 0; k < communityCards.length; k++) {
          oppHand[2 + communityNeeded + k] = communityCards[k];
        }
        opponentResults.add(HandEvaluator.evaluate(oppHand.sublist(0, 7)));
      }

      final playerResult = HandEvaluator.evaluate(playerHand);

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

      // Adaptive early termination: check every kCheckInterval iterations.
      if (targetStandardError != null &&
          (i + 1) >= kMinAdaptiveIterations &&
          (i + 1) % kCheckInterval == 0) {
        final n = i + 1;
        final p = (wins + ties * 0.5) / n;
        final se = sqrt(p * (1 - p) / n);
        if (se <= targetStandardError) {
          final actualIter = n;
          return EquityResult(
            winProbability: wins / actualIter,
            tieProbability: ties / actualIter,
            lossProbability: losses / actualIter,
            iterations: actualIter,
          );
        }
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
