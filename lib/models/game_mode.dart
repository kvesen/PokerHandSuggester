/// Game mode model: defines playing style that adjusts decision thresholds.
library;

/// Poker game formats / playing styles.
enum GameMode {
  /// Standard deep-stack cash game (default).
  cashGame,

  /// Tournament — early stages; survival matters.
  tournamentEarly,

  /// Tournament — near the money bubble; extreme ICM pressure.
  tournamentBubble,

  /// Tournament — final table; short-handed, aggression pays.
  tournamentFinalTable,

  /// Turbo / speed format; blinds escalate fast.
  turbo,

  /// Heads-up; very wide ranges, aggression is key.
  headsUp,
}

/// Returns a short human-readable name for [mode].
String gameModeLabel(GameMode mode) {
  switch (mode) {
    case GameMode.cashGame:
      return 'Cash Game';
    case GameMode.tournamentEarly:
      return 'Tournament (Early)';
    case GameMode.tournamentBubble:
      return 'Tournament (Bubble)';
    case GameMode.tournamentFinalTable:
      return 'Tournament (Final Table)';
    case GameMode.turbo:
      return 'Turbo / Speed';
    case GameMode.headsUp:
      return 'Heads-Up';
  }
}

/// Returns a brief description explaining when to use [mode].
String gameModeDescription(GameMode mode) {
  switch (mode) {
    case GameMode.cashGame:
      return 'Standard deep-stack cash game. Long-term EV focus.';
    case GameMode.tournamentEarly:
      return 'Survival matters. Avoid marginal spots early in a tournament.';
    case GameMode.tournamentBubble:
      return 'ICM pressure near the money. Play extremely tight.';
    case GameMode.tournamentFinalTable:
      return 'Short-handed final table. Controlled aggression pays.';
    case GameMode.turbo:
      return 'Blinds escalate fast. Widen your ranges and play more aggressively.';
    case GameMode.headsUp:
      return 'One opponent. Very wide ranges, constant aggression.';
  }
}

/// Returns the raise equity multiple for [mode].
///
/// This replaces [kRaiseEquityMultiple] from `constants.dart` when a mode is
/// active. A higher value requires stronger equity before raising.
double gameModeRaiseMultiple(GameMode mode) {
  switch (mode) {
    case GameMode.cashGame:
      return 1.5;
    case GameMode.tournamentEarly:
      return 1.6;
    case GameMode.tournamentBubble:
      return 1.8;
    case GameMode.tournamentFinalTable:
      return 1.4;
    case GameMode.turbo:
      return 1.3;
    case GameMode.headsUp:
      return 1.2;
  }
}

/// Returns the free-check raise equity threshold for [mode].
///
/// This replaces [kFreeCheckRaiseEquityThreshold] from `constants.dart` when a
/// mode is active.
double gameModeFreeCheckThreshold(GameMode mode) {
  switch (mode) {
    case GameMode.cashGame:
      return 0.60;
    case GameMode.tournamentEarly:
      return 0.65;
    case GameMode.tournamentBubble:
      return 0.70;
    case GameMode.tournamentFinalTable:
      return 0.55;
    case GameMode.turbo:
      return 0.50;
    case GameMode.headsUp:
      return 0.45;
  }
}

/// Returns a multiplier applied on top of the existing position multipliers.
///
/// Values > 1.0 allow more aggressive play; values < 1.0 require tighter play.
double gameModePositionScale(GameMode mode) {
  switch (mode) {
    case GameMode.cashGame:
      return 1.00;
    case GameMode.tournamentEarly:
      return 0.90;
    case GameMode.tournamentBubble:
      return 0.80;
    case GameMode.tournamentFinalTable:
      return 1.05;
    case GameMode.turbo:
      return 1.10;
    case GameMode.headsUp:
      return 1.10;
  }
}
