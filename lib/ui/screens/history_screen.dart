/// Hand history screen.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../engine/decision_engine.dart';
import '../../engine/equity_calculator.dart';
import '../../models/game_state.dart';
import '../../models/hand_record.dart';
import '../../services/history_service.dart';
import '../widgets/card_widget.dart';
import 'results_screen.dart';

/// Displays the full list of analyzed hands with swipe-to-delete and
/// pull-to-refresh support.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.historyService});

  final HistoryService historyService;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HandRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    final records = await widget.historyService.getHistory();
    if (mounted) {
      setState(() {
        _records = records;
        _loading = false;
      });
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History'),
        content:
            const Text('Delete all analyzed hands? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.historyService.clearHistory();
      if (mounted) setState(() => _records = []);
    }
  }

  Future<void> _deleteRecord(HandRecord record) async {
    await widget.historyService.deleteHand(record.id);
    if (mounted) {
      setState(() => _records.removeWhere((r) => r.id == record.id));
    }
  }

  void _openRecord(HandRecord record) {
    final gameState = GameState(
      holeCards: record.holeCards,
      communityCards: record.communityCards,
      potSize: record.potSize,
      betToCall: record.betToCall,
      numberOfOpponents: record.numberOfOpponents,
    );
    final equityResult = EquityResult(
      winProbability: record.equity,
      tieProbability: 0,
      lossProbability: 1 - record.equity,
      iterations: 0,
    );
    final decision = Decision(
      action: record.action,
      equity: record.equity,
      potOdds: record.potOdds,
      expectedValue: record.expectedValue,
      explanation: record.explanation,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResultsScreen(
          gameState: gameState,
          equityResult: equityResult,
          decision: decision,
          isSaved: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hand History'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_records.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear All',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? _EmptyState()
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _records.length,
                    itemBuilder: (context, index) {
                      final record = _records[index];
                      return _HistoryCard(
                        record: record,
                        onTap: () => _openRecord(record),
                        onDismissed: () => _deleteRecord(record),
                      );
                    },
                  ),
                ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.casino_outlined,
            size: 72,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No hands analyzed yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Play a hand to see your history here.',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.record,
    required this.onTap,
    required this.onDismissed,
  });

  final HandRecord record;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(record.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatRelative(record.timestamp),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    _SmallDecisionBadge(action: record.action),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ...record.holeCards.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: CardWidget(card: c, size: CardSize.small),
                      ),
                    ),
                    if (record.communityCards.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 1,
                        height: 36,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(width: 8),
                      ...record.communityCards.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: CardWidget(card: c, size: CardSize.small),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MiniStat(
                      label: 'Equity',
                      value: '${(record.equity * 100).toStringAsFixed(1)}%',
                    ),
                    const SizedBox(width: 16),
                    _MiniStat(
                      label: 'EV',
                      value: record.expectedValue >= 0
                          ? '+${record.expectedValue.toStringAsFixed(1)}'
                          : record.expectedValue.toStringAsFixed(1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatRelative(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, y').format(dt);
  }
}

class _SmallDecisionBadge extends StatelessWidget {
  const _SmallDecisionBadge({required this.action});

  final PlayerAction action;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (action) {
      PlayerAction.fold => ('FOLD', const Color(0xFFD32F2F)),
      PlayerAction.call => ('CALL', const Color(0xFFF9A825)),
      PlayerAction.raise => ('RAISE', const Color(0xFF388E3C)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
