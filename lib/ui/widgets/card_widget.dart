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
    final isRed = card.suit == Suit.hearts || card.suit == Suit.diamonds;
    final color = isRed ? const Color(0xFFEF4444) : const Color(0xFF1C1C1E);
    final suitSymbol = kSuitSymbols[card.suit.name] ?? '';
    final rankLabel = kRankLabels[card.rank.name] ?? '';

    final double cardWidth = size.width;
    final double cardHeight = size.height;
    final double fontSize = size.fontSize;

    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: '$rankLabel of ${card.suit.name}${selected ? ", selected" : ""}',
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: selected
                ? [Colors.white, const Color(0xFFFFF9C4)] // Soft warm glow
                : [Colors.white, const Color(0xFFE2E8F0)], // Cool crisp white
          ),
          borderRadius: BorderRadius.circular(size.borderRadius),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            width: selected ? 2.5 : 1.5,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 6,
                offset: const Offset(1, 3),
              ),
          ],
        ),
        child: Stack(
          children: [
            // Top-left rank + suit
            Positioned(
              top: size.padding,
              left: size.padding,
              child: _RankSuit(
                rank: rankLabel,
                suit: suitSymbol,
                color: color,
                fontSize: fontSize,
              ),
            ),
            // Center suit watermark
            Center(
              child: Opacity(
                opacity: 0.10,
                child: Text(
                  suitSymbol,
                  style: TextStyle(
                    fontSize: fontSize * 1.2,
                    color: color,
                    height: 1.0,
                  ),
                ),
              ),
            ),
            // Center primary suit
            Center(
              child: Text(
                suitSymbol,
                style: TextStyle(
                  fontSize: fontSize * 0.9,
                  color: color.withValues(alpha: 0.9),
                ),
              ),
            ),
            // Bottom-right rank + suit (rotated)
            Positioned(
              bottom: size.padding,
              right: size.padding,
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
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          rank,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1.0,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

/// Sizing presets for [CardWidget].
enum CardSize {
  // Added padding and border radius variables internally
  tiny(width: 34, height: 48, fontSize: 8, padding: 2, borderRadius: 6),
  small(width: 34, height: 48, fontSize: 10, padding: 3, borderRadius: 6),
  medium(width: 52, height: 74, fontSize: 14, padding: 4, borderRadius: 8),
  large(width: 72, height: 100, fontSize: 20, padding: 6, borderRadius: 10);

  const CardSize({
    required this.width,
    required this.height,
    required this.fontSize,
    required this.padding,
    required this.borderRadius,
  });

  final double width;
  final double height;
  final double fontSize;
  final double padding;
  final double borderRadius;
}
