import 'package:flutter_test/flutter_test.dart';

import 'package:poker_hand_suggester/engine/decision_engine.dart';
import 'package:poker_hand_suggester/models/card.dart';
import 'package:poker_hand_suggester/models/hand_record.dart';

void main() {
  final sample = HandRecord(
    id: 'rec-1',
    timestamp: DateTime.utc(2025, 6, 15, 12, 0, 0),
    holeCards: const [
      PokerCard(suit: Suit.hearts, rank: Rank.ace),
      PokerCard(suit: Suit.spades, rank: Rank.king),
    ],
    communityCards: const [
      PokerCard(suit: Suit.clubs, rank: Rank.ten),
      PokerCard(suit: Suit.diamonds, rank: Rank.jack),
      PokerCard(suit: Suit.hearts, rank: Rank.queen),
    ],
    potSize: 200,
    betToCall: 40,
    numberOfOpponents: 3,
    action: PlayerAction.raise,
    equity: 0.72,
    winProbability: 0.68,
    tieProbability: 0.08,
    potOdds: 0.167,
    expectedValue: 113.6,
    explanation: 'Royal flush draw.',
  );

  group('HandRecord serialization', () {
    test('toJson produces expected keys', () {
      final json = sample.toJson();
      expect(json['id'], 'rec-1');
      expect(json['action'], 'raise');
      expect(json['equity'], 0.72);
      expect((json['holeCards'] as List).length, 2);
      expect((json['communityCards'] as List).length, 3);
    });

    test('round-trip JSON preserves all fields', () {
      final json = sample.toJson();
      final restored = HandRecord.fromJson(json);

      expect(restored.id, sample.id);
      expect(restored.timestamp, sample.timestamp);
      expect(restored.action, sample.action);
      expect(restored.equity, sample.equity);
      expect(restored.winProbability, sample.winProbability);
      expect(restored.tieProbability, sample.tieProbability);
      expect(restored.potOdds, sample.potOdds);
      expect(restored.expectedValue, sample.expectedValue);
      expect(restored.explanation, sample.explanation);
      expect(restored.potSize, sample.potSize);
      expect(restored.betToCall, sample.betToCall);
      expect(restored.numberOfOpponents, sample.numberOfOpponents);
      expect(restored.holeCards.length, sample.holeCards.length);
      expect(restored.communityCards.length, sample.communityCards.length);
    });

    test('round-trip string JSON preserves all fields', () {
      final jsonStr = sample.toJsonString();
      final restored = HandRecord.fromJsonString(jsonStr);
      expect(restored.id, sample.id);
      expect(restored.action, PlayerAction.raise);
    });

    test('hole cards are preserved after round-trip', () {
      final restored = HandRecord.fromJson(sample.toJson());
      expect(restored.holeCards[0].suit, Suit.hearts);
      expect(restored.holeCards[0].rank, Rank.ace);
      expect(restored.holeCards[1].suit, Suit.spades);
      expect(restored.holeCards[1].rank, Rank.king);
    });

    test('community cards are preserved after round-trip', () {
      final restored = HandRecord.fromJson(sample.toJson());
      expect(restored.communityCards.length, 3);
      expect(restored.communityCards[0].rank, Rank.ten);
    });

    test('backward-compat: old JSON without winProbability falls back to equity', () {
      final json = sample.toJson()
        ..remove('winProbability')
        ..remove('tieProbability');
      final restored = HandRecord.fromJson(json);
      expect(restored.winProbability, sample.equity);
      expect(restored.tieProbability, 0.0);
    });
  });

  group('HandRecord field access', () {
    test('id field is accessible', () => expect(sample.id, 'rec-1'));
    test('timestamp field is accessible',
        () => expect(sample.timestamp, isA<DateTime>()));
    test('action field is accessible',
        () => expect(sample.action, PlayerAction.raise));
    test('equity field is accessible', () => expect(sample.equity, 0.72));
  });
}
