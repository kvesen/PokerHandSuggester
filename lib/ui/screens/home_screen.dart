/// Home screen — app entry point with navigation to manual input.
library;

import 'package:flutter/material.dart';

import '../../engine/decision_engine.dart';
import '../../models/hand_record.dart';
import '../../services/history_service.dart';
import '../../services/theme_service.dart';
import '../widgets/card_widget.dart';
import 'camera_screen.dart';
import 'history_screen.dart';
import 'manual_input_screen.dart';

/// The main landing screen of the Poker Hand Suggester.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.themeService});

  final ThemeService themeService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<HandRecord> _recentHands = [];
  HistoryService? _historyService;

  @override
  void initState() {
    super.initState();
    _initHistory();
  }

  Future<void> _initHistory() async {
    final service = await HistoryService.create();
    if (!mounted) return;
    setState(() => _historyService = service);
    await _loadRecent();
  }

  Future<void> _loadRecent() async {
    final service = _historyService;
    if (service == null) return;
    final records = await service.getHistory();
    if (mounted) {
      setState(() => _recentHands = records.take(3).toList());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadRecent();
  }

  void _openHistory() {
    final service = _historyService;
    if (service == null) return;
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => HistoryScreen(historyService: service),
          ),
        )
        .then((_) => _loadRecent());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeService.isDark;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF1A237E)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main scrollable content
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 64),

                      // App icon / logo
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withAlpha(80),
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '🃏',
                            style: TextStyle(fontSize: 64),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      const Text(
                        'Poker Hand\nSuggester',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 8,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tagline
                      Text(
                        'Make mathematically optimal decisions\nat the poker table.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withAlpha(210),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Feature chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: const [
                          _FeatureChip(
                              icon: Icons.calculate,
                              label: 'Equity Analysis'),
                          _FeatureChip(
                              icon: Icons.percent, label: 'Pot Odds'),
                          _FeatureChip(
                              icon: Icons.trending_up,
                              label: 'EV Calculation'),
                          _FeatureChip(
                              icon: Icons.recommend,
                              label: 'Fold/Call/Raise'),
                        ],
                      ),
                      const SizedBox(height: 48),

                      // Primary action buttons
                      Row(
                        children: [
                          Expanded(
                            child: _ActionCard(
                              emoji: '📸',
                              title: 'Scan Table',
                              description:
                                  'Take a photo to\nauto-detect cards',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const CameraScreen(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionCard(
                              emoji: '✍️',
                              title: 'Manual Input',
                              description: 'Select cards\nfrom the grid',
                              onTap: () => Navigator.of(context)
                                  .push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const ManualInputScreen(),
                                    ),
                                  )
                                  .then((_) => _loadRecent()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Recent Activity section
                      _RecentActivity(
                        records: _recentHands,
                        onSeeAll: _openHistory,
                      ),

                      const SizedBox(height: 16),

                      // Version / footer
                      Text(
                        'Texas Hold\'em · Phase 3',
                        style: TextStyle(
                          color: Colors.white.withAlpha(120),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Top-left: history button
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.history, color: Colors.white),
                  tooltip: 'Hand History',
                  onPressed: _openHistory,
                ),
              ),

              // Top-right: theme toggle
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode : Icons.dark_mode,
                    color: Colors.white,
                  ),
                  tooltip: isDark ? 'Light Mode' : 'Dark Mode',
                  onPressed: () => widget.themeService.toggleTheme(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent Activity section
// ---------------------------------------------------------------------------

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({
    required this.records,
    required this.onSeeAll,
  });

  final List<HandRecord> records;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (records.isNotEmpty)
              GestureDetector(
                onTap: onSeeAll,
                child: Text(
                  'See All',
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white.withAlpha(200),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (records.isEmpty)
          Center(
            child: Text(
              'Your analyzed hands will appear here',
              style: TextStyle(
                color: Colors.white.withAlpha(130),
                fontSize: 13,
              ),
            ),
          )
        else
          ...records.map((r) => _RecentHandTile(record: r)),
      ],
    );
  }
}

class _RecentHandTile extends StatelessWidget {
  const _RecentHandTile({required this.record});

  final HandRecord record;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (record.action) {
      PlayerAction.fold => ('FOLD', const Color(0xFFD32F2F)),
      PlayerAction.call => ('CALL', const Color(0xFFF9A825)),
      PlayerAction.raise => ('RAISE', const Color(0xFF388E3C)),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withAlpha(40)),
      ),
      child: Row(
        children: [
          // Hole cards
          ...record.holeCards.map(
            (c) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: CardWidget(card: c, size: CardSize.small),
            ),
          ),
          const SizedBox(width: 8),
          // Decision badge (small)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          // Timestamp
          Text(
            _formatRelative(record.timestamp),
            style: TextStyle(
              color: Colors.white.withAlpha(160),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ---------------------------------------------------------------------------
// Existing helper widgets
// ---------------------------------------------------------------------------

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// A tappable card tile used for the two main action buttons on the home screen.
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
