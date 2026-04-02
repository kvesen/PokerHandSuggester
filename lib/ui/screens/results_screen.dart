/// Results screen: shows the decision, equity, pot odds, and EV.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../engine/decision_engine.dart';
import '../../engine/equity_calculator.dart';
import '../../engine/hand_evaluator.dart';
import '../../models/card.dart';
import '../../models/game_mode.dart';
import '../../models/game_state.dart';
import '../../models/hand_record.dart';
import '../../models/position.dart';
import '../../services/history_service.dart';
import '../../utils/app_colors.dart';
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

  HistoryService? _historyService;

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
      HistoryService.create().then((s) {
        if (!mounted) return;
        _historyService = s;
        _saveToHistory();
      });
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
      final service = _historyService;
      if (service == null) return;
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
        winProbability: widget.equityResult.winProbability,
        tieProbability: widget.equityResult.tieProbability,
        potOdds: widget.decision.potOdds,
        expectedValue: widget.decision.expectedValue,
        explanation: widget.decision.explanation,
        gameMode: widget.gameState.gameMode,
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
          preSelectedGameMode: widget.gameState.gameMode,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Recommendation',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor:
            (isDark ? Colors.black : Colors.white).withOpacity(0.5),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.transparent),
          ),
        ),
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: isDark ? Colors.black : Colors.white,
        tooltip: 'New Hand',
        onPressed: _startNewHand,
        child: const Icon(Icons.refresh),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndTop,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.8),
            radius: 1.5,
            colors: isDark
                ? [
                    const Color(0xFF1E3C2B),
                    const Color(0xFF090B0F),
                    const Color(0xFF050505),
                  ]
                : [
                    const Color(0xFFE8F5E9),
                    const Color(0xFFF1F5F9),
                    const Color(0xFFFFFFFF),
                  ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Space below the AppBar (SafeArea top + AppBar height)
              SizedBox(
                height: MediaQuery.of(context).padding.top +
                    kToolbarHeight +
                    8,
              ),

              // Section 0 — Decision badge
              _animated(0, DecisionBadge(action: widget.decision.action)),
              const SizedBox(height: 28),

              // Section 1 — Stats row
              _animated(
                1,
                _StatsRow(
                  isDark: isDark,
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

              // Animated equity bar
              _animated(
                2,
                _EquityBar(equity: widget.decision.equity, isDark: isDark),
              ),
              const SizedBox(height: 12),

              // Hand strength badge
              if (widget.gameState.communityCards.isNotEmpty)
                _animated(
                  2,
                  _HandStrengthBadge(
                    holeCards: widget.gameState.holeCards,
                    communityCards: widget.gameState.communityCards,
                  ),
                ),
              if (widget.gameState.communityCards.isNotEmpty)
                const SizedBox(height: 12),

              // Section 2 — Equity breakdown
              _animated(
                3,
                _EquityBreakdown(result: widget.equityResult, isDark: isDark),
              ),
              const SizedBox(height: 20),

              // Section 3 — Poker table visualization
              _animated(
                4,
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
                5,
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? kDarkGreenBackground
                        : kLightGreenBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? kDarkGreenBorder : kLightGreenBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: isDark
                                ? kPrimaryGreenDark
                                : kPrimaryGreen,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Why this decision?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.decision.explanation,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color:
                              isDark ? Colors.white70 : Colors.black87,
                        ),
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
                    Text(
                      'Your Hand',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isDark ? kPrimaryGreenDark : kPrimaryGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: widget.gameState.holeCards
                          .map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child:
                                  CardWidget(card: c, size: CardSize.large),
                            ),
                          )
                          .toList(),
                    ),
                    if (widget.gameState.communityCards.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Community Cards',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: isDark ? kPrimaryGreenDark : kPrimaryGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: widget.gameState.communityCards
                            .map((c) =>
                                CardWidget(card: c, size: CardSize.large))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _GameInfoSummary(
                      gameState: widget.gameState,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Showdown banner
              if (_isShowdown)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [kPrimaryGreenDark, kMediumGreenDark]
                          : [kPrimaryGreen, const Color(0xFF4CAF50)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emoji_events,
                          color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Hand Complete — Showdown',
                        style: TextStyle(
                          color: isDark ? Colors.black87 : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_isShowdown) const SizedBox(height: 12),

              // Primary action button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: Icon(
                      _isShowdown ? Icons.refresh : Icons.arrow_forward),
                  label:
                      Text(_isShowdown ? 'New Hand' : 'Continue Hand'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor:
                        isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed:
                      _isShowdown ? _startNewHand : _continueHand,
                ),
              ),
              const SizedBox(height: 12),

              // Secondary action button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Adjust Inputs'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(
                        color: theme.colorScheme.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private helper widgets
// ---------------------------------------------------------------------------

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.items, required this.isDark});

  final List<_StatItem> items;
  final bool isDark;

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
                    borderRadius: BorderRadius.circular(16),
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
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
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
  const _EquityBreakdown({required this.result, required this.isDark});

  final EquityResult result;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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
                    isDark: isDark,
                  ),
                  const VerticalDivider(thickness: 1),
                  _BreakdownItem(
                    label: 'Tie',
                    value: '${(result.tieProbability * 100).toStringAsFixed(1)}%',
                    color: const Color(0xFFF9A825),
                    isDark: isDark,
                  ),
                  const VerticalDivider(thickness: 1),
                  _BreakdownItem(
                    label: 'Loss',
                    value: '${(result.lossProbability * 100).toStringAsFixed(1)}%',
                    color: const Color(0xFFD32F2F),
                    isDark: isDark,
                  ),
                  const VerticalDivider(thickness: 1),
                  _BreakdownItem(
                    label: 'Iterations',
                    value: result.iterations.toString(),
                    color: Colors.grey,
                    isDark: isDark,
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
    required this.isDark,
  });

  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black45,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _GameInfoSummary extends StatelessWidget {
  const _GameInfoSummary({required this.gameState, required this.isDark});

  final GameState gameState;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final mode = gameState.gameMode;
    final showMode = mode != null && mode != GameMode.cashGame;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? kDarkGreenBackground : kLightGreenBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? kDarkGreenBorder : kLightGreenBorder,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _InfoItem(
                label: 'Pot',
                value: gameState.potSize.toStringAsFixed(0),
                isDark: isDark,
              ),
              _InfoItem(
                label: 'To Call',
                value: gameState.betToCall.toStringAsFixed(0),
                isDark: isDark,
              ),
              _InfoItem(
                label: 'Opponents',
                value: '${gameState.numberOfOpponents}',
                isDark: isDark,
              ),
              if (gameState.heroPosition != null)
                _InfoItem(
                  label: 'Position',
                  value: positionLabel(gameState.heroPosition!),
                  isDark: isDark,
                ),
            ],
          ),
          if (showMode) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (isDark ? kPrimaryGreenDark : kPrimaryGreen).withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sports_esports_rounded,
                    size: 14,
                    color: isDark ? kPrimaryGreenDark : kPrimaryGreen,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    gameModeLabel(mode),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? kPrimaryGreenDark : kPrimaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: isDark ? kPrimaryGreenDark : kPrimaryGreen,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black45,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Maps a [HandRanking] enum value to a readable label.
String _handRankLabel(HandRanking rank) => switch (rank) {
      HandRanking.highCard => 'High Card',
      HandRanking.onePair => 'One Pair',
      HandRanking.twoPair => 'Two Pair',
      HandRanking.threeOfAKind => 'Three of a Kind',
      HandRanking.straight => 'Straight',
      HandRanking.flush => 'Flush',
      HandRanking.fullHouse => 'Full House',
      HandRanking.fourOfAKind => 'Four of a Kind',
      HandRanking.straightFlush => 'Straight Flush',
      HandRanking.royalFlush => 'Royal Flush',
    };

/// Animated equity bar shown below the stats row.
class _EquityBar extends StatelessWidget {
  const _EquityBar({required this.equity, required this.isDark});

  final double equity;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final equityPct = equity * 100;
    final barColor = equity >= 0.5
        ? const Color(0xFF22C55E)
        : equity >= 0.3
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return Semantics(
      label: 'Equity ${equityPct.toStringAsFixed(1)} percent',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: equity),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          final animatedPct = value * 100;
          final animatedOppPct = (1 - value) * 100;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'You ${animatedPct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: barColor,
                    ),
                  ),
                  Text(
                    '${animatedOppPct.toStringAsFixed(1)}% Opponents',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 14,
                  backgroundColor:
                      isDark ? Colors.white12 : Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Pill badge showing the best evaluated hand rank when community cards exist.
class _HandStrengthBadge extends StatelessWidget {
  const _HandStrengthBadge({
    required this.holeCards,
    required this.communityCards,
  });

  final List<PokerCard> holeCards;
  final List<PokerCard> communityCards;

  @override
  Widget build(BuildContext context) {
    final result = HandEvaluator.evaluate(holeCards + communityCards);
    final label = _handRankLabel(result.ranking);
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: colorScheme.onPrimaryContainer,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
