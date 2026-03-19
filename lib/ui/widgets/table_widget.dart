/// Poker table visualization widget.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/card.dart';
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
  });

  final List<PokerCard> holeCards;
  final List<PokerCard> communityCards;
  final int numberOfOpponents;
  final double potSize;

  @override
  Widget build(BuildContext context) {
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
                painter: _TablePainter(),
              ),
              ..._buildOpponentSeats(w, h),
              _buildCommunityCards(w, h),
              _buildPotDisplay(w, h),
              _buildPlayerSeat(w, h),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildOpponentSeats(double w, double h) {
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
          child: _OpponentSeat(number: i + 1),
        ),
      );
    }
    return seats;
  }

  Widget _buildCommunityCards(double w, double h) {
    const cardW = 32.0;
    const cardH = 46.0;
    const spacing = 4.0;
    final totalWidth = cardW * 5 + spacing * 4;
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
            child: Container(
              width: cardW,
              height: cardH,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white.withAlpha(60), width: 1),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPotDisplay(double w, double h) {
    return Positioned(
      left: 0,
      right: 0,
      top: h * 0.52,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(100),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.toll, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
              Text(
                potSize > 0 ? potSize.toStringAsFixed(0) : '0',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerSeat(double w, double h) {
    const cardSpacing = 4.0;
    const cardW = 32.0;
    final totalCardsWidth = cardW * 2 + cardSpacing;
    final left = (w - totalCardsWidth) / 2 - 8;

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
                    _EmptyCardSlot(),
                    const SizedBox(width: cardSpacing),
                    _EmptyCardSlot(),
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
          const SizedBox(height: 2),
          const Text(
            'You',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
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
  const _OpponentSeat({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(40),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withAlpha(120), width: 1.5),
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _EmptyCardSlot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withAlpha(60), width: 1),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Table CustomPainter
// ---------------------------------------------------------------------------

class _TablePainter extends CustomPainter {
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

    // Border / rail
    final borderPaint = Paint()
      ..color = const Color(0xFF3E1F00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03;
    canvas.drawOval(tableRect, borderPaint);

    // Felt fill
    final feltPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFF2E7D32), Color(0xFF1B5E20)],
        center: Alignment.center,
        radius: 0.8,
      ).createShader(tableRect)
      ..style = PaintingStyle.fill;
    canvas.drawOval(tableRect, feltPaint);

    // Inner highlight ring
    final innerRect = Rect.fromCenter(
      center: center,
      width: w * 0.84,
      height: h * 0.78,
    );
    final innerPaint = Paint()
      ..color = const Color(0xFF388E3C).withAlpha(80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(innerRect, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
