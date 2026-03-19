/// History service: persists hand records using SharedPreferences.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/hand_record.dart';

const _kHistoryKey = 'hand_history';
const _kMaxHistory = 100;

/// Persists and retrieves [HandRecord] objects using [SharedPreferences].
class HistoryService {
  HistoryService._();

  /// Creates and initialises a [HistoryService] instance.
  static Future<HistoryService> create() async {
    return HistoryService._();
  }

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Saves [record] to history. Auto-prunes oldest entries beyond 100.
  Future<void> saveHand(HandRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await _loadAll(prefs);
    records.insert(0, record);
    if (records.length > _kMaxHistory) {
      records.removeRange(_kMaxHistory, records.length);
    }
    await _saveAll(prefs, records);
  }

  /// Returns all stored hand records, sorted newest first.
  Future<List<HandRecord>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return _loadAll(prefs);
  }

  /// Deletes all stored hand records.
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHistoryKey);
  }

  /// Deletes a specific hand record by [id].
  Future<void> deleteHand(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await _loadAll(prefs);
    records.removeWhere((r) => r.id == id);
    await _saveAll(prefs, records);
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  Future<List<HandRecord>> _loadAll(SharedPreferences prefs) async {
    final jsonStr = prefs.getString(_kHistoryKey);
    if (jsonStr == null) return [];
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => HandRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAll(
    SharedPreferences prefs,
    List<HandRecord> records,
  ) async {
    final list = records.map((r) => r.toJson()).toList();
    await prefs.setString(_kHistoryKey, jsonEncode(list));
  }
}
