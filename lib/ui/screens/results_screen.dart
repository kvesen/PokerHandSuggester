/// Results screen: shows the decision, equity, pot odds, and EV.
library;

import 'package:flutter/material.dart';

import '../../engine/decision_engine.dart';
import '../../engine/equity_calculator.dart';
import '../../models/game_state.dart';
import '../../models/hand_record.dart';
import '../../models/position.dart';
import '../../services/history_service.dart';
import '../widgets/card_widget.dart';
import '../widgets/decision_badge.dart';
import '../widgets/table_widget.dart';
import 'manual_input_screen.dart';

/// Displays the recommendation from the decision engine.
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({
    super.key,
    required this.gameState,
    required this.equityResult,
    required this.decision,
    this.isSaved = true,
  });

  final GameState gameState;
  final EquityResult equityResult;
  final Decision decision;

  /// When [true], automatically saves the hand to history on first load.
  /// Set to [false] when viewing from the history screen to prevent re-saving.
  final bool isSaved;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;

  static const _sectionCount = 6;
  static const _staggerMs = 100;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _sectionCount,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );

    _fadeAnims = _controllers
        .map(
          (c) => Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(parent: c, curve: Curves.easeOut),
          ),
        )
        .toList();

    _slideAnims = _controllers
        .map(
          (c) => Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeOut)),
        )
        .toList();

    _startStaggeredAnimations();

    if (widget.isSaved) {
      _saveToHistory();
    }
  }

  void _startStaggeredAnimations() async {
    for (var i = 0; i < _sectionCount; i++) {
      await Future.delayed(Duration(milliseconds: i * _staggerMs));
      if (mounted) _controllers[i].forward();
    }
  }

  Future<void> _saveToHistory() async {
    try {
      final service = await HistoryService.create();
      final record = HandRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        holeCards: widget.gameState.holeCards,
        communityCards: widget.gameState.communityCards,
        potSize: widget.gameState.potSize,
        betToCall: widget.gameState.betToCall,
        numberOfOpponents: widget.gameState.numberOfOpponents,
        action: widget.decision.action,
        equity: widget.decision.equity,
        potOdds: widget.decision.potOdds,
        expectedValue: widget.decision.expectedValue,
        explanation: widget.decision.explanation,
      );
      await service.saveHand(record);
    } catch (_) {
      // History saving is best-effort; don't disrupt the UX.
    }
  }

  bool get _isShowdown => widget.gameState.communityCards.length >= 5;

  void _startNewHand() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const ManualInputScreen()),
      (route) => route.isFirst,
    );
  }

  void _continueHand() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ManualInputScreen(
          preSelectedHoleCards: widget.gameState.holeCards.toList(),
          preSelectedCommunityCards: widget.gameState.communityCards.toList(),
          preFilledPot: widget.gameState.potSize,
          preFilledBet: 0,
          initialOpponents: widget.gameState.numberOfOpponents,
          preSelectedHeroPosition: widget.gameState.heroPosition,
          preSelectedVillainPositions: widget.gameState.villainPositions?.toList(),
          lockHoleCards: true,
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _animated(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeAnims[index],
      child: SlideTransition(position: _slideAnims[index], child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      appBar: AppBar(
        title: const Text(
          'Recommendation',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        tooltip: 'New Hand',
        onPressed: _startNewHand,
        child: const Icon(Icons.refresh),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndTop,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),

            // Section 0 — Decision badge
            _animated(0, DecisionBadge(action: widget.decision.action)),
            const SizedBox(height: 28),

            // Section 1 — Stats row
            _animated(
              1,
              _StatsRow(
                items: [
                  _StatItem(
                    label: 'Equity',
                    value: widget.decision.equityPercent,
                    icon: Icons.bar_chart,
                    color: const Color(0xFF1565C0),
                  ),
                  _StatItem(
                    label: 'Pot Odds',
                    value: widget.decision.potOddsPercent,
                    icon: Icons.percent,
                    color: const Color(0xFF6A1B9A),
                  ),
                  _StatItem(
                    label: 'EV',
                    value: widget.decision.evFormatted,
                    icon: Icons.trending_up,
                    color: widget.decision.expectedValue >= 0
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC62828),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 2 — Equity breakdown
            _animated(
              2,
              _EquityBreakdown(result: widget.equityResult),
            ),
            const SizedBox(height: 20),

            // Section 3 — Poker table visualization
            _animated(
              3,
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: PokerTableWidget(
                  holeCards: widget.gameState.holeCards,
                  communityCards: widget.gameState.communityCards,
                  numberOfOpponents: widget.gameState.numberOfOpponents,
                  potSize: widget.gameState.potSize,
                  heroPosition: widget.gameState.heroPosition,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Section 4 — Explanation
            _animated(
              4,
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 20, color: Color(0xFF1B5E20)),
                        const SizedBox(width: 6),
                        const Text(
                          'Why this decision?',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.decision.explanation,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Section 5 — Cards display + game info
            _animated(
              5,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Hand',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: widget.gameState.holeCards
                        .map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CardWidget(card: c, size: CardSize.large),
                          ),
                        )
                        .toList(),
                  ),
                  if (widget.gameState.communityCards.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Community Cards',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: widget.gameState.communityCards
                          .map(
                              (c) => CardWidget(card: c, size: CardSize.large))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _GameInfoSummary(gameState: widget.gameState),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Showdown banner (only when all 5 community cards are dealt)
            if (_isShowdown)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emoji_events,
                        color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Hand Complete — Showdown',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            if (_isShowdown) const SizedBox(height: 12),

            // Primary action — new hand (showdown) or continue to next street
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: Icon(_isShowdown ? Icons.refresh : Icons.arrow_forward),
                label: Text(_isShowdown ? 'New Hand' : 'Continue Hand'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isShowdown ? _startNewHand : _continueHand,
              ),
            ),
            const SizedBox(height: 12),

            // Secondary action — go back and re-edit same street
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Adjust Inputs'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1B5E20),
                  side: const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private helper widgets
// ---------------------------------------------------------------------------

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.items});

  final List<_StatItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(
                    color: item.color.withAlpha(15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: item.color.withAlpha(80)),
                  ),
                  child: Column(
                    children: [
                      Icon(item.icon, color: item.color, size: 22),
                      const SizedBox(height: 4),
                      Text(
                        item.value,
                        style: TextStyle(
                          color: item.color,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        item.label,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black45),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StatItem {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _EquityBreakdown extends StatelessWidget {
  const _EquityBreakdown({required this.result});

  final EquityResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            // Green top strip
            Container(
              height: 4,
              color: const Color(0xFF388E3C),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _BreakdownItem(
                    label: 'Win',
                    value: '${(result.winProbability * 100).toStringAsFixed(1)}%',
                    color: const Color(0xFF388E3C),
                  ),
                  const VerticalDivider(thickness: 1),
                  _BreakdownItem(
                    label: 'Tie',
                    value: '${(result.tieProbability * 100).toStringAsFixed(1)}%',
                    color: const Color(0xFFF9A825),
                  ),
                  const VerticalDivider(thickness: 1),
                  _BreakdownItem(
                    label: 'Loss',
                    value: '${(result.lossProbability * 100).toStringAsFixed(1)}%',
                    color: const Color(0xFFD32F2F),
                  ),
                  const VerticalDivider(thickness: 1),
                  _BreakdownItem(
                    label: 'Iterations',
                    value: result.iterations.toString(),
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownItem extends StatelessWidget {
  const _BreakdownItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        Text(label,
            style: const TextStyle(color: Colors.black45, fontSize: 11)),
      ],
    );
  }
}

class _GameInfoSummary extends StatelessWidget {
  const _GameInfoSummary({required this.gameState});

  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _InfoItem(
            label: 'Pot',
            value: gameState.potSize.toStringAsFixed(0),
          ),
          _InfoItem(
            label: 'To Call',
            value: gameState.betToCall.toStringAsFixed(0),
          ),
          _InfoItem(
            label: 'Opponents',
            value: '${gameState.numberOfOpponents}',
          ),
          if (gameState.heroPosition != null)
            _InfoItem(
              label: 'Position',
              value: positionLabel(gameState.heroPosition!),
            ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        Text(label,
            style: const TextStyle(color: Colors.black45, fontSize: 12)),
      ],
    );
  }
}

