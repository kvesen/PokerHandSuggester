import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:poker_hand_suggester/engine/decision_engine.dart';
import 'package:poker_hand_suggester/models/card.dart';
import 'package:poker_hand_suggester/models/hand_record.dart';
import 'package:poker_hand_suggester/services/history_service.dart';

HandRecord _makeRecord({
  String? id,
  DateTime? timestamp,
  PlayerAction action = PlayerAction.call,
}) {
  return HandRecord(
    id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    timestamp: timestamp ?? DateTime.now(),
    holeCards: const [
      PokerCard(suit: Suit.hearts, rank: Rank.ace),
      PokerCard(suit: Suit.spades, rank: Rank.king),
    ],
    communityCards: const [],
    potSize: 100,
    betToCall: 20,
    numberOfOpponents: 2,
    action: action,
    equity: 0.65,
    winProbability: 0.60,
    tieProbability: 0.10,
    potOdds: 0.167,
    expectedValue: 47.5,
    explanation: 'Strong hand.',
  );
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('HistoryService', () {
    test('saves and retrieves a hand', () async {
      final service = await HistoryService.create();
      final record = _makeRecord(id: 'test-1');
      await service.saveHand(record);

      final history = await service.getHistory();
      expect(history.length, 1);
      expect(history.first.id, 'test-1');
    });

    test('history is sorted newest first', () async {
      final service = await HistoryService.create();
      final older = _makeRecord(
        id: 'old',
        timestamp: DateTime(2024, 1, 1),
      );
      final newer = _makeRecord(
        id: 'new',
        timestamp: DateTime(2025, 1, 1),
      );

      await service.saveHand(older);
      await service.saveHand(newer);

      final history = await service.getHistory();
      expect(history.first.id, 'new');
      expect(history.last.id, 'old');
    });

    test('clearHistory removes all records', () async {
      final service = await HistoryService.create();
      await service.saveHand(_makeRecord(id: 'a'));
      await service.saveHand(_makeRecord(id: 'b'));

      await service.clearHistory();
      final history = await service.getHistory();
      expect(history, isEmpty);
    });

    test('deleteHand removes only the specified record', () async {
      final service = await HistoryService.create();
      await service.saveHand(_makeRecord(id: 'keep'));
      await service.saveHand(_makeRecord(id: 'delete-me'));

      await service.deleteHand('delete-me');
      final history = await service.getHistory();
      expect(history.length, 1);
      expect(history.first.id, 'keep');
    });

    test('auto-prunes history to 100 entries', () async {
      final service = await HistoryService.create();
      for (var i = 0; i < 105; i++) {
        await service.saveHand(_makeRecord(id: 'hand-$i'));
      }
      final history = await service.getHistory();
      expect(history.length, 100);
    });
  });
}
