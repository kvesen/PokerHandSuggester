/// Position selector widget — oval poker table with 9 tappable seats.
library;

import 'dart:ui';
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

  final ValueChanged<TablePosition?> onPositionChanged;
  final TablePosition? selectedPosition;
  final List<TablePosition> villainPositions;
  final ValueChanged<List<TablePosition>>? onVillainPositionsChanged;
  final int maxVillains;

  // Seats arranged clockwise from the Button
  static const List<(TablePosition, double, double)> _seats = [
    (TablePosition.button,     0.08, 0.50),
    (TablePosition.smallBlind, 0.32, 0.04),
    (TablePosition.bigBlind,   0.50, 0.00),
    (TablePosition.utg,        0.68, 0.04),
    (TablePosition.utg1,       0.88, 0.22),
    (TablePosition.mp,         0.92, 0.50),
    (TablePosition.mp1,        0.80, 0.78),
    (TablePosition.hijack,     0.56, 0.92),
    (TablePosition.cutoff,     0.20, 0.78),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AspectRatio(
      aspectRatio: 2.0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Stack(
            children: [
              // Premium Table Background
              Positioned.fill(
                child: CustomPaint(painter: _TableOutlinePainter(isDark: isDark)),
              ),
              // Interactive Seats
              for (final (pos, fx, fy) in _seats)
                _buildSeat(context, pos, fx * w, fy * h, isDark),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSeat(BuildContext context, TablePosition pos, double cx, double cy, bool isDark) {
    const seatSize = 48.0;
    final isHero = selectedPosition == pos;
    final isVillain = villainPositions.contains(pos);
    final theme = Theme.of(context);

    // Dynamic colors based on state
    final Color borderColor;
    final Color shadowColor;
    final Color textColor;
    
    if (isHero) {
      borderColor = const Color(0xFF10B981); // Emerald glow
      shadowColor = const Color(0xFF10B981);
      textColor = Colors.white;
    } else if (isVillain) {
      borderColor = const Color(0xFFEF4444); // Ruby glow
      shadowColor = const Color(0xFFEF4444);
      textColor = Colors.white;
    } else {
      borderColor = isDark ? Colors.white24 : Colors.black26;
      shadowColor = Colors.transparent;
      textColor = isDark ? Colors.white60 : Colors.black54;
    }

    return Positioned(
      left: cx - seatSize / 2,
      top: cy - seatSize / 2,
      child: GestureDetector(
        onTap: () {
          if (isHero) {
            onPositionChanged(null);
          } else if (isVillain) {
            if (onVillainPositionsChanged != null) {
              final updated = List<TablePosition>.from(villainPositions)..remove(pos);
              onVillainPositionsChanged!(updated);
            }
          } else {
            if (selectedPosition == null) {
              onPositionChanged(pos);
            } else if (onVillainPositionsChanged != null && villainPositions.length < maxVillains) {
              final updated = List<TablePosition>.from(villainPositions)..add(pos);
              onVillainPositionsChanged!(updated);
            } else if (onVillainPositionsChanged == null) {
              onPositionChanged(pos);
            }
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          width: seatSize,
          height: seatSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Glassmorphism base
            color: isDark ? Colors.black54 : Colors.white.withOpacity(0.8),
            border: Border.all(
              color: borderColor,
              width: (isHero || isVillain) ? 2.5 : 1.5,
            ),
            boxShadow: [
              if (isHero || isVillain)
                BoxShadow(
                  color: shadowColor.withOpacity(isDark ? 0.5 : 0.6),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              if (!isHero && !isVillain)
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isHero)
                    Text(
                      'YOU',
                      style: TextStyle(
                        color: borderColor,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    )
                  else if (isVillain)
                    Text(
                      'OPP',
                      style: TextStyle(
                        color: borderColor,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  Text(
                    positionLabel(pos),
                    style: TextStyle(
                      color: textColor,
                      fontSize: (isHero || isVillain) ? 9 : 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
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
  final bool isDark;
  _TableOutlinePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final rect = Rect.fromLTWH(w * 0.08, h * 0.10, w * 0.84, h * 0.80);

    // Neon glowing rail border
    final outerGlowPaint = Paint()
      ..color = const Color(0xFF10B981).withOpacity(isDark ? 0.3 : 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(rect, outerGlowPaint);

    // Rich dark felt fill
    final feltPaint = Paint()
      ..shader = RadialGradient(
        colors: isDark 
            ? [const Color(0xFF1B3B2B), const Color(0xFF0D1C15)] 
            : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
        center: Alignment.center,
        radius: 0.8,
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawOval(rect, feltPaint);

    // Solid rail edge
    final borderPaint = Paint()
      ..color = isDark ? const Color(0xFF234B36) : const Color(0xFFA5D6A7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.02;
    canvas.drawOval(rect, borderPaint);

    // Subtle inner felt ring
    final innerRect = Rect.fromLTWH(
        w * 0.12, h * 0.16, w * 0.76, h * 0.68);
    final innerPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(innerRect, innerPaint);

    // Center watermark label
    final textSpan = TextSpan(
      text: 'TABLE\nPOSITION',
      style: TextStyle(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
        fontSize: w * 0.040,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.0,
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
  bool shouldRepaint(covariant _TableOutlinePainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
