/// Interactive card picker — fixed 13-column × 4-row grid of all 52 cards.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/card.dart';
import 'card_widget.dart';

/// A grid showing all 52 cards in a fixed 13-column (rank) × 4-row (suit)
/// layout. Columns run 2 → A (small cards on the left, big on the right);
/// rows run ♠ → ♥ → ♦ → ♣.
///
/// Tapping a card toggles its selected state. [selectedCards] is the external
/// selection state; [onCardToggled] is called whenever the user taps a card.
///
/// A text-input row above the grid lets the user type shorthand notation
/// (e.g. `Ah`, `Kd`, `10s`, `5c`) to select cards without tapping.
///
/// [disabledCards] – cards that cannot be selected (already used elsewhere).
/// [maxSelectable] – maximum cards that can be selected at once.
class CardSelector extends StatefulWidget {
  const CardSelector({
    super.key,
    required this.selectedCards,
    required this.onCardToggled,
    this.disabledCards = const [],
    this.maxSelectable = 52,
  });

  final List<PokerCard> selectedCards;
  final void Function(PokerCard card) onCardToggled;
  final List<PokerCard> disabledCards;
  final int maxSelectable;

  @override
  State<CardSelector> createState() => _CardSelectorState();
}

class _CardSelectorState extends State<CardSelector> {
  final _textController = TextEditingController();
  String? _errorText;

  // Fixed rank order: 2 (left) → A (right).
  static const _rankOrder = [
    Rank.two,
    Rank.three,
    Rank.four,
    Rank.five,
    Rank.six,
    Rank.seven,
    Rank.eight,
    Rank.nine,
    Rank.ten,
    Rank.jack,
    Rank.queen,
    Rank.king,
    Rank.ace,
  ];

  // Fixed suit order: ♠ → ♥ → ♦ → ♣ (top to bottom).
  static const _suitOrder = [
    Suit.spades,
    Suit.hearts,
    Suit.diamonds,
    Suit.clubs,
  ];

  /// Builds the 52-card deck in row-major order so that grid index [i] maps to
  /// `suit = _suitOrder[i ~/ 13]` (row) and `rank = _rankOrder[i % 13]` (column).
  List<PokerCard> _buildDeck() => [
        for (final suit in _suitOrder)
          for (final rank in _rankOrder) PokerCard(suit: suit, rank: rank),
      ];

  // Matches shorthand card notation, e.g. "Ah", "10s", "kD".
  static final _cardNotationRegex =
      RegExp(r'^(10|[2-9TtJjQqKkAa])([HhDdCcSs])$');

  /// Parses shorthand notation such as `Ah`, `Kd`, `10s`, `5c` into a
  /// [PokerCard]. Returns `null` if the input is not a valid card string.
  PokerCard? _parseInput(String input) {
    final s = input.trim();
    if (s.isEmpty) return null;

    final match = _cardNotationRegex.firstMatch(s);
    if (match == null) return null;

    final rankStr = match.group(1)!.toUpperCase();
    final suitStr = match.group(2)!.toLowerCase();

    final rank = switch (rankStr) {
      '2' => Rank.two,
      '3' => Rank.three,
      '4' => Rank.four,
      '5' => Rank.five,
      '6' => Rank.six,
      '7' => Rank.seven,
      '8' => Rank.eight,
      '9' => Rank.nine,
      '10' || 'T' => Rank.ten,
      'J' => Rank.jack,
      'Q' => Rank.queen,
      'K' => Rank.king,
      'A' => Rank.ace,
      _ => null,
    };

    final suit = switch (suitStr) {
      'h' => Suit.hearts,
      'd' => Suit.diamonds,
      'c' => Suit.clubs,
      's' => Suit.spades,
      _ => null,
    };

    if (rank == null || suit == null) return null;
    return PokerCard(suit: suit, rank: rank);
  }

  void _submit() {
    final tokens = _textController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (tokens.isEmpty) return;

    final List<String> invalidTokens = [];
    final List<String> alreadyUsedTokens = [];
    final List<String> alreadySelectedTokens = [];
    final List<String> duplicateTokens = [];
    final List<String> maxReachedTokens = [];

    // Cards successfully parsed and queued to add (ordered, deduped).
    final List<PokerCard> toAdd = [];
    final Set<PokerCard> seen = {};
    int currentCount = widget.selectedCards.length;

    for (final token in tokens) {
      final card = _parseInput(token);
      if (card == null) {
        invalidTokens.add(token);
        continue;
      }
      if (widget.disabledCards.contains(card)) {
        alreadyUsedTokens.add(token);
        continue;
      }
      if (widget.selectedCards.contains(card)) {
        alreadySelectedTokens.add(token);
        continue;
      }
      if (seen.contains(card)) {
        duplicateTokens.add(token);
        continue;
      }
      if (currentCount >= widget.maxSelectable) {
        maxReachedTokens.add(token);
        continue;
      }
      seen.add(card);
      toAdd.add(card);
      currentCount++;
    }

    for (final card in toAdd) {
      widget.onCardToggled(card);
    }

    final List<String> errorParts = [];
    if (invalidTokens.isNotEmpty) {
      errorParts.add('Invalid: ${invalidTokens.join(', ')}');
    }
    if (alreadyUsedTokens.isNotEmpty) {
      errorParts.add('Already used: ${alreadyUsedTokens.join(', ')}');
    }
    if (alreadySelectedTokens.isNotEmpty) {
      errorParts.add('Already selected: ${alreadySelectedTokens.join(', ')}');
    }
    if (duplicateTokens.isNotEmpty) {
      errorParts.add('Duplicate: ${duplicateTokens.join(', ')}');
    }
    if (maxReachedTokens.isNotEmpty) {
      errorParts.add('Maximum reached: ${maxReachedTokens.join(', ')}');
    }

    if (errorParts.isEmpty) {
      setState(() => _errorText = null);
      _textController.clear();
    } else {
      setState(() => _errorText = errorParts.join(' — '));
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deck = _buildDeck();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Text-input row ──────────────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Add cards by shorthand',
                  hintText: 'e.g. Ah, Kd, 10s',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 13,
                  ),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.redAccent),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.redAccent),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.04),
                  errorText: _errorText,
                  errorStyle: const TextStyle(fontSize: 11),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 13,
                ),
                onChanged: (_) {
                  if (_errorText != null) setState(() => _errorText = null);
                },
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: IconButton(
                onPressed: _submit,
                icon: Icon(
                  Icons.add_circle_outline,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                tooltip: 'Add card',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // ── Card grid: 13 columns (rank 2→A) × 4 rows (suit ♠♥♦♣) ─────────
        Semantics(
          label: 'Card selection grid',
          child: GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 13,
            childAspectRatio: 34 / 48, // matches CardSize.tiny (34×48)
            crossAxisSpacing: 2.0,
            mainAxisSpacing: 2.0,
          ),
          itemCount: deck.length,
          itemBuilder: (context, index) {
            final card = deck[index];
            final isSelected = widget.selectedCards.contains(card);
            final isDisabled = widget.disabledCards.contains(card) ||
                (!isSelected && widget.selectedCards.length >= widget.maxSelectable);

            // Stagger the entry animation by varying duration per card index,
            // so cards animate in sequentially rather than all at once.
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: isDisabled ? 0.2 : 1.0),
              duration:
                  Duration(milliseconds: 250 + (index * 8).clamp(0, 200)),
              curve: Curves.easeOutCubic,
              builder: (context, opacity, child) =>
                  Opacity(opacity: opacity, child: child),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                scale: isSelected ? 1.08 : (isDisabled ? 0.95 : 1.0),
                child: CardWidget(
                  card: card,
                  selected: isSelected,
                  size: CardSize.tiny,
                  onTap: isDisabled ? null : () {
                    HapticFeedback.selectionClick();
                    widget.onCardToggled(card);
                  },
                ),
              ),
            );
          },
          ),
        ),
      ],
    );
  }
}
