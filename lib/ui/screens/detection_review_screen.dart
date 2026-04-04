/// Detection review screen — inspect, edit, and assign detected cards.
library;

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/card.dart';
import '../../recognition/card_detector.dart';
import '../widgets/card_selector.dart';
import '../widgets/card_widget.dart';
import 'manual_input_screen.dart';

/// Received from [CameraScreen] after running card detection.
class DetectionReviewScreen extends StatefulWidget {
  const DetectionReviewScreen({
    super.key,
    required this.imagePath,
    required this.detectionResult,
  });

  final String imagePath;
  final DetectionResult detectionResult;

  @override
  State<DetectionReviewScreen> createState() =>
      _DetectionReviewScreenState();
}

/// Per-card assignment: hole card or community card.
enum CardAssignment { hole, community }

class _DetectionReviewScreenState
    extends State<DetectionReviewScreen> {
  late final List<PokerCard> _cards;
  late final Map<PokerCard, CardAssignment> _assignments;

  bool _showCardSelector = false;

  @override
  void initState() {
    super.initState();
    _cards =
        List<PokerCard>.from(widget.detectionResult.detectedCards);
    _assignments = {
      for (final c in _cards) c: CardAssignment.hole,
    };
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  List<PokerCard> get _holeCards => _cards
      .where((c) => _assignments[c] == CardAssignment.hole)
      .toList();

  List<PokerCard> get _communityCards => _cards
      .where((c) => _assignments[c] == CardAssignment.community)
      .toList();

  void _toggleAssignment(PokerCard card) {
    setState(() {
      _assignments[card] = _assignments[card] == CardAssignment.hole
          ? CardAssignment.community
          : CardAssignment.hole;
    });
  }

  void _removeCard(PokerCard card) {
    setState(() {
      _cards.remove(card);
      _assignments.remove(card);
    });
  }

  void _addCard(PokerCard card) {
    if (!_cards.contains(card)) {
      setState(() {
        _cards.add(card);
        _assignments[card] = CardAssignment.hole;
      });
    }
    setState(() => _showCardSelector = false);
  }

  void _proceed() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ManualInputScreen(
          preSelectedHoleCards:
              _holeCards.length > 2 ? null : _holeCards,
          preSelectedCommunityCards:
              _communityCards.length > 5 ? null : _communityCards,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = _cards.length;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Review Detected Cards',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        backgroundColor: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.5),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.transparent),
          ),
        ),
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
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
        child: ListView(
        padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + kToolbarHeight + 8, 16, 16),
        children: [
          // Image preview
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(widget.imagePath),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),

          // Count header
          Text(
            '$total card${total == 1 ? '' : 's'} detected — assign them below',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap a card label to toggle Hole / Community. '
            'Swipe left to remove.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 12),

          // Card list
          if (_cards.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No cards detected.\nAdd cards manually below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ..._cards.map(
              (card) => Dismissible(
                key: ValueKey(card),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _removeCard(card),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CardWidget(card: card, selected: true),
                    title: Text(_cardLabel(card)),
                    trailing: GestureDetector(
                      onTap: () => _toggleAssignment(card),
                      child: _AssignmentChip(
                        assignment: _assignments[card]!,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Unrecognized text
          if (widget.detectionResult.unrecognizedTexts.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Unrecognized text fragments:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: widget.detectionResult.unrecognizedTexts
                  .map(
                    (t) => Chip(
                      label: Text(t),
                      backgroundColor: Colors.orange.shade100,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Add card button
          OutlinedButton.icon(
            icon: const Icon(Icons.add_card),
            label: const Text('Add Card Manually'),
            onPressed: () =>
                setState(() => _showCardSelector = !_showCardSelector),
          ),

          // Mini card selector
          if (_showCardSelector) ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2)),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: CardSelector(
                selectedCards: _cards,
                onCardToggled: (card) {
                  if (_cards.contains(card)) {
                    _removeCard(card);
                  } else {
                    _addCard(card);
                  }
                },
                maxSelectable: 7,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Continue button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.check),
              label: const Text(
                'Continue',
                style: TextStyle(fontSize: 18),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _proceed,
            ),
          ),
          const SizedBox(height: 8),

          // Retake button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Retake Photo'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(height: 24),
        ],
        ),
      ),
    );
  }

  String _cardLabel(PokerCard card) {
    const rankLabels = {
      Rank.ace: 'Ace',
      Rank.king: 'King',
      Rank.queen: 'Queen',
      Rank.jack: 'Jack',
      Rank.ten: '10',
      Rank.nine: '9',
      Rank.eight: '8',
      Rank.seven: '7',
      Rank.six: '6',
      Rank.five: '5',
      Rank.four: '4',
      Rank.three: '3',
      Rank.two: '2',
    };
    const suitLabels = {
      Suit.hearts: '♥ Hearts',
      Suit.diamonds: '♦ Diamonds',
      Suit.clubs: '♣ Clubs',
      Suit.spades: '♠ Spades',
    };
    return '${rankLabels[card.rank]} of ${suitLabels[card.suit]}';
  }
}

class _AssignmentChip extends StatelessWidget {
  const _AssignmentChip({required this.assignment});

  final CardAssignment assignment;

  @override
  Widget build(BuildContext context) {
    final isHole = assignment == CardAssignment.hole;
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isHole
            ? primary.withAlpha(30)
            : Colors.blue.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHole ? primary : Colors.blue,
        ),
      ),
      child: Text(
        isHole ? 'My Hand' : 'Community',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isHole ? primary : Colors.blue,
        ),
      ),
    );
  }
}
