/// Manual input screen: card selection, pot/bet inputs, calculate button.
library;

import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../engine/equity_calculator.dart';
import '../../engine/decision_engine.dart';
import '../../engine/equity_isolate.dart';
import '../../models/card.dart';
import '../../models/game_state.dart';
import '../../models/position.dart';
import '../../utils/constants.dart';
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

  /// Runs the equity calculation in a separate isolate.
  ///
  /// This must be a [static] method so the [Isolate.run] closure does not
  /// capture [this] (which contains unsendable Flutter framework objects like
  /// [TabController], [TextEditingController], etc.).
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
    if (!_formKey.currentState!.validate()) return;
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

      // Copy instance fields into local variables before crossing the isolate
      // boundary so that _runInIsolate receives only plain Dart objects.
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
      );

      final gameState = GameState(
        holeCards: List.unmodifiable(_holeCards),
        communityCards: List.unmodifiable(_communityCards),
        potSize: pot,
        betToCall: bet,
        numberOfOpponents: _opponents,
        heroPosition: _heroPosition,
        villainPositions: _villainPositions.isNotEmpty ? List.unmodifiable(_villainPositions) : null,
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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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

  /// Street info (title + color) derived from the number of community cards
  /// that were pre-selected when this screen was opened.
  ({String title, Color color}) get _streetInfo {
    switch (widget.preSelectedCommunityCards?.length ?? 0) {
      case 0:
        return (title: 'Flop', color: Colors.blue.shade700);
      case 3:
        return (title: 'Turn', color: Colors.orange.shade700);
      case 4:
        return (title: 'River', color: Colors.red.shade700);
      case 5:
        return (title: 'Showdown', color: Colors.purple.shade700);
      default:
        return (title: 'Select Cards', color: Colors.grey.shade700);
    }
  }

  /// Returns the title to display in the AppBar.
  String get _streetTitle =>
      widget.lockHoleCards ? _streetInfo.title : 'Select Cards';

  /// A no-op card toggle handler used when hole-card editing is locked.
  void _lockedCardToggle(PokerCard _) {
    // Hole cards are locked — do nothing.
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_streetTitle),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 2,
        bottom: widget.lockHoleCards
            ? PreferredSize(
                preferredSize: const Size.fromHeight(32),
                child: Container(
                  width: double.infinity,
                  color: _streetInfo.color,
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  child: Text(
                    _streetTitle.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _resetToNewHand,
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        tooltip: 'New Hand',
        child: const Icon(Icons.refresh),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndTop,
      body: ColoredBox(
        color: const Color(0xFFFAFAF8),
        child: Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return _buildWideLayout();
              }
              return _buildNarrowLayout();
            },
          ),
        ),
      ),
    );
  }

  // Wide (tablet/desktop) layout: card selector on left, game info on right.
  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column: card previews + selector
        Expanded(
          flex: 3,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionHeader(
                  title: 'Your Hand',
                  subtitle: '${_holeCards.length}/2 cards'),
              const SizedBox(height: 8),
              _CardPreviewRow(
                  cards: _holeCards,
                  emptySlots: kMaxHoleCards - _holeCards.length),
              const SizedBox(height: 16),
              _SectionHeader(
                title: 'Community Cards',
                subtitle: '${_communityCards.length}/5 cards',
              ),
              const SizedBox(height: 8),
              _CardPreviewRow(
                cards: _communityCards,
                emptySlots: kMaxCommunityCards - _communityCards.length,
              ),
              const SizedBox(height: 24),
              _buildCardSelectorBox(),
            ],
          ),
        ),
        // Right column: game info + calculate button
        Expanded(
          flex: 2,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
            children: [
              ..._buildGameInfoWidgets(),
              const SizedBox(height: 32),
              _buildCalculateButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  // Narrow (phone) layout: single column.
  Widget _buildNarrowLayout() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(
            title: 'Your Hand',
            subtitle: '${_holeCards.length}/2 cards'),
        const SizedBox(height: 8),
        _CardPreviewRow(
            cards: _holeCards,
            emptySlots: kMaxHoleCards - _holeCards.length),
        const SizedBox(height: 16),
        _SectionHeader(
          title: 'Community Cards',
          subtitle: '${_communityCards.length}/5 cards',
        ),
        const SizedBox(height: 8),
        _CardPreviewRow(
          cards: _communityCards,
          emptySlots: kMaxCommunityCards - _communityCards.length,
        ),
        const SizedBox(height: 24),
        _buildCardSelectorBox(),
        const SizedBox(height: 24),
        ..._buildGameInfoWidgets(),
        const SizedBox(height: 32),
        _buildCalculateButton(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCardSelectorBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          ColoredBox(
            color: const Color(0xFFF1F8E9),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1B5E20),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF1B5E20),
              indicatorWeight: 3,
              onTap: widget.lockHoleCards
                ? (index) {
                    // Prevent switching to the hole cards tab when locked.
                    if (index == 0) {
                      _tabController.animateTo(1);
                    }
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
                        color: widget.lockHoleCards ? Colors.grey.shade400 : null,
                      ),
                    ),
                    if (widget.lockHoleCards) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.lock,
                          size: 14, color: Colors.grey.shade400),
                    ],
                  ],
                ),
              ),
              const Tab(text: 'Community (0–5)'),
            ],
          ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: CardSelector(
              selectedCards:
                  _activeSection == 0 ? _holeCards : _communityCards,
              onCardToggled: _activeSection == 0 && widget.lockHoleCards
                  ? _lockedCardToggle
                  : _onCardToggled,
              disabledCards:
                  _activeSection == 0 ? _communityCards : _holeCards,
              maxSelectable:
                  _activeSection == 0 ? kMaxHoleCards : kMaxCommunityCards,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGameInfoWidgets() {
    return [
      const Text(
        'Game Info',
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1B5E20),
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
                const SizedBox(width: 12),
                Expanded(
                  child: _NumericField(
                    controller: _betController,
                    label: 'Bet to Call',
                    hint: '20',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Opponents:', style: TextStyle(fontSize: 16)),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: _opponents > 1
                        ? const Color(0xFF1B5E20)
                        : Colors.grey.shade300,
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
                Text(
                  '$_opponents',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: _opponents < 9
                        ? const Color(0xFF1B5E20)
                        : Colors.grey.shade300,
                  ),
                  onPressed:
                      _opponents < 9 ? () => setState(() => _opponents++) : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Position selector — collapsible so it doesn't clutter the UI.
            ExpansionTile(
              title: const Text(
                'Table Position (optional)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                _buildPositionSubtitle(),
                style: TextStyle(
                  fontSize: 12,
                  color: (_heroPosition != null || _villainPositions.isNotEmpty)
                      ? const Color(0xFF2E7D32)
                      : Colors.grey,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                  child: Text(
                    'Tap a seat to mark your position (green). '
                    'Tap other seats to mark opponents (red).',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                  child: PositionSelector(
                    selectedPosition: _heroPosition,
                    onPositionChanged: (pos) =>
                        setState(() => _heroPosition = pos),
                    villainPositions: _villainPositions,
                    onVillainPositionsChanged: (positions) =>
                        setState(() => _villainPositions = positions),
                    maxVillains: _opponents,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildCalculateButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        icon: _isCalculating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.calculate),
        label:
            Text(_isCalculating ? 'Calculating…' : 'Calculate Best Move'),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          padding: const EdgeInsets.symmetric(vertical: 18),
          textStyle: const TextStyle(fontSize: 17, letterSpacing: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _isCalculating ? null : _calculate,
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
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.black38, fontSize: 13),
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
    return Row(
      children: [
        ...cards.map(
          (c) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: CardWidget(card: c, selected: true),
          ),
        ),
        ...List.generate(
          emptySlots,
          (_) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Container(
              width: 48,
              height: 68,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFA5D6A7), width: 1.5),
                borderRadius: BorderRadius.circular(6),
                color: const Color(0xFFF1F8E9),
              ),
              child:
                  const Icon(Icons.add, color: Color(0xFF81C784), size: 20),
            ),
          ),
        ),
      ],
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

  /// Minimum allowed value (inclusive). Defaults to 0.
  final double minValue;

  /// When true the value must be strictly greater than [minValue].
  final bool mustBePositive;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Required';
        final n = double.tryParse(value);
        if (n == null) return 'Enter a valid number';
        if (mustBePositive && n <= minValue) {
          return 'Must be greater than ${minValue.toStringAsFixed(0)}';
        }
        if (!mustBePositive && n < minValue) {
          return 'Must be ≥ ${minValue.toStringAsFixed(0)}';
        }
        return null;
      },
    );
  }
}
