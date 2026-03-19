/// Decision engine: combines equity and pot odds to recommend an action.
library;

import 'pot_odds.dart';
import '../models/position.dart';

/// The three possible player actions.
enum PlayerAction { fold, call, raise }

/// The full recommendation produced by the decision engine.
class Decision {
  const Decision({
    required this.action,
    required this.equity,
    required this.potOdds,
    required this.expectedValue,
    required this.explanation,
  });

  /// Recommended action (fold / call / raise).
  final PlayerAction action;

  /// Player's estimated equity (0–1).
  final double equity;

  /// Pot odds required to break even (0–1).
  final double potOdds;

  /// Expected value of calling: `equity * pot - (1 - equity) * costToCall`.
  final double expectedValue;

  /// Human-readable explanation of the recommendation.
  final String explanation;

  /// Equity as a percentage string (e.g. "42.3%").
  String get equityPercent => '${(equity * 100).toStringAsFixed(1)}%';

  /// Pot odds as a percentage string (e.g. "33.3%").
  String get potOddsPercent => '${(potOdds * 100).toStringAsFixed(1)}%';

  /// EV formatted as a rounded integer (e.g. "+15" or "-8").
  String get evFormatted =>
      expectedValue >= 0
          ? '+${expectedValue.toStringAsFixed(1)}'
          : expectedValue.toStringAsFixed(1);
}

/// Calculates the optimal poker decision.
class DecisionEngine {
  /// Evaluates the current game state and returns a [Decision].
  ///
  /// [equity]       – estimated win probability (0–1) from equity calculator.
  /// [pot]          – total chips currently in the pot.
  /// [costToCall]   – chips required to stay in the hand.
  /// [heroPosition] – optional table position; adjusts raise/call thresholds.
  static Decision decide({
    required double equity,
    required double pot,
    required double costToCall,
    TablePosition? heroPosition,
  }) {
    final potOddsRequired =
        PotOdds.requiredEquity(pot: pot, costToCall: costToCall);
    final ev = equity * pot - (1 - equity) * costToCall;

    // Position multiplier: > 1.0 → play more aggressively (e.g. BTN),
    // < 1.0 → play tighter (e.g. UTG).
    final double multiplier =
        heroPosition != null ? positionMultiplier(heroPosition) : 1.0;

    // Raise threshold is position-adjusted: easier to raise from the button,
    // harder from early position.
    final double raiseThreshold = 1.5 / multiplier;

    // Free-check raise threshold: also position-adjusted.
    final double freeCheckRaiseThreshold = 0.6 / multiplier;

    final PlayerAction action;
    final String baseExplanation;

    if (costToCall <= 0) {
      // Free to check — always at least call (check).
      if (equity >= freeCheckRaiseThreshold) {
        action = PlayerAction.raise;
        baseExplanation =
            'You can check for free, but with ${(equity * 100).toStringAsFixed(1)}% equity '
            'you have a strong hand — raise to build the pot.';
      } else {
        action = PlayerAction.call;
        baseExplanation =
            'No bet to call. Check and see the next card for free.';
      }
    } else if (equity < potOddsRequired) {
      action = PlayerAction.fold;
      baseExplanation =
          'Your equity (${(equity * 100).toStringAsFixed(1)}%) is less than '
          'the pot odds required (${(potOddsRequired * 100).toStringAsFixed(1)}%). '
          'Calling has negative expected value (EV = $ev). Fold.';
    } else if (equity < potOddsRequired * raiseThreshold) {
      action = PlayerAction.call;
      baseExplanation =
          'Your equity (${(equity * 100).toStringAsFixed(1)}%) meets but does not '
          'greatly exceed pot odds (${(potOddsRequired * 100).toStringAsFixed(1)}%). '
          'Calling is marginally profitable (EV = ${ev.toStringAsFixed(1)}).';
    } else {
      action = PlayerAction.raise;
      baseExplanation =
          'Your equity (${(equity * 100).toStringAsFixed(1)}%) significantly exceeds '
          'pot odds (${(potOddsRequired * 100).toStringAsFixed(1)}%). '
          'You have a strong edge — raise to extract value (EV = ${ev.toStringAsFixed(1)}).';
    }

    // Append position note when a position is provided.
    final String explanation = heroPosition != null
        ? '$baseExplanation ${_positionNote(heroPosition)}'
        : baseExplanation;

    return Decision(
      action: action,
      equity: equity,
      potOdds: potOddsRequired,
      expectedValue: ev,
      explanation: explanation,
    );
  }

  /// Returns a human-readable position note for the explanation string.
  static String _positionNote(TablePosition pos) {
    switch (pos) {
      case TablePosition.button:
        return 'Your ${positionLabel(pos)} position gives you a strong positional '
            'advantage — you can play this hand more aggressively.';
      case TablePosition.cutoff:
        return 'Your ${positionLabel(pos)} position is strong — you act late and '
            'can apply pressure.';
      case TablePosition.hijack:
        return 'Your ${positionLabel(pos)} position is a neutral baseline — play '
            'your standard ranges.';
      case TablePosition.utg:
        return 'Your ${positionLabel(pos)} position means you should play tighter '
            '— many players still to act behind you.';
      case TablePosition.utg1:
        return 'Your ${positionLabel(pos)} position is early — stick to strong '
            'hands with many players yet to act.';
      case TablePosition.mp:
        return 'Your ${positionLabel(pos)} position is slightly better but still '
            'early — play solid, tight ranges.';
      case TablePosition.mp1:
        return 'Your ${positionLabel(pos)} position offers moderate positional '
            'advantage — you can widen your range slightly.';
      case TablePosition.smallBlind:
        return 'Your ${positionLabel(pos)} position is out of position postflop '
            '— be cautious and play tighter ranges.';
      case TablePosition.bigBlind:
        return 'Your ${positionLabel(pos)} position is out of position postflop, '
            'but you already have chips invested in the pot.';
    }
  }
}
