/// History service: persists hand records using Hive.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/hand_record.dart';

const _kBoxName = 'hand_history';
const _kMaxHistory = 100;

/// Persists and retrieves [HandRecord] objects using Hive.
class HistoryService {
  HistoryService._(this._box);

  final Box<String> _box;

  /// Creates and initialises a [HistoryService] instance.
  static Future<HistoryService> create() async {
    final box = await Hive.openBox<String>(_kBoxName);
    return HistoryService._(box);
  }

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Saves [record] to history. Auto-prunes oldest entries beyond [_kMaxHistory].
  Future<void> saveHand(HandRecord record) async {
    try {
      final records = _loadAll();
      records.insert(0, record);
      if (records.length > _kMaxHistory) {
        records.removeRange(_kMaxHistory, records.length);
      }
      await _saveAll(records);
    } catch (e, st) {
      debugPrint('HistoryService.saveHand: error — $e\n$st');
    }
  }

  /// Returns all stored hand records, sorted newest first.
  Future<List<HandRecord>> getHistory() async {
    try {
      return _loadAll();
    } catch (e, st) {
      debugPrint('HistoryService.getHistory: error — $e\n$st');
      return [];
    }
  }

  /// Deletes all stored hand records.
  Future<void> clearHistory() async {
    try {
      await _box.clear();
    } catch (e, st) {
      debugPrint('HistoryService.clearHistory: error — $e\n$st');
    }
  }

  /// Deletes a specific hand record by [id].
  Future<void> deleteHand(String id) async {
    try {
      final records = _loadAll();
      records.removeWhere((r) => r.id == id);
      await _saveAll(records);
    } catch (e, st) {
      debugPrint('HistoryService.deleteHand: error — $e\n$st');
    }
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  List<HandRecord> _loadAll() {
    final entries = <HandRecord>[];
    for (var i = 0; i < _box.length; i++) {
      final jsonStr = _box.getAt(i);
      if (jsonStr != null) {
        try {
          entries.add(HandRecord.fromJson(
            jsonDecode(jsonStr) as Map<String, dynamic>,
          ));
        } catch (e, st) {
          // Skip corrupted entries; this can occur if the serialisation format
          // changes between app versions or the on-disk data is truncated.
          assert(() {
            debugPrint('HistoryService: skipping corrupted entry – $e\n$st');
            return true;
          }());
        }
      }
    }
    return entries;
  }

  Future<void> _saveAll(List<HandRecord> records) async {
    await _box.clear();
    await _box.addAll(records.map((r) => jsonEncode(r.toJson())));
  }
}
