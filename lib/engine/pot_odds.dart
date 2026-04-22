/// Pot odds calculator.
library;

/// Calculates pot odds and the minimum equity required for a profitable call.
class PotOdds {
  /// The fraction of the total pot (after calling) that the call costs.
  ///
  /// Formula: `costToCall / (pot + costToCall)`
  ///
  /// Example: pot = 100, costToCall = 50 → 50 / 150 ≈ 0.333 (33.3 %).
  static double calculate({required double pot, required double costToCall}) {
    if (costToCall <= 0) return 0;
    final total = pot + costToCall;
    if (total <= 0) return 0;
    return costToCall / total;
  }

  /// The minimum equity (win probability) needed to make a call break-even.
  ///
  /// This is identical to the pot-odds fraction — you need at least this
  /// equity to profit in the long run.
  static double requiredEquity({
    required double pot,
    required double costToCall,
  }) {
    return calculate(pot: pot, costToCall: costToCall);
  }
}
