/// Color-coded decision badge widget.
library;

import 'package:flutter/material.dart';

import '../../engine/decision_engine.dart';

/// Large, color-coded badge showing FOLD / CALL / RAISE.
class DecisionBadge extends StatelessWidget {
  const DecisionBadge({super.key, required this.action});

  final PlayerAction action;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (action) {
      PlayerAction.fold => ('FOLD', const Color(0xFFD32F2F), Icons.close),
      PlayerAction.call => ('CALL', const Color(0xFFF9A825), Icons.remove),
      PlayerAction.raise => ('RAISE', const Color(0xFF388E3C), Icons.arrow_upward),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(120),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 36),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }
}
