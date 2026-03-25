/// Table position model for Texas Hold'em.
library;

/// Table positions in Texas Hold'em (9-max table).
enum TablePosition {
  utg,        // Under the Gun (earliest, worst position)
  utg1,       // UTG+1
  mp,         // Middle Position
  mp1,        // MP+1 (Lojack)
  hijack,     // Hijack
  cutoff,     // Cutoff
  button,     // Button / Dealer (best position — acts last postflop)
  smallBlind, // Small Blind (forced bet, out of position postflop)
  bigBlind,   // Big Blind (forced bet, out of position but already invested)
}

/// Returns a positional multiplier for the raise/call thresholds.
///
/// Values > 1.0 allow more aggressive play; values < 1.0 require stronger
/// hands to raise (tighter play from early positions).
double positionMultiplier(TablePosition pos) {
  switch (pos) {
    case TablePosition.utg:
      return 0.80;
    case TablePosition.utg1:
      return 0.85;
    case TablePosition.mp:
      return 0.90;
    case TablePosition.mp1:
      return 0.93;
    case TablePosition.hijack:
      return 1.00;
    case TablePosition.cutoff:
      return 1.05;
    case TablePosition.button:
      return 1.15;
    case TablePosition.smallBlind:
      return 0.90;
    case TablePosition.bigBlind:
      return 0.95;
  }
}

/// Returns a short human-readable label for the position.
String positionLabel(TablePosition pos) {
  switch (pos) {
    case TablePosition.utg:
      return 'UTG';
    case TablePosition.utg1:
      return 'UTG+1';
    case TablePosition.mp:
      return 'MP';
    case TablePosition.mp1:
      return 'MP+1';
    case TablePosition.hijack:
      return 'HJ';
    case TablePosition.cutoff:
      return 'CO';
    case TablePosition.button:
      return 'BTN';
    case TablePosition.smallBlind:
      return 'SB';
    case TablePosition.bigBlind:
      return 'BB';
  }
}

/// Returns a range-pressure multiplier representing how strong an opener's
/// range is from that position.
///
/// Values > 1.0 mean a tight opening range (need stronger hand to continue).
/// Values < 1.0 mean a wide opening range (can continue lighter).
double opponentRangePressure(TablePosition pos) {
  switch (pos) {
    case TablePosition.utg:
      return 1.25;
    case TablePosition.utg1:
      return 1.18;
    case TablePosition.mp:
      return 1.12;
    case TablePosition.mp1:
      return 1.07;
    case TablePosition.hijack:
      return 1.00;
    case TablePosition.cutoff:
      return 0.93;
    case TablePosition.button:
      return 0.87;
    case TablePosition.smallBlind:
      return 1.05;
    case TablePosition.bigBlind:
      return 1.02;
  }
}

/// Returns a brief description of the position.
String positionDescription(TablePosition pos) {
  switch (pos) {
    case TablePosition.utg:
      return 'Under the Gun — first to act, worst position';
    case TablePosition.utg1:
      return 'UTG+1 — second to act, still very early';
    case TablePosition.mp:
      return 'Middle Position — moderate positional disadvantage';
    case TablePosition.mp1:
      return 'MP+1 (Lojack) — slightly better than middle position';
    case TablePosition.hijack:
      return 'Hijack — neutral baseline position';
    case TablePosition.cutoff:
      return 'Cutoff — strong position, one left of the button';
    case TablePosition.button:
      return 'Button — best position, acts last on every street';
    case TablePosition.smallBlind:
      return 'Small Blind — forced bet, out of position postflop';
    case TablePosition.bigBlind:
      return 'Big Blind — forced bet, out of position but already invested';
  }
}
