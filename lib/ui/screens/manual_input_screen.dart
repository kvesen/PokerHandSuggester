/// Manual input screen: card selection, pot/bet inputs, calculate button.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../engine/decision_engine.dart';
import '../../engine/equity_calculator.dart';
import '../../models/card.dart';
import '../../models/game_state.dart';
import '../../utils/constants.dart';
import '../widgets/card_selector.dart';
import '../widgets/card_widget.dart';
import 'results_screen.dart';

/// Screen where the user selects their cards and enters game details.
class ManualInputScreen extends StatefulWidget {
  const ManualInputScreen({
    super.key,
    this.preSelectedHoleCards,
    this.preSelectedCommunityCards,
  });

  /// Optional hole cards pre-populated from the camera/detection flow.
  final List<PokerCard>? preSelectedHoleCards;

  /// Optional community cards pre-populated from the camera/detection flow.
  final List<PokerCard>? preSelectedCommunityCards;

  @override
  State<ManualInputScreen> createState() => _ManualInputScreenState();
}

class _ManualInputScreenState extends State<ManualInputScreen>
    with SingleTickerProviderStateMixin {
  late final List<PokerCard> _holeCards;
  late final List<PokerCard> _communityCards;

  final _potController = TextEditingController(text: '100');
  final _betController = TextEditingController(text: '20');
  final _formKey = GlobalKey<FormState>();

  int _opponents = 2;
  bool _isCalculating = false;

  // Which section is the selector currently filling? 0 = hole, 1 = community.
  int _activeSection = 0;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _holeCards = List<PokerCard>.from(widget.preSelectedHoleCards ?? []);
    _communityCards =
        List<PokerCard>.from(widget.preSelectedCommunityCards ?? []);
    _tabController = TabController(length: 2, vsync: this);
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

  Future<void> _calculate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_holeCards.length < kMaxHoleCards) {
      _showError('Please select exactly 2 hole cards.');
      return;
    }

    setState(() => _isCalculating = true);

    try {
      final pot = double.parse(_potController.text);
      final bet = double.parse(_betController.text);

      final equityResult = await Future(() => EquityCalculator.calculate(
            holeCards: _holeCards,
            communityCards: _communityCards,
            numOpponents: _opponents,
          ));

      final decision = DecisionEngine.decide(
        equity: equityResult.equity,
        pot: pot,
        costToCall: bet,
      );

      final gameState = GameState(
        holeCards: List.unmodifiable(_holeCards),
        communityCards: List.unmodifiable(_communityCards),
        potSize: pot,
        betToCall: bet,
        numberOfOpponents: _opponents,
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Cards'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF1B5E20),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF1B5E20),
            tabs: const [
              Tab(text: 'Hole Cards (2)'),
              Tab(text: 'Community (0–5)'),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: CardSelector(
              selectedCards:
                  _activeSection == 0 ? _holeCards : _communityCards,
              onCardToggled: _onCardToggled,
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
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _NumericField(
              controller: _potController,
              label: 'Pot Size',
              hint: '100',
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
            icon: const Icon(Icons.remove_circle_outline),
            onPressed:
                _opponents > 1 ? () => setState(() => _opponents--) : null,
          ),
          Text(
            '$_opponents',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed:
                _opponents < 8 ? () => setState(() => _opponents++) : null,
          ),
        ],
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
          backgroundColor: const Color(0xFF1B5E20),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 18),
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
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Text(subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 14)),
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
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
                borderRadius: BorderRadius.circular(6),
                color: Colors.grey.shade50,
              ),
              child:
                  const Icon(Icons.add, color: Colors.grey, size: 20),
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
  });

  final TextEditingController controller;
  final String label;
  final String hint;

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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Required';
        final n = double.tryParse(value);
        if (n == null || n < 0) return 'Enter a valid number';
        return null;
      },
    );
  }
}
