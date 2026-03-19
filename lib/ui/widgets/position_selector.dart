/// Position selector widget — oval poker table with 9 tappable seats.
library;

import 'package:flutter/material.dart';

import '../../models/position.dart';

/// Displays a visual oval poker table with 9 tappable seats.
///
/// Tapping a seat selects it as the hero position (highlighted in green).
/// Tapping the already-selected seat deselects it (clears the position).
class PositionSelector extends StatelessWidget {
  const PositionSelector({
    super.key,
    required this.onPositionChanged,
    this.selectedPosition,
  });

  /// Callback invoked when the user selects or clears a position.
  final ValueChanged<TablePosition?> onPositionChanged;

  /// The currently selected position (null = none selected).
  final TablePosition? selectedPosition;

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
    final isSelected = selectedPosition == pos;

    return Positioned(
      left: cx - seatSize / 2,
      top: cy - seatSize / 2,
      child: GestureDetector(
        onTap: () {
          // Tap selected seat again → deselect
          onPositionChanged(isSelected ? null : pos);
        },
        child: Container(
          width: seatSize,
          height: seatSize,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF2E7D32)
                : Colors.grey.shade300,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1B5E20)
                  : Colors.grey.shade400,
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x552E7D32),
                      blurRadius: 6,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected)
                const Text(
                  'YOU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Text(
                positionLabel(pos),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontSize: isSelected ? 9 : 10,
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
