/// Position selector widget — oval poker table with 9 tappable seats.
library;

import 'package:flutter/material.dart';

import '../../models/position.dart';

/// Displays a visual oval poker table with 9 tappable seats.
///
/// Tapping a seat selects it as the hero position (highlighted in green).
/// Tapping the already-selected seat deselects it (clears the position).
///
/// When [onVillainPositionsChanged] is provided, additional seats can be
/// marked as villain seats (shown in red/orange with an "OPP" label).
/// At most [maxVillains] villain seats can be selected at once.
/// A seat cannot be both hero and villain simultaneously.
class PositionSelector extends StatelessWidget {
  const PositionSelector({
    super.key,
    required this.onPositionChanged,
    this.selectedPosition,
    this.villainPositions = const [],
    this.onVillainPositionsChanged,
    this.maxVillains = 1,
  });

  /// Callback invoked when the user selects or clears the hero position.
  final ValueChanged<TablePosition?> onPositionChanged;

  /// The currently selected hero position (null = none selected).
  final TablePosition? selectedPosition;

  /// The currently selected villain seats.
  final List<TablePosition> villainPositions;

  /// Callback invoked when villain seats change.
  /// If null, villain selection is disabled.
  final ValueChanged<List<TablePosition>>? onVillainPositionsChanged;

  /// Maximum number of villain seats that can be selected.
  final int maxVillains;

  // Seats arranged clockwise from the Button (standard poker table order:
  // BTN → SB → BB → UTG → UTG+1 → MP → MP+1 → HJ → CO → back to BTN).
  // Fractional coordinates: (x from left, y from top).
  static const List<(TablePosition, double, double)> _seats = [
    (TablePosition.button,     0.08, 0.50),  // left-middle (dealer)
    (TablePosition.smallBlind, 0.32, 0.04),  // upper-left
    (TablePosition.bigBlind,   0.50, 0.00),  // top-center
    (TablePosition.utg,        0.68, 0.04),  // upper-right
    (TablePosition.utg1,       0.88, 0.22),  // right-upper
    (TablePosition.mp,         0.92, 0.50),  // right-middle
    (TablePosition.mp1,        0.80, 0.78),  // lower-right
    (TablePosition.hijack,     0.56, 0.92),  // bottom-center
    (TablePosition.cutoff,     0.20, 0.78),  // lower-left
  ];

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2.0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Stack(
            children: [
              // Table background
              Positioned.fill(
                child: CustomPaint(painter: _TableOutlinePainter()),
              ),
              // Seats
              for (final (pos, fx, fy) in _seats)
                _buildSeat(pos, fx * w, fy * h),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSeat(TablePosition pos, double cx, double cy) {
    const seatSize = 46.0;
    final isHero = selectedPosition == pos;
    final isVillain = villainPositions.contains(pos);

    return Positioned(
      left: cx - seatSize / 2,
      top: cy - seatSize / 2,
      child: GestureDetector(
        onTap: () {
          if (isHero) {
            // Tap selected hero seat → deselect hero
            onPositionChanged(null);
          } else if (isVillain) {
            // Tap villain seat → remove it from villain list
            if (onVillainPositionsChanged != null) {
              final updated = List<TablePosition>.from(villainPositions)
                ..remove(pos);
              onVillainPositionsChanged!(updated);
            }
          } else {
            // Empty seat: set as hero first, then fill villain slots.
            if (selectedPosition == null) {
              onPositionChanged(pos);
            } else if (onVillainPositionsChanged != null &&
                villainPositions.length < maxVillains) {
              final updated = List<TablePosition>.from(villainPositions)
                ..add(pos);
              onVillainPositionsChanged!(updated);
            } else if (onVillainPositionsChanged == null) {
              onPositionChanged(pos);
            }
          }
        },
        child: Container(
          width: seatSize,
          height: seatSize,
          decoration: BoxDecoration(
            color: isHero
                ? const Color(0xFF2E7D32)
                : isVillain
                    ? const Color(0xFFEF5350)
                    : Colors.grey.shade300,
            shape: BoxShape.circle,
            border: Border.all(
              color: isHero
                  ? const Color(0xFF1B5E20)
                  : isVillain
                      ? const Color(0xFFB71C1C)
                      : Colors.grey.shade400,
              width: (isHero || isVillain) ? 2.5 : 1.5,
            ),
            boxShadow: isHero
                ? const [
                    BoxShadow(
                      color: Color(0x552E7D32),
                      blurRadius: 6,
                      spreadRadius: 1,
                    )
                  ]
                : isVillain
                    ? const [
                        BoxShadow(
                          color: Color(0x55EF5350),
                          blurRadius: 6,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isHero)
                const Text(
                  'YOU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else if (isVillain)
                const Text(
                  'OPP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Text(
                positionLabel(pos),
                style: TextStyle(
                  color: (isHero || isVillain)
                      ? Colors.white
                      : Colors.grey.shade700,
                  fontSize: (isHero || isVillain) ? 9 : 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painter for the oval table outline
// ---------------------------------------------------------------------------

class _TableOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final rect = Rect.fromLTWH(w * 0.08, h * 0.10, w * 0.84, h * 0.80);

    // Felt fill
    final feltPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFF388E3C), Color(0xFF1B5E20)],
        center: Alignment.center,
        radius: 0.8,
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawOval(rect, feltPaint);

    // Rail border
    final borderPaint = Paint()
      ..color = const Color(0xFF3E1F00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025;
    canvas.drawOval(rect, borderPaint);

    // Inner highlight ring
    final innerRect = Rect.fromLTWH(
        w * 0.12, h * 0.16, w * 0.76, h * 0.68);
    final innerPaint = Paint()
      ..color = const Color(0xFF66BB6A).withAlpha(80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(innerRect, innerPaint);

    // "Table Position" label in center
    final textSpan = TextSpan(
      text: 'Table\nPosition',
      style: TextStyle(
        color: Colors.white.withAlpha(160),
        fontSize: w * 0.042,
        fontWeight: FontWeight.bold,
        height: 1.3,
      ),
    );
    final tp = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(w / 2 - tp.width / 2, h / 2 - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
