/// Poker table visualization widget.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/card.dart';
import '../../models/position.dart';
import 'card_widget.dart';

/// Renders an oval poker table with hole cards, community cards, pot display,
/// and opponent seat indicators.
class PokerTableWidget extends StatelessWidget {
  const PokerTableWidget({
    super.key,
    required this.holeCards,
    required this.communityCards,
    required this.numberOfOpponents,
    required this.potSize,
    this.heroPosition,
  });

  final List<PokerCard> holeCards;
  final List<PokerCard> communityCards;
  final int numberOfOpponents;
  final double potSize;

  /// Optional hero position — when provided, shows the position label on the
  /// player's seat.
  final TablePosition? heroPosition;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AspectRatio(
      aspectRatio: 3 / 2,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Stack(
            children: [
              CustomPaint(
                size: Size(w, h),
                painter: _TablePainter(isDark: isDark),
              ),
              ..._buildOpponentSeats(w, h, isDark),
              _buildCommunityCards(w, h, isDark),
              _buildPotDisplay(w, h, isDark),
              _buildPlayerSeat(w, h, isDark),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildOpponentSeats(double w, double h, bool isDark) {
    if (numberOfOpponents <= 0) return [];
    final seats = <Widget>[];
    const startAngle = 200.0 * math.pi / 180.0;
    const endAngle = 340.0 * math.pi / 180.0;
    const span = endAngle - startAngle;
    final count = numberOfOpponents.clamp(1, 9);

    final rx = w * 0.38;
    final ry = h * 0.33;
    final cx = w / 2;
    final cy = h / 2;

    for (var i = 0; i < count; i++) {
      final t = count == 1 ? 0.5 : i / (count - 1);
      final angle = startAngle + t * span;
      final sx = cx + rx * math.cos(angle);
      final sy = cy + ry * math.sin(angle);

      seats.add(
        Positioned(
          left: sx - 18,
          top: sy - 18,
          child: _OpponentSeat(number: i + 1, isDark: isDark),
        ),
      );
    }
    return seats;
  }

  Widget _buildCommunityCards(double w, double h, bool isDark) {
    const cardW = 34.0;
    const cardH = 48.0;
    const spacing = 4.0;
    const double totalWidth = cardW * 5 + spacing * 4;
    final left = (w - totalWidth) / 2;
    final top = h * 0.32 - cardH / 2;

    return Positioned(
      left: left,
      top: top,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (i) {
          if (i < communityCards.length) {
            return Padding(
              padding: const EdgeInsets.only(right: spacing),
              child: CardWidget(card: communityCards[i], size: CardSize.small),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(right: spacing),
            child: _EmptyCardSlot(isDark: isDark),
          );
        }),
      ),
    );
  }

  Widget _buildPotDisplay(double w, double h, bool isDark) {
    return Positioned(
      left: 0,
      right: 0,
      top: h * 0.55,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.toll_rounded,
                    color: Color(0xFFFFC107),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    potSize > 0 ? potSize.toStringAsFixed(0) : '0',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerSeat(double w, double h, bool isDark) {
    const cardSpacing = 4.0;
    const cardW = 34.0;
    const double totalCardsWidth = cardW * 2 + cardSpacing;
    final left = (w - totalCardsWidth) / 2;

    return Positioned(
      left: left,
      bottom: h * 0.04,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: holeCards.isEmpty
                ? [
                    _EmptyCardSlot(isDark: isDark),
                    const SizedBox(width: cardSpacing),
                    _EmptyCardSlot(isDark: isDark),
                  ]
                : holeCards
                      .map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(right: cardSpacing),
                          child: CardWidget(card: c, size: CardSize.small),
                        ),
                      )
                      .toList(),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Text(
              heroPosition != null
                  ? 'You · ${positionLabel(heroPosition!)}'
                  : 'You',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _OpponentSeat extends StatelessWidget {
  const _OpponentSeat({required this.number, required this.isDark});

  final int number;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              'OPP\n$number',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCardSlot extends StatelessWidget {
  const _EmptyCardSlot({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 48,
      decoration: BoxDecoration(
        color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Table CustomPainter
// ---------------------------------------------------------------------------

class _TablePainter extends CustomPainter {
  final bool isDark;
  _TablePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final tableRect = Rect.fromCenter(
      center: center,
      width: w * 0.92,
      height: h * 0.86,
    );

    // Glowing Outer ring
    final outerGlowPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: isDark ? 0.3 : 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.04
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(tableRect, outerGlowPaint);

    // Deep Felt fill
    final feltPaint = Paint()
      ..shader = RadialGradient(
        colors: isDark
            ? [const Color(0xFF1B3B2B), const Color(0xFF0D1C15)]
            : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
        center: Alignment.center,
        radius: 0.8,
      ).createShader(tableRect)
      ..style = PaintingStyle.fill;
    canvas.drawOval(tableRect, feltPaint);

    // Hard Edge rail
    final borderPaint = Paint()
      ..color = isDark ? const Color(0xFF234B36) : const Color(0xFFA5D6A7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025;
    canvas.drawOval(tableRect, borderPaint);

    // Subtle inner felt ring
    final innerRect = Rect.fromCenter(
      center: center,
      width: w * 0.82,
      height: h * 0.76,
    );
    final innerPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(innerRect, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _TablePainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
