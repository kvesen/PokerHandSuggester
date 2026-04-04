/// Manual input screen: card selection, pot/bet inputs, calculate button.
library;

import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../engine/equity_calculator.dart';
import '../../engine/decision_engine.dart';
import '../../engine/equity_isolate.dart';
import '../../models/card.dart';
import '../../models/game_mode.dart';
import '../../models/game_state.dart';
import '../../models/position.dart';
import '../../services/crash_reporting_service.dart';
import '../../utils/constants.dart';
import '../utils/error_helpers.dart';
import '../widgets/card_selector.dart';
import '../widgets/card_widget.dart';
import '../widgets/position_selector.dart';
import 'results_screen.dart';

/// Screen where the user selects their cards and enters game details.
class ManualInputScreen extends StatefulWidget {
  const ManualInputScreen({
    super.key,
    this.preSelectedHoleCards,
    this.preSelectedCommunityCards,
    this.preFilledPot,
    this.preFilledBet,
    this.preSelectedHeroPosition,
    this.preSelectedVillainPositions,
    this.initialOpponents,
    this.lockHoleCards = false,
    this.preSelectedGameMode,
  });

  /// Optional hole cards pre-populated from the camera/detection flow.
  final List<PokerCard>? preSelectedHoleCards;

  /// Optional community cards pre-populated from the camera/detection flow.
  final List<PokerCard>? preSelectedCommunityCards;

  /// Optional pre-filled pot size (for "Continue Hand" flow).
  final double? preFilledPot;

  /// Optional pre-filled bet to call (for "Continue Hand" flow).
  final double? preFilledBet;

  /// Optional pre-filled hero position (carried over from prior street).
  final TablePosition? preSelectedHeroPosition;

  /// Optional pre-filled villain positions (carried over from prior street).
  final List<TablePosition>? preSelectedVillainPositions;

  /// Optional pre-filled opponent count (carried over from prior street).
  final int? initialOpponents;

  /// When [true], the hole-cards tab is locked and cannot be edited.
  /// Used when continuing a hand into a new street.
  final bool lockHoleCards;

  /// Optional pre-selected game mode (carried over from prior street).
  final GameMode? preSelectedGameMode;

  @override
  State<ManualInputScreen> createState() => _ManualInputScreenState();
}

class _ManualInputScreenState extends State<ManualInputScreen>
    with SingleTickerProviderStateMixin {
  late final List<PokerCard> _holeCards;
  late final List<PokerCard> _communityCards;

  late final TextEditingController _potController;
  late final TextEditingController _betController;
  final _formKey = GlobalKey<FormState>();

  late int _opponents;
  bool _isCalculating = false;
  TablePosition? _heroPosition;
  late List<TablePosition> _villainPositions;
  late GameMode _gameMode;

  // Which section is the selector currently filling? 0 = hole, 1 = community.
  late int _activeSection;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _holeCards = List<PokerCard>.from(widget.preSelectedHoleCards ?? []);
    _communityCards =
        List<PokerCard>.from(widget.preSelectedCommunityCards ?? []);
    _potController = TextEditingController(
      text: widget.preFilledPot?.toStringAsFixed(0) ?? '100',
    );
    _betController = TextEditingController(
      text: widget.preFilledBet?.toStringAsFixed(0) ?? '20',
    );
    _opponents = widget.initialOpponents ?? 2;
    _heroPosition = widget.preSelectedHeroPosition;
    _villainPositions =
        List<TablePosition>.from(widget.preSelectedVillainPositions ?? []);
    _gameMode = widget.preSelectedGameMode ?? GameMode.cashGame;
    // When hole cards are locked, open directly on the community cards tab.
    _activeSection = widget.lockHoleCards ? 1 : 0;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _activeSection,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _activeSection = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _potController.dispose();
    _betController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _onCardToggled(PokerCard card) {
    setState(() {
      if (_activeSection == 0) {
        // Hole cards section
        if (_holeCards.contains(card)) {
          _holeCards.remove(card);
        } else if (_holeCards.length < kMaxHoleCards) {
          _holeCards.add(card);
        }
      } else {
        // Community cards section
        if (_communityCards.contains(card)) {
          _communityCards.remove(card);
        } else if (_communityCards.length < kMaxCommunityCards) {
          _communityCards.add(card);
        }
      }
    });
  }

  static Future<EquityResult> _runInIsolate(
    List<PokerCard> holeCards,
    List<PokerCard> communityCards,
    int numOpponents,
  ) {
    final params = EquityIsolateParams(
      holeCards: holeCards,
      communityCards: communityCards,
      numOpponents: numOpponents,
    );
    return Isolate.run(() => runEquityCalculation(params));
  }

  Future<void> _calculate() async {
    if (_isCalculating) return; // Prevent multiple simultaneous calculations
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    if (_holeCards.length < kMaxHoleCards) {
      _showError('Please select exactly 2 hole cards.');
      return;
    }
    final communityCount = _communityCards.length;
    if (communityCount == 1 || communityCount == 2) {
      _showError(
          'Community cards must be 0, 3, 4, or 5 — not $communityCount.');
      return;
    }

    setState(() => _isCalculating = true);

    try {
      final pot = double.parse(_potController.text);
      final bet = double.parse(_betController.text);

      final holeCardsCopy = List<PokerCard>.from(_holeCards);
      final communityCardsCopy = List<PokerCard>.from(_communityCards);
      final opponentsCopy = _opponents;

      final equityResult =
          await _runInIsolate(holeCardsCopy, communityCardsCopy, opponentsCopy);

      final decision = DecisionEngine.decide(
        equity: equityResult.equity,
        pot: pot,
        costToCall: bet,
        heroPosition: _heroPosition,
        villainPositions: _villainPositions.isNotEmpty ? _villainPositions : null,
        gameMode: _gameMode,
      );

      final gameState = GameState(
        holeCards: List.unmodifiable(_holeCards),
        communityCards: List.unmodifiable(_communityCards),
        potSize: pot,
        betToCall: bet,
        numberOfOpponents: _opponents,
        heroPosition: _heroPosition,
        villainPositions: _villainPositions.isNotEmpty ? List.unmodifiable(_villainPositions) : null,
        gameMode: _gameMode,
      );

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ResultsScreen(
            gameState: gameState,
            equityResult: equityResult,
            decision: decision,
          ),
        ),
      );
    } catch (e, st) {
      CrashReportingService.recordError(e, st);
      if (mounted) {
        showErrorSnackBar(context, 'Could not calculate — please try again.');
      }
    } finally {
      if (mounted) setState(() => _isCalculating = false);
    }
  }

  void _resetToNewHand() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const ManualInputScreen()),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  String _buildPositionSubtitle() {
    final heroPart = _heroPosition != null
        ? 'You: ${positionLabel(_heroPosition!)}'
        : null;
    final villainPart = _villainPositions.isNotEmpty
        ? 'Opp: ${_villainPositions.map(positionLabel).join(', ')}'
        : null;

    if (heroPart != null && villainPart != null) {
      return '$heroPart  |  $villainPart';
    }
    if (heroPart != null) return heroPart;
    if (villainPart != null) return villainPart;
    return 'Improves accuracy';
  }

  // ---------------------------------------------------------------------------
  // Street helpers
  // ---------------------------------------------------------------------------

  ({String title, Color color}) get _streetInfo {
    switch (widget.preSelectedCommunityCards?.length ?? 0) {
      case 0:
        return (title: 'Flop', color: const Color(0xFF3B82F6));
      case 3:
        return (title: 'Turn', color: const Color(0xFFF59E0B));
      case 4:
        return (title: 'River', color: const Color(0xFFEF4444));
      case 5:
        return (title: 'Showdown', color: const Color(0xFF8B5CF6));
      default:
        return (title: 'Select Cards', color: Colors.grey.shade600);
    }
  }

  String get _streetTitle =>
      widget.lockHoleCards ? _streetInfo.title : 'Select Cards';

  void _lockedCardToggle(PokerCard _) {}

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _streetTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        // Glassmorphism surface — intentionally differs between light/dark modes.
        backgroundColor: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.5),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.transparent),
          ),
        ),
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              _resetToNewHand();
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reset', style: TextStyle(fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
            ),
          ),
        ],
        bottom: widget.lockHoleCards
            ? PreferredSize(
                preferredSize: const Size.fromHeight(32),
                child: Container(
                  width: double.infinity,
                  color: _streetInfo.color.withValues(alpha: isDark ? 0.6 : 0.8),
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  child: Text(
                    _streetTitle.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : null,
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
          child: Form(
            key: _formKey,
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return _buildWideLayout(isDark);
                }
                return _buildNarrowLayout(isDark);
              },
            ),
          ),
        ),
      ),
    );
  }

  // Wide (tablet/desktop) layout
  Widget _buildWideLayout(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: ListView(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            children: [
              _SectionHeader(
                  title: 'Your Hand',
                  subtitle: '${_holeCards.length}/2 cards'),
              const SizedBox(height: 12),
              _CardPreviewRow(
                  cards: _holeCards,
                  emptySlots: kMaxHoleCards - _holeCards.length),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Community Cards',
                subtitle: '${_communityCards.length}/5 cards',
              ),
              const SizedBox(height: 12),
              _CardPreviewRow(
                cards: _communityCards,
                emptySlots: kMaxCommunityCards - _communityCards.length,
              ),
              const SizedBox(height: 32),
              _buildCardSelectorBox(isDark),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 24, 24, 24),
            physics: const BouncingScrollPhysics(),
            children: [
              ..._buildGameInfoWidgets(isDark),
              const SizedBox(height: 32),
              _buildCalculateButton(),
            ],
          ),
        ),
      ],
    );
  }

  // Narrow (phone) layout
  Widget _buildNarrowLayout(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        _SectionHeader(
            title: 'Your Hand',
            subtitle: '${_holeCards.length}/2 cards'),
        const SizedBox(height: 12),
        _CardPreviewRow(
            cards: _holeCards,
            emptySlots: kMaxHoleCards - _holeCards.length),
        const SizedBox(height: 24),
        _SectionHeader(
          title: 'Community Cards',
          subtitle: '${_communityCards.length}/5 cards',
        ),
        const SizedBox(height: 12),
        _CardPreviewRow(
          cards: _communityCards,
          emptySlots: kMaxCommunityCards - _communityCards.length,
        ),
        const SizedBox(height: 32),
        _buildCardSelectorBox(isDark),
        const SizedBox(height: 32),
        ..._buildGameInfoWidgets(isDark),
        const SizedBox(height: 40),
        _buildCalculateButton(),
      ],
    );
  }

  Widget _buildCardSelectorBox(bool isDark) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            // Glassmorphism surface — intentionally differs between light/dark modes.
            color: theme.colorScheme.surface.withValues(alpha: isDark ? 0.3 : 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              // Glassmorphism surface — intentionally differs between light/dark modes.
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      // Glassmorphism surface — intentionally differs between light/dark modes.
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                  indicatorColor: theme.colorScheme.primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  dividerColor: Colors.transparent,
                  onTap: widget.lockHoleCards
                      ? (index) {
                          if (index == 0) _tabController.animateTo(1);
                        }
                      : null,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Hole Cards (2)',
                            style: TextStyle(
                              color: widget.lockHoleCards ? Colors.grey.shade500 : null,
                            ),
                          ),
                          if (widget.lockHoleCards) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.lock_rounded, size: 14, color: Colors.grey.shade500),
                          ],
                        ],
                      ),
                    ),
                    const Tab(text: 'Community (0–5)'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: CardSelector(
                  selectedCards: _activeSection == 0 ? _holeCards : _communityCards,
                  onCardToggled: _activeSection == 0 && widget.lockHoleCards
                      ? _lockedCardToggle
                      : _onCardToggled,
                  disabledCards: _activeSection == 0 ? _communityCards : _holeCards,
                  maxSelectable: _activeSection == 0 ? kMaxHoleCards : kMaxCommunityCards,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGameInfoWidgets(bool isDark) {
    final theme = Theme.of(context);
    return [
      Text(
        'Game Info',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
          letterSpacing: -0.5,
        ),
      ),
      const SizedBox(height: 16),
      ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              // Glassmorphism surface — intentionally differs between light/dark modes.
              color: theme.colorScheme.surface.withValues(alpha: isDark ? 0.3 : 0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                // Glassmorphism surface — intentionally differs between light/dark modes.
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _NumericField(
                        controller: _potController,
                        label: 'Pot Size',
                        hint: '100',
                        mustBePositive: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _NumericField(
                        controller: _betController,
                        label: 'Bet to Call',
                        hint: '20',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text('Opponents:',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface)),
                    const Spacer(),
                    Semantics(
                      label: 'Decrease number of opponents',
                      child: IconButton(
                        icon: Icon(
                          Icons.remove_circle_rounded,
                          color: _opponents > 1
                              ? theme.colorScheme.primary
                              : Colors.grey.shade500,
                        ),
                        onPressed: _opponents > 1
                            ? () => setState(() {
                                  _opponents--;
                                  if (_villainPositions.length > _opponents) {
                                    _villainPositions =
                                        _villainPositions.sublist(0, _opponents);
                                  }
                                })
                            : null,
                      ),
                    ),
                    Container(
                      width: 32,
                      alignment: Alignment.center,
                      child: Text(
                        '$_opponents',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Semantics(
                      label: 'Increase number of opponents',
                      child: IconButton(
                        icon: Icon(
                          Icons.add_circle_rounded,
                          color: _opponents < 9
                              ? theme.colorScheme.primary
                              : Colors.grey.shade500,
                        ),
                        onPressed: _opponents < 9 ? () => setState(() => _opponents++) : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildGameModeSelector(isDark, theme),
                const SizedBox(height: 16),
                Theme(
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      'Table Position (optional)',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface),
                    ),
                    subtitle: Text(
                      _buildPositionSubtitle(),
                      style: TextStyle(
                        fontSize: 12,
                        color: (_heroPosition != null || _villainPositions.isNotEmpty)
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 20),
                        child: Text(
                          'Tap a seat to mark your position (green).\n'
                          'Tap other seats to mark opponents (red).',
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.4),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: PositionSelector(
                          selectedPosition: _heroPosition,
                          onPositionChanged: (pos) => setState(() => _heroPosition = pos),
                          villainPositions: _villainPositions,
                          onVillainPositionsChanged: (positions) =>
                              setState(() => _villainPositions = positions),
                          maxVillains: _opponents,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildGameModeSelector(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Game Mode:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: GameMode.values.map((mode) {
            final isSelected = _gameMode == mode;
            return GestureDetector(
              onTap: () => setState(() => _gameMode = mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withValues(alpha: 0.8),
                          ],
                        )
                      : null,
                  color: isSelected
                      ? null
                      : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  gameModeLabel(mode),
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            gameModeDescription(_gameMode),
            key: ValueKey(_gameMode),
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalculateButton() {
    return Semantics(
      label: 'Calculate best poker move',
      button: true,
      child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FilledButton(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _isCalculating ? null : _calculate,
        child: _isCalculating
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 22, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'Calculate Best Move',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Colors.white,
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
// Private helper widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            subtitle,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _CardPreviewRow extends StatelessWidget {
  const _CardPreviewRow({required this.cards, required this.emptySlots});

  final List<PokerCard> cards;
  final int emptySlots;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          ...cards.map(
            (c) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CardWidget(card: c, selected: true),
            ),
          ),
          ...List.generate(
            emptySlots,
            (_) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                width: 50,
                height: 72,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.4),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumericField extends StatelessWidget {
  const _NumericField({
    required this.controller,
    required this.label,
    required this.hint,
    this.minValue = 0,
    this.mustBePositive = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final double minValue;
  final bool mustBePositive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        hintStyle:
            TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
        filled: true,
        fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.03),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Required';
        final n = double.tryParse(value);
        if (n == null) return 'Enter a valid number';
        if (mustBePositive && n <= minValue) {
          return '>${minValue.toStringAsFixed(0)}';
        }
        if (!mustBePositive && n < minValue) {
          return '≥${minValue.toStringAsFixed(0)}';
        }
        return null;
      },
    );
  }
}
