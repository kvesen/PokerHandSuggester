/// App-wide constants for suits, ranks, and hand ranking names.
library;

/// Unicode suit symbols.
const Map<String, String> kSuitSymbols = {
  'hearts': '♥',
  'diamonds': '♦',
  'clubs': '♣',
  'spades': '♠',
};

/// Display labels for card ranks.
const Map<String, String> kRankLabels = {
  'two': '2',
  'three': '3',
  'four': '4',
  'five': '5',
  'six': '6',
  'seven': '7',
  'eight': '8',
  'nine': '9',
  'ten': '10',
  'jack': 'J',
  'queen': 'Q',
  'king': 'K',
  'ace': 'A',
};

/// Human-readable names for hand rankings.
const List<String> kHandRankingNames = [
  'High Card',
  'One Pair',
  'Two Pair',
  'Three of a Kind',
  'Straight',
  'Flush',
  'Full House',
  'Four of a Kind',
  'Straight Flush',
  'Royal Flush',
];

/// Maximum hole cards a player can hold.
const int kMaxHoleCards = 2;

/// Maximum community cards on the board.
const int kMaxCommunityCards = 5;

/// Default Monte Carlo simulation iterations.
const int kDefaultSimulationIterations = 10000;
