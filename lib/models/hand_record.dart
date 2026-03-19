/// Hand record model: stores a single analyzed hand for history.
library;

import 'dart:convert';

import '../engine/decision_engine.dart';
import 'card.dart';

/// A persisted record of a single analyzed poker hand.
class HandRecord {
  const HandRecord({
    required this.id,
    required this.timestamp,
    required this.holeCards,
    required this.communityCards,
    required this.potSize,
    required this.betToCall,
    required this.numberOfOpponents,
    required this.action,
    required this.equity,
    required this.potOdds,
    required this.expectedValue,
    required this.explanation,
  });

  /// Unique identifier (timestamp-based).
  final String id;

  /// When this hand was analyzed.
  final DateTime timestamp;

  /// The player's two hole cards.
  final List<PokerCard> holeCards;

  /// Community cards on the board (0–5).
  final List<PokerCard> communityCards;

  /// Total pot size in chips.
  final double potSize;

  /// Amount needed to call.
  final double betToCall;

  /// Number of active opponents.
  final int numberOfOpponents;

  /// Recommended action.
  final PlayerAction action;

  /// Win probability (0–1).
  final double equity;

  /// Pot odds required to break even (0–1).
  final double potOdds;

  /// Expected value.
  final double expectedValue;

  /// Human-readable explanation.
  final String explanation;

  // -------------------------------------------------------------------------
  // JSON serialization
  // -------------------------------------------------------------------------

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'holeCards': holeCards.map(_cardToJson).toList(),
      'communityCards': communityCards.map(_cardToJson).toList(),
      'potSize': potSize,
      'betToCall': betToCall,
      'numberOfOpponents': numberOfOpponents,
      'action': action.name,
      'equity': equity,
      'potOdds': potOdds,
      'expectedValue': expectedValue,
      'explanation': explanation,
    };
  }

  factory HandRecord.fromJson(Map<String, dynamic> json) {
    return HandRecord(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      holeCards: (json['holeCards'] as List<dynamic>)
          .map((e) => _cardFromJson(e as Map<String, dynamic>))
          .toList(),
      communityCards: (json['communityCards'] as List<dynamic>)
          .map((e) => _cardFromJson(e as Map<String, dynamic>))
          .toList(),
      potSize: (json['potSize'] as num).toDouble(),
      betToCall: (json['betToCall'] as num).toDouble(),
      numberOfOpponents: json['numberOfOpponents'] as int,
      action: PlayerAction.values.firstWhere(
        (a) => a.name == json['action'] as String,
      ),
      equity: (json['equity'] as num).toDouble(),
      potOdds: (json['potOdds'] as num).toDouble(),
      expectedValue: (json['expectedValue'] as num).toDouble(),
      explanation: json['explanation'] as String,
    );
  }

  /// Serializes to a JSON string.
  String toJsonString() => jsonEncode(toJson());

  /// Deserializes from a JSON string.
  factory HandRecord.fromJsonString(String source) =>
      HandRecord.fromJson(jsonDecode(source) as Map<String, dynamic>);
}

Map<String, dynamic> _cardToJson(PokerCard card) => {
      'suit': card.suit.name,
      'rank': card.rank.name,
    };

PokerCard _cardFromJson(Map<String, dynamic> json) => PokerCard(
      suit: Suit.values.firstWhere((s) => s.name == json['suit'] as String),
      rank: Rank.values.firstWhere((r) => r.name == json['rank'] as String),
    );
