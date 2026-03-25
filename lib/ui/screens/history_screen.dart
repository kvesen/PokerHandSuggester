/// Hand history screen.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../engine/decision_engine.dart';
import '../../engine/equity_calculator.dart';
import '../../models/card.dart';
import '../../models/game_state.dart';
import '../../models/hand_record.dart';
import '../../services/history_service.dart';
import '../../utils/constants.dart';
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
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          title: Text('Clear History', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
          content: Text(
            'Delete all analyzed hands? This cannot be undone.',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Clear All', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
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
      winProbability: record.winProbability,
      tieProbability: record.tieProbability,
      lossProbability: (1 - record.winProbability - record.tieProbability).clamp(0.0, 1.0),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Hand History',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        backgroundColor: (isDark ? Colors.black : Colors.white).withOpacity(0.5),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.transparent),
          ),
        ),
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        actions: [
          if (_records.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear All',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.8),
            radius: 1.5,
            colors: isDark
                ? [
                    const Color(0xFF1E3C2B), // Deep emerald glow
                    const Color(0xFF090B0F), // Dark charcoal
                    const Color(0xFF050505),
                  ]
                : [
                    const Color(0xFFE8F5E9), // Soft mint glow
                    const Color(0xFFF1F5F9), // Light slate
                    const Color(0xFFFFFFFF),
                  ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: _loading
              ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
              : _records.isEmpty
                  ? _EmptyState(isDark: isDark)
                  : RefreshIndicator(
                      onRefresh: _loadHistory,
                      color: Theme.of(context).colorScheme.primary,
                      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      child: ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 20),
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        itemCount: _records.length,
                        itemBuilder: (context, index) {
                          final record = _records[index];
                          return _HistoryCard(
                            record: record,
                            isDark: isDark,
                            onTap: () => _openRecord(record),
                            onDismissed: () => _deleteRecord(record),
                          );
                        },
                      ),
                    ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(isDark ? 0.3 : 0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      size: 64,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No hands analyzed yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Play a hand to see your history here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.record,
    required this.isDark,
    required this.onTap,
    required this.onDismissed,
  });

  final HandRecord record;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(record.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDismissed(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                splashColor: theme.colorScheme.primary.withOpacity(0.1),
                highlightColor: theme.colorScheme.primary.withOpacity(0.05),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(isDark ? 0.4 : 0.8),
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _formatRelative(record.timestamp),
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          _SmallDecisionBadge(action: record.action, isDark: isDark),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ...record.holeCards.map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: _MiniCard(card: c),
                            ),
                          ),
                          if (record.communityCards.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Container(
                                width: 2,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                            Wrap(
                              spacing: 4,
                              children: record.communityCards
                                  .map((c) => _MiniCard(card: c))
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _MiniStat(
                              label: 'Equity',
                              value: '${(record.equity * 100).toStringAsFixed(1)}%',
                              isDark: isDark,
                              icon: Icons.pie_chart_outline_rounded,
                            ),
                            Container(
                              width: 1,
                              height: 20,
                              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                            ),
                            _MiniStat(
                              label: 'EV',
                              value: record.expectedValue >= 0
                                  ? '+${record.expectedValue.toStringAsFixed(1)}'
                                  : record.expectedValue.toStringAsFixed(1),
                              isDark: isDark,
                              icon: Icons.trending_up_rounded,
                              valueColor: record.expectedValue > 0 
                                  ? const Color(0xFF10B981) 
                                  : (record.expectedValue < 0 ? const Color(0xFFEF4444) : null),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
  const _SmallDecisionBadge({required this.action, required this.isDark});

  final PlayerAction action;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (action) {
      PlayerAction.fold => ('FOLD', const Color(0xFFEF4444)),
      PlayerAction.call => ('CALL', const Color(0xFFF59E0B)),
      PlayerAction.raise => ('RAISE', const Color(0xFF10B981)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? color : color.withRed((color.red * 0.8).toInt()),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label, 
    required this.value, 
    required this.isDark,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool isDark;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: isDark ? Colors.white38 : Colors.black38),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black54, 
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13, 
            fontWeight: FontWeight.bold,
            color: valueColor ?? (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.card});

  final PokerCard card;

  @override
  Widget build(BuildContext context) {
    final isRed = card.suit == Suit.hearts || card.suit == Suit.diamonds;
    final color = isRed ? const Color(0xFFEF4444) : const Color(0xFF1C1C1E);
    final rank = kRankLabels[card.rank.name] ?? '';
    final suit = kSuitSymbols[card.suit.name] ?? '';

    return Container(
      width: 28,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            rank,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color, height: 1.1),
          ),
          Text(
            suit,
            style: TextStyle(fontSize: 9, color: color, height: 1.1),
          ),
        ],
      ),
    );
  }
}
