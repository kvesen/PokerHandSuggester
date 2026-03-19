/// Color-coded decision badge widget with elastic bounce-in animation.
library;

import 'package:flutter/material.dart';

import '../../engine/decision_engine.dart';

/// Large, color-coded badge showing FOLD / CALL / RAISE with a bounce-in
/// animation when it first appears.
class DecisionBadge extends StatefulWidget {
  const DecisionBadge({super.key, required this.action});

  final PlayerAction action;

  @override
  State<DecisionBadge> createState() => _DecisionBadgeState();
}

class _DecisionBadgeState extends State<DecisionBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (widget.action) {
      PlayerAction.fold => ('FOLD', const Color(0xFFD32F2F), Icons.close),
      PlayerAction.call => ('CALL', const Color(0xFFF9A825), Icons.remove),
      PlayerAction.raise =>
        ('RAISE', const Color(0xFF388E3C), Icons.arrow_upward),
    };

    return ScaleTransition(
      scale: _scale,
      child: Container(
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
      ),
    );
  }
}
