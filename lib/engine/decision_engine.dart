/// Decision engine: combines equity and pot odds to recommend an action.
library;

import 'pot_odds.dart';

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
  /// [equity]     – estimated win probability (0–1) from equity calculator.
  /// [pot]        – total chips currently in the pot.
  /// [costToCall] – chips required to stay in the hand.
  static Decision decide({
    required double equity,
    required double pot,
    required double costToCall,
  }) {
    final potOddsRequired =
        PotOdds.requiredEquity(pot: pot, costToCall: costToCall);
    final ev = equity * pot - (1 - equity) * costToCall;

    final PlayerAction action;
    final String explanation;

    if (costToCall <= 0) {
      // Free to check — always at least call (check).
      if (equity >= 0.6) {
        action = PlayerAction.raise;
        explanation =
            'You can check for free, but with ${(equity * 100).toStringAsFixed(1)}% equity '
            'you have a strong hand — raise to build the pot.';
      } else {
        action = PlayerAction.call;
        explanation =
            'No bet to call. Check and see the next card for free.';
      }
    } else if (equity < potOddsRequired) {
      action = PlayerAction.fold;
      explanation =
          'Your equity (${(equity * 100).toStringAsFixed(1)}%) is less than '
          'the pot odds required (${(potOddsRequired * 100).toStringAsFixed(1)}%). '
          'Calling has negative expected value (EV = $ev). Fold.';
    } else if (equity < potOddsRequired * 1.5) {
      action = PlayerAction.call;
      explanation =
          'Your equity (${(equity * 100).toStringAsFixed(1)}%) meets but does not '
          'greatly exceed pot odds (${(potOddsRequired * 100).toStringAsFixed(1)}%). '
          'Calling is marginally profitable (EV = ${ev.toStringAsFixed(1)}).';
    } else {
      action = PlayerAction.raise;
      explanation =
          'Your equity (${(equity * 100).toStringAsFixed(1)}%) significantly exceeds '
          'pot odds (${(potOddsRequired * 100).toStringAsFixed(1)}%). '
          'You have a strong edge — raise to extract value (EV = ${ev.toStringAsFixed(1)}).';
    }

    return Decision(
      action: action,
      equity: equity,
      potOdds: potOddsRequired,
      expectedValue: ev,
      explanation: explanation,
    );
  }
}
