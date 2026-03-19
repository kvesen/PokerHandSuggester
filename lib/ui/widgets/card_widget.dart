/// Visual playing card widget.
library;

import 'package:flutter/material.dart';

import '../../models/card.dart';
import '../../utils/constants.dart';

/// Displays a single [PokerCard] as a visual playing card.
///
/// [selected] – when true, a highlight border is shown.
/// [onTap]    – optional tap callback.
class CardWidget extends StatelessWidget {
  const CardWidget({
    super.key,
    required this.card,
    this.selected = false,
    this.onTap,
    this.size = CardSize.medium,
  });

  final PokerCard card;
  final bool selected;
  final VoidCallback? onTap;
  final CardSize size;

  @override
  Widget build(BuildContext context) {
    final isRed =
        card.suit == Suit.hearts || card.suit == Suit.diamonds;
    final color = isRed ? const Color(0xFFD32F2F) : const Color(0xFF212121);
    final suitSymbol = kSuitSymbols[card.suit.name] ?? '';
    final rankLabel = kRankLabels[card.rank.name] ?? '';

    final double cardWidth = size.width;
    final double cardHeight = size.height;
    final double fontSize = size.fontSize;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF9C4) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? const Color(0xFFF9A825) : const Color(0xFFBDBDBD),
            width: selected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(selected ? 60 : 30),
              blurRadius: selected ? 6 : 3,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Top-left rank + suit
            Positioned(
              top: 2,
              left: 4,
              child: _RankSuit(
                rank: rankLabel,
                suit: suitSymbol,
                color: color,
                fontSize: fontSize,
              ),
            ),
            // Center suit
            Center(
              child: Text(
                suitSymbol,
                style: TextStyle(
                  fontSize: fontSize * 1.5,
                  color: color,
                ),
              ),
            ),
            // Bottom-right rank + suit (rotated)
            Positioned(
              bottom: 2,
              right: 4,
              child: RotatedBox(
                quarterTurns: 2,
                child: _RankSuit(
                  rank: rankLabel,
                  suit: suitSymbol,
                  color: color,
                  fontSize: fontSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankSuit extends StatelessWidget {
  const _RankSuit({
    required this.rank,
    required this.suit,
    required this.color,
    required this.fontSize,
  });

  final String rank;
  final String suit;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          rank,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: color,
            height: 1.1,
          ),
        ),
        Text(
          suit,
          style: TextStyle(fontSize: fontSize * 0.8, color: color, height: 1),
        ),
      ],
    );
  }
}

/// Sizing presets for [CardWidget].
enum CardSize {
  small(width: 32, height: 46, fontSize: 9),
  medium(width: 48, height: 68, fontSize: 13),
  large(width: 64, height: 90, fontSize: 17);

  const CardSize({
    required this.width,
    required this.height,
    required this.fontSize,
  });

  final double width;
  final double height;
  final double fontSize;
}
