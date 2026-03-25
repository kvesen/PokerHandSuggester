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
    // Deep, rich colors for suits instead of basic red/black
    final color = isRed ? const Color(0xFFE53935) : const Color(0xFF1E1E1E);
    
    final suitSymbol = kSuitSymbols[card.suit.name] ?? '';
    final rankLabel = kRankLabels[card.rank.name] ?? '';

    final double cardWidth = size.width;
    final double cardHeight = size.height;
    final double fontSize = size.fontSize;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          // Subtle gradient to mimic the sheen on physical cards
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: selected 
                ? [const Color(0xFFFFFDE7), const Color(0xFFFFF9C4)] // Soft golden sheen
                : [const Color(0xFFFFFFFF), const Color(0xFFF5F5F5)], // Bright white to off-white
          ),
          borderRadius: BorderRadius.circular(size.borderRadius),
          // Glow effect when selected, soft drop shadow otherwise
          boxShadow: [
            if (selected)
              BoxShadow(
                color: const Color(0xFFFFC107).withOpacity(isDark ? 0.4 : 0.6),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 2),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
          ],
          border: Border.all(
            color: selected 
                ? const Color(0xFFFFC107) 
                : const Color(0xFFE0E0E0).withOpacity(isDark ? 0.2 : 1.0),
            width: selected ? 2.0 : 1.0,
          ),
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
                opacity: 0.15, // Large faint symbol in the background
                child: Text(
                  suitSymbol,
                  style: TextStyle(
                    fontSize: fontSize * 3.5,
                    color: color,
                    height: 1,
                  ),
                ),
              ),
            ),
            // Center primary suit
            Center(
              child: Text(
                suitSymbol,
                style: TextStyle(
                  fontSize: fontSize * 1.8,
                  color: color,
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          rank,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900, // Extra bold for modern look
            color: color,
            height: 1.0,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          suit,
          style: TextStyle(
            fontSize: fontSize * 0.85, 
            color: color, 
            height: 1.0
          ),
        ),
      ],
    );
  }
}

/// Sizing presets for [CardWidget].
enum CardSize {
  small(width: 34, height: 48, fontSize: 10, padding: 3, borderRadius: 6),
  medium(width: 52, height: 74, fontSize: 14, padding: 4, borderRadius: 8),
  large(width: 72, height: 102, fontSize: 18, padding: 6, borderRadius: 10);

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
