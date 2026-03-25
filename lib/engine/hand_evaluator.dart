/// Hand evaluator: ranks the best 5-card hand from up to 7 cards.
library;

import '../models/card.dart';

/// Poker hand rankings, ordered from weakest to strongest.
enum HandRanking {
  highCard,
  onePair,
  twoPair,
  threeOfAKind,
  straight,
  flush,
  fullHouse,
  fourOfAKind,
  straightFlush,
  royalFlush,
}

/// The result of evaluating a hand: ranking plus a comparable score.
///
/// Higher [score] always beats a lower [score] — this encodes both the
/// ranking tier and the kicker values so two [HandResult]s can be compared
/// directly with [compareTo].
class HandResult implements Comparable<HandResult> {
  const HandResult({required this.ranking, required this.score});

  /// The category of this hand.
  final HandRanking ranking;

  /// A numeric score that fully determines hand strength, including kickers.
  /// Encoded as: `ranking.index * base^5 + kicker terms` where `base = 15`.
  final int score;

  @override
  int compareTo(HandResult other) => score.compareTo(other.score);

  @override
  String toString() => ranking.name;
}

/// Evaluates poker hands.
class HandEvaluator {
  /// Returns the best [HandResult] achievable from [cards] (2–7 cards).
  static HandResult evaluate(List<PokerCard> cards) {
    assert(cards.length >= 2 && cards.length <= 7);

    if (cards.length < 5) {
      // Cannot form a complete 5-card hand; compare by best available cards.
      return _evaluatePartial(cards);
    }

    // Generate all C(n,5) combinations and pick the best.
    HandResult? best;
    for (final combo in _combinations(cards, 5)) {
      final result = _evaluateFive(combo);
      if (best == null || result.compareTo(best) > 0) {
        best = result;
      }
    }
    return best!;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Evaluate a partial hand (< 5 cards) by rank only.
  static HandResult _evaluatePartial(List<PokerCard> cards) {
    final sorted = [...cards]..sort((a, b) => b.value.compareTo(a.value));
    final score = _tierScore(HandRanking.highCard, sorted.map((c) => c.value).toList());
    return HandResult(ranking: HandRanking.highCard, score: score);
  }

  /// Evaluate exactly 5 cards and return their [HandResult].
  static HandResult _evaluateFive(List<PokerCard> five) {
    final sorted = [...five]..sort((a, b) => b.value.compareTo(a.value));
    final values = sorted.map((c) => c.value).toList();
    final isFlush = _isFlush(five);
    final straightHighCard = _straightHighCard(values);

    if (isFlush && straightHighCard != null) {
      final ranking =
          straightHighCard == 14 ? HandRanking.royalFlush : HandRanking.straightFlush;
      return HandResult(
        ranking: ranking,
        score: _tierScore(ranking, [straightHighCard]),
      );
    }

    final groups = _groupByRank(values);
    // groups sorted descending by count, then by rank value
    groups.sort((a, b) => a[0] != b[0] ? b[0].compareTo(a[0]) : b[1].compareTo(a[1]));

    final counts = groups.map((g) => g[0]).toList(); // e.g. [4,1] or [3,2]

    if (counts[0] == 4) {
      final quad = groups[0][1];
      final kicker = groups[1][1];
      return HandResult(
        ranking: HandRanking.fourOfAKind,
        score: _tierScore(HandRanking.fourOfAKind, [quad, kicker]),
      );
    }

    if (counts[0] == 3 && counts[1] == 2) {
      final trips = groups[0][1];
      final pair = groups[1][1];
      return HandResult(
        ranking: HandRanking.fullHouse,
        score: _tierScore(HandRanking.fullHouse, [trips, pair]),
      );
    }

    if (isFlush) {
      return HandResult(
        ranking: HandRanking.flush,
        score: _tierScore(HandRanking.flush, values),
      );
    }

    if (straightHighCard != null) {
      return HandResult(
        ranking: HandRanking.straight,
        score: _tierScore(HandRanking.straight, [straightHighCard]),
      );
    }

    if (counts[0] == 3) {
      final trips = groups[0][1];
      final kickers = groups.skip(1).map((g) => g[1]).toList();
      return HandResult(
        ranking: HandRanking.threeOfAKind,
        score: _tierScore(HandRanking.threeOfAKind, [trips, ...kickers]),
      );
    }

    if (counts[0] == 2 && counts[1] == 2) {
      final highPair = groups[0][1];
      final lowPair = groups[1][1];
      final kicker = groups[2][1];
      return HandResult(
        ranking: HandRanking.twoPair,
        score: _tierScore(HandRanking.twoPair, [highPair, lowPair, kicker]),
      );
    }

    if (counts[0] == 2) {
      final pair = groups[0][1];
      final kickers = groups.skip(1).map((g) => g[1]).toList();
      return HandResult(
        ranking: HandRanking.onePair,
        score: _tierScore(HandRanking.onePair, [pair, ...kickers]),
      );
    }

    return HandResult(
      ranking: HandRanking.highCard,
      score: _tierScore(HandRanking.highCard, values),
    );
  }

  /// Whether all five cards share the same suit.
  static bool _isFlush(List<PokerCard> five) {
    final suit = five[0].suit;
    return five.every((c) => c.suit == suit);
  }

  /// Returns the high-card value of the straight, or null if not a straight.
  /// Handles the ace-low straight (A-2-3-4-5 → high card = 5).
  static int? _straightHighCard(List<int> sortedDesc) {
    // Normal straight check
    bool sequential = true;
    for (int i = 0; i < 4; i++) {
      if (sortedDesc[i] - sortedDesc[i + 1] != 1) {
        sequential = false;
        break;
      }
    }
    if (sequential) return sortedDesc[0];

    // Ace-low straight: A-2-3-4-5 (values: 14,5,4,3,2)
    if (sortedDesc[0] == 14 &&
        sortedDesc[1] == 5 &&
        sortedDesc[2] == 4 &&
        sortedDesc[3] == 3 &&
        sortedDesc[4] == 2) {
      return 5;
    }
    return null;
  }

  /// Groups card values by rank count.
  /// Returns list of [count, rankValue] pairs.
  static List<List<int>> _groupByRank(List<int> values) {
    final freq = <int, int>{};
    for (final v in values) {
      freq[v] = (freq[v] ?? 0) + 1;
    }
    return freq.entries.map((e) => [e.value, e.key]).toList();
  }

  /// Encodes [ranking tier + kicker values] into a single comparable integer.
  static int _tierScore(HandRanking ranking, List<int> kickers) {
    // Each tier occupies a unique range. Kickers fit in base-15 (max rank = 14).
    // Score = tier * 15^5 + k0 * 15^4 + k1 * 15^3 + ...
    const int base = 15;
    int score = ranking.index;
    for (final k in kickers) {
      score = score * base + k;
    }
    // Pad remaining positions
    final padding = 5 - kickers.length;
    for (int i = 0; i < padding; i++) {
      score = score * base;
    }
    return score;
  }

  /// Generates all C(n, k) combinations iteratively using index arrays.
  /// Avoids deep recursion and minimises intermediate list allocations.
  static List<List<T>> _combinations<T>(List<T> items, int k) {
    final n = items.length;
    if (k > n) return [];
    if (k == 0) return [[]];

    final result = <List<T>>[];
    // indices[i] holds the index into items for position i in the current combo
    final indices = List<int>.generate(k, (i) => i);

    while (true) {
      result.add([for (final i in indices) items[i]]);

      // Find the rightmost index that can be incremented
      int i = k - 1;
      while (i >= 0 && indices[i] == i + n - k) {
        i--;
      }
      if (i < 0) break;

      indices[i]++;
      for (int j = i + 1; j < k; j++) {
        indices[j] = indices[j - 1] + 1;
      }
    }
    return result;
  }
}
