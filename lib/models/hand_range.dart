/// Preflop hand range model for Texas Hold'em.
///
/// Defines a 13×13 matrix representation of starting hands and provides
/// GTO-approximate opening ranges for each table position.
library;

import 'position.dart';

/// Recommended preflop action for a hand from a given position.
enum RangeAction {
  /// Open-raise or 3-bet this hand.
  raise,

  /// Call or limp with this hand.
  call,

  /// Fold this hand.
  fold,
}

/// Rank labels in matrix order — highest (Ace) to lowest (Deuce).
const List<String> _ranks = [
  'A', 'K', 'Q', 'J', 'T', '9', '8', '7', '6', '5', '4', '3', '2',
];

/// Returns the hand label for matrix cell ([row], [col]).
///
/// - Diagonal (row == col): pocket pair, e.g. "AA", "77"
/// - Above diagonal (row < col): suited hand, e.g. "AKs", "87s"
/// - Below diagonal (row > col): offsuit hand, e.g. "AKo", "87o"
String handLabel(int row, int col) {
  assert(row >= 0 && row < 13 && col >= 0 && col < 13);
  if (row == col) return '${_ranks[row]}${_ranks[row]}';
  if (row < col) return '${_ranks[row]}${_ranks[col]}s';
  return '${_ranks[col]}${_ranks[row]}o';
}

/// Returns true if ([row], [col]) represents a suited hand (above the diagonal).
bool isSuited(int row, int col) => row < col;

/// Returns true if ([row], [col]) represents a pocket pair (on the diagonal).
bool isPocketPair(int row, int col) => row == col;

/// Returns the recommended preflop action for [position] at matrix cell
/// ([row], [col]).
///
/// Rank index mapping: 0=A, 1=K, 2=Q, 3=J, 4=T, 5=9, 6=8, 7=7, 8=6,
/// 9=5, 10=4, 11=3, 12=2.
///
/// - Above diagonal (row < col): suited hands (e.g. AKs)
/// - Below diagonal (row > col): offsuit hands (e.g. AKo)
/// - Diagonal (row == col): pocket pairs (e.g. AA)
RangeAction getAction(TablePosition position, int row, int col) {
  // hi = rank index of the higher card (lower index = higher rank)
  // lo = rank index of the lower card
  final hi = row < col ? row : col;
  final lo = row < col ? col : row;
  final suited = row < col;
  final pair = row == col;

  switch (position) {
    case TablePosition.utg:
      return _utg(hi, lo, suited, pair);
    case TablePosition.utg1:
      return _utg1(hi, lo, suited, pair);
    case TablePosition.mp:
      return _mp(hi, lo, suited, pair);
    case TablePosition.mp1:
      return _mp1(hi, lo, suited, pair);
    case TablePosition.hijack:
      return _hj(hi, lo, suited, pair);
    case TablePosition.cutoff:
      return _co(hi, lo, suited, pair);
    case TablePosition.button:
      return _btn(hi, lo, suited, pair);
    case TablePosition.smallBlind:
      return _sb(hi, lo, suited, pair);
    case TablePosition.bigBlind:
      return _bb(hi, lo, suited, pair);
  }
}

/// Returns the approximate percentage of hands played from [position].
double openingPercentage(TablePosition position) {
  switch (position) {
    case TablePosition.utg:
      return 15.0;
    case TablePosition.utg1:
      return 17.0;
    case TablePosition.mp:
      return 20.0;
    case TablePosition.mp1:
      return 23.0;
    case TablePosition.hijack:
      return 27.0;
    case TablePosition.cutoff:
      return 33.0;
    case TablePosition.button:
      return 45.0;
    case TablePosition.smallBlind:
      return 35.0;
    case TablePosition.bigBlind:
      return 40.0;
  }
}

// ---------------------------------------------------------------------------
// Position-specific range helpers
// ---------------------------------------------------------------------------
// hi   = rank index of higher card (0=A, 12=2); lower index = better rank
// lo   = rank index of lower card  (hi < lo for non-pairs)
// suited = true for suited hands (above diagonal)
// pair   = true for pocket pairs  (diagonal)
// ---------------------------------------------------------------------------

/// UTG — ~15%: Premium hands only.
RangeAction _utg(int hi, int lo, bool suited, bool pair) {
  if (pair) {
    if (hi <= 5) return RangeAction.raise; // AA–99
    if (hi <= 7) return RangeAction.call; // 88–77
    return RangeAction.fold;
  }
  if (suited) {
    if (hi == 0 && lo <= 4) return RangeAction.raise; // AKs–ATs
    if (hi == 1 && lo == 2) return RangeAction.raise; // KQs
    if (hi == 1 && lo == 3) return RangeAction.call; // KJs
    if (hi == 2 && lo == 3) return RangeAction.call; // QJs
    if (hi == 3 && lo == 4) return RangeAction.call; // JTs
    return RangeAction.fold;
  }
  if (hi == 0 && lo <= 2) return RangeAction.raise; // AKo, AQo
  return RangeAction.fold;
}

/// UTG+1 — ~17%: Slightly wider than UTG.
RangeAction _utg1(int hi, int lo, bool suited, bool pair) {
  if (pair) {
    if (hi <= 5) return RangeAction.raise; // AA–99
    if (hi <= 7) return RangeAction.call; // 88–77
    return RangeAction.fold;
  }
  if (suited) {
    if (hi == 0 && lo <= 5) return RangeAction.raise; // AKs–A9s
    if (hi == 1 && lo <= 3) return RangeAction.raise; // KQs–KJs
    if (hi == 2 && lo == 3) return RangeAction.raise; // QJs
    if (hi == 3 && lo == 4) return RangeAction.call; // JTs
    if (hi == 4 && lo == 5) return RangeAction.call; // T9s
    return RangeAction.fold;
  }
  if (hi == 0 && lo <= 3) return RangeAction.raise; // AKo–AJo
  if (hi == 1 && lo == 2) return RangeAction.raise; // KQo
  return RangeAction.fold;
}

/// MP — ~20%: Add suited connectors and broadway hands.
RangeAction _mp(int hi, int lo, bool suited, bool pair) {
  if (pair) {
    if (hi <= 6) return RangeAction.raise; // AA–88
    if (hi <= 8) return RangeAction.call; // 77–66
    return RangeAction.fold;
  }
  if (suited) {
    if (hi == 0 && lo <= 6) return RangeAction.raise; // AKs–A8s
    if (hi == 1 && lo <= 4) return RangeAction.raise; // KQs–KTs
    if (hi == 2 && lo <= 4) return RangeAction.raise; // QJs–QTs
    if (hi == 3 && lo == 4) return RangeAction.raise; // JTs
    if (hi == 3 && lo == 5) return RangeAction.call; // J9s
    if (hi == 4 && lo == 5) return RangeAction.call; // T9s
    if (hi == 5 && lo == 6) return RangeAction.call; // 98s
    return RangeAction.fold;
  }
  if (hi == 0 && lo <= 3) return RangeAction.raise; // AKo–AJo
  if (hi == 1 && lo <= 3) return RangeAction.raise; // KQo–KJo
  return RangeAction.fold;
}

/// MP+1/Lojack — ~23%: Widen further with more suited hands.
RangeAction _mp1(int hi, int lo, bool suited, bool pair) {
  if (pair) {
    if (hi <= 7) return RangeAction.raise; // AA–77
    if (hi <= 9) return RangeAction.call; // 66–55
    return RangeAction.fold;
  }
  if (suited) {
    if (hi == 0 && lo <= 6) return RangeAction.raise; // AKs–A8s
    if (hi == 1 && lo <= 5) return RangeAction.raise; // KQs–K9s
    if (hi == 2 && lo <= 5) return RangeAction.raise; // QJs–Q9s
    if (hi == 3 && lo <= 5) return RangeAction.raise; // JTs–J9s
    if (hi == 4 && lo == 5) return RangeAction.raise; // T9s
    if (hi == 4 && lo == 6) return RangeAction.call; // T8s
    if (hi == 5 && lo == 6) return RangeAction.call; // 98s
    if (hi == 6 && lo == 7) return RangeAction.call; // 87s
    return RangeAction.fold;
  }
  if (hi == 0 && lo <= 4) return RangeAction.raise; // AKo–ATo
  if (hi == 1 && lo <= 3) return RangeAction.raise; // KQo–KJo
  if (hi == 2 && lo == 3) return RangeAction.raise; // QJo
  return RangeAction.fold;
}

/// HJ — ~27%: Add more suited hands and broadway offsuit combos.
RangeAction _hj(int hi, int lo, bool suited, bool pair) {
  if (pair) {
    if (hi <= 8) return RangeAction.raise; // AA–66
    if (hi <= 10) return RangeAction.call; // 55–44
    return RangeAction.fold;
  }
  if (suited) {
    if (hi == 0 && lo <= 7) return RangeAction.raise; // AKs–A7s
    if (hi == 1 && lo <= 6) return RangeAction.raise; // KQs–K8s
    if (hi == 2 && lo <= 6) return RangeAction.raise; // QJs–Q8s
    if (hi == 3 && lo <= 6) return RangeAction.raise; // JTs–J8s
    if (hi == 4 && lo <= 6) return RangeAction.raise; // T9s–T8s
    if (hi == 5 && lo == 6) return RangeAction.raise; // 98s
    if (hi == 5 && lo == 7) return RangeAction.call; // 97s
    if (hi == 6 && lo == 7) return RangeAction.call; // 87s
    if (hi == 7 && lo == 8) return RangeAction.call; // 76s
    return RangeAction.fold;
  }
  if (hi == 0 && lo <= 4) return RangeAction.raise; // AKo–ATo
  if (hi == 1 && lo <= 4) return RangeAction.raise; // KQo–KTo
  if (hi == 2 && lo <= 4) return RangeAction.raise; // QJo–QTo
  if (hi == 3 && lo == 4) return RangeAction.raise; // JTo
  return RangeAction.fold;
}

/// CO — ~33%: Significantly wider; most suited broadways.
RangeAction _co(int hi, int lo, bool suited, bool pair) {
  if (pair) {
    if (hi <= 9) return RangeAction.raise; // AA–55
    if (hi <= 11) return RangeAction.call; // 44–33
    return RangeAction.fold;
  }
  if (suited) {
    if (hi == 0 && lo <= 9) return RangeAction.raise; // AKs–A5s
    if (hi == 1 && lo <= 7) return RangeAction.raise; // KQs–K7s
    if (hi == 2 && lo <= 7) return RangeAction.raise; // QJs–Q7s
    if (hi == 3 && lo <= 7) return RangeAction.raise; // JTs–J7s
    if (hi == 4 && lo <= 7) return RangeAction.raise; // T9s–T7s
    if (hi == 5 && lo <= 7) return RangeAction.raise; // 98s–97s
    if (hi == 6 && lo == 7) return RangeAction.raise; // 87s
    if (hi == 7 && lo == 8) return RangeAction.call; // 76s
    if (hi == 7 && lo == 9) return RangeAction.call; // 75s
    if (hi == 6 && lo == 8) return RangeAction.call; // 86s
    if (hi == 8 && lo == 9) return RangeAction.call; // 65s
    return RangeAction.fold;
  }
  if (hi == 0 && lo <= 5) return RangeAction.raise; // AKo–A9o
  if (hi == 1 && lo <= 4) return RangeAction.raise; // KQo–KTo
  if (hi == 2 && lo <= 4) return RangeAction.raise; // QJo–QTo
  if (hi == 3 && lo == 4) return RangeAction.raise; // JTo
  if (hi == 1 && lo == 5) return RangeAction.call; // K9o
  return RangeAction.fold;
}

/// BTN — ~45%: Very wide; most playable hands.
RangeAction _btn(int hi, int lo, bool suited, bool pair) {
  if (pair) {
    if (hi <= 11) return RangeAction.raise; // AA–33
    return RangeAction.call; // 22
  }
  if (suited) {
    if (hi == 0) return RangeAction.raise; // AKs–A2s (all suited Ax)
    if (hi == 1 && lo <= 9) return RangeAction.raise; // KQs–K5s
    if (hi == 1 && lo >= 10) return RangeAction.call; // K4s–K2s
    if (hi == 2 && lo <= 8) return RangeAction.raise; // QJs–Q6s
    if (hi == 2 && lo == 9) return RangeAction.call; // Q5s
    if (hi == 3 && lo <= 7) return RangeAction.raise; // JTs–J7s
    if (hi == 3 && lo == 8) return RangeAction.call; // J6s
    if (hi == 4 && lo <= 7) return RangeAction.raise; // T9s–T7s
    if (hi == 4 && lo == 8) return RangeAction.call; // T6s
    if (hi == 5 && lo <= 8) return RangeAction.raise; // 98s–96s
    if (hi == 6 && lo <= 9) return RangeAction.raise; // 87s–85s
    if (hi == 7 && lo <= 10) return RangeAction.raise; // 76s–74s
    if (hi == 8 && lo <= 10) return RangeAction.raise; // 65s–63s
    if (hi == 9 && lo == 10) return RangeAction.raise; // 54s
    if (hi == 9 && lo == 11) return RangeAction.call; // 53s
    return RangeAction.fold;
  }
  if (hi == 0 && lo <= 7) return RangeAction.raise; // AKo–A7o
  if (hi == 0 && lo == 8) return RangeAction.call; // A6o
  if (hi == 1 && lo <= 5) return RangeAction.raise; // KQo–K9o
  if (hi == 1 && lo == 6) return RangeAction.call; // K8o
  if (hi == 2 && lo <= 4) return RangeAction.raise; // QJo–QTo
  if (hi == 2 && lo == 5) return RangeAction.call; // Q9o
  if (hi == 3 && lo == 4) return RangeAction.raise; // JTo
  if (hi == 3 && lo == 5) return RangeAction.call; // J9o
  if (hi == 4 && lo == 5) return RangeAction.call; // T9o
  return RangeAction.fold;
}

/// SB — ~35%: Wide but out of position; mix of raise/call.
RangeAction _sb(int hi, int lo, bool suited, bool pair) {
  if (pair) {
    if (hi <= 7) return RangeAction.raise; // AA–77
    if (hi <= 10) return RangeAction.call; // 66–44
    return RangeAction.fold;
  }
  if (suited) {
    if (hi == 0 && lo <= 8) return RangeAction.raise; // AKs–A6s
    if (hi == 0 && lo == 9) return RangeAction.call; // A5s
    if (hi == 1 && lo <= 5) return RangeAction.raise; // KQs–K9s
    if (hi == 1 && lo == 6) return RangeAction.call; // K8s
    if (hi == 2 && lo <= 5) return RangeAction.raise; // QJs–Q9s
    if (hi == 3 && lo <= 5) return RangeAction.raise; // JTs–J9s
    if (hi == 4 && lo <= 6) return RangeAction.raise; // T9s–T8s
    if (hi == 5 && lo == 6) return RangeAction.raise; // 98s
    if (hi == 5 && lo == 7) return RangeAction.call; // 97s
    if (hi == 6 && lo == 7) return RangeAction.call; // 87s
    if (hi == 7 && lo == 8) return RangeAction.call; // 76s
    return RangeAction.fold;
  }
  if (hi == 0 && lo <= 4) return RangeAction.raise; // AKo–ATo
  if (hi == 0 && lo == 5) return RangeAction.call; // A9o
  if (hi == 1 && lo <= 4) return RangeAction.raise; // KQo–KTo
  if (hi == 1 && lo == 5) return RangeAction.call; // K9o
  if (hi == 2 && lo == 3) return RangeAction.raise; // QJo
  if (hi == 2 && lo == 4) return RangeAction.call; // QTo
  if (hi == 3 && lo == 4) return RangeAction.call; // JTo
  return RangeAction.fold;
}

/// BB — ~40% defend: Wide defense range vs opens; 3-bet premiums.
RangeAction _bb(int hi, int lo, bool suited, bool pair) {
  if (pair) {
    if (hi <= 3) return RangeAction.raise; // AA–JJ (3-bet)
    if (hi <= 11) return RangeAction.call; // TT–33
    return RangeAction.fold; // 22
  }
  if (suited) {
    if (hi == 0 && lo <= 3) return RangeAction.raise; // AKs–AJs (3-bet)
    if (hi == 0) return RangeAction.call; // ATs–A2s
    if (hi == 1 && lo == 2) return RangeAction.raise; // KQs (3-bet)
    if (hi == 1) return RangeAction.call; // KJs–K2s
    if (hi == 2 && lo <= 7) return RangeAction.call; // QJs–Q7s
    if (hi == 3 && lo <= 7) return RangeAction.call; // JTs–J7s
    if (hi == 4 && lo <= 7) return RangeAction.call; // T9s–T7s
    if (hi == 5 && lo <= 8) return RangeAction.call; // 98s–96s
    if (hi == 6 && lo <= 9) return RangeAction.call; // 87s–85s
    if (hi == 7 && lo <= 10) return RangeAction.call; // 76s–74s
    if (hi == 8 && lo == 9) return RangeAction.call; // 65s
    if (hi == 9 && lo == 10) return RangeAction.call; // 54s
    return RangeAction.fold;
  }
  if (hi == 0 && lo <= 2) return RangeAction.raise; // AKo–AQo (3-bet)
  if (hi == 0) return RangeAction.call; // AJo–A2o
  if (hi == 1 && lo <= 4) return RangeAction.call; // KQo–KTo
  if (hi == 2 && lo <= 4) return RangeAction.call; // QJo–QTo
  if (hi == 3 && lo == 4) return RangeAction.call; // JTo
  if (hi == 4 && lo == 5) return RangeAction.call; // T9o
  return RangeAction.fold;
}
