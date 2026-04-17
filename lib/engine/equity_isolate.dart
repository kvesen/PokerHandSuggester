/// Background isolate helper for Monte Carlo equity calculation.
library;

import '../models/card.dart';
import '../utils/constants.dart';
import 'equity_calculator.dart';

/// Serializable parameters for [runEquityCalculation].
class EquityIsolateParams {
  const EquityIsolateParams({
    required this.holeCards,
    required this.communityCards,
    required this.numOpponents,
    this.iterations = 10000,
    this.targetStandardError = kDefaultTargetStandardError,
  });

  final List<PokerCard> holeCards;
  final List<PokerCard> communityCards;
  final int numOpponents;
  final int iterations;
  final double? targetStandardError;
}

/// Top-level function suitable for use with [Isolate.run].
///
/// Usage:
/// ```dart
/// final result = await Isolate.run(
///   () => runEquityCalculation(params),
/// );
/// ```
EquityResult runEquityCalculation(EquityIsolateParams params) {
  return EquityCalculator.calculate(
    holeCards: params.holeCards,
    communityCards: params.communityCards,
    numOpponents: params.numOpponents,
    iterations: params.iterations,
    targetStandardError: params.targetStandardError,
  );
}
