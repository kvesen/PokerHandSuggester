/// Color-coded decision badge widget with elastic bounce-in animation.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      duration: const Duration(milliseconds: 650),
    );
    _scale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    HapticFeedback.heavyImpact();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Vibrant neon gradients
    final (label, gradientColors, shadowColor, icon) = switch (widget.action) {
      PlayerAction.fold => (
        'FOLD',
        [const Color(0xFFF43F5E), const Color(0xFFBE123C)],
        const Color(0xFFE11D48),
        Icons.close_rounded,
      ),
      PlayerAction.call => (
        'CALL',
        [const Color(0xFFFBBF24), const Color(0xFFD97706)],
        const Color(0xFFF59E0B),
        Icons.drag_handle_rounded,
      ),
      PlayerAction.raise => (
        'RAISE',
        [const Color(0xFF34D399), const Color(0xFF059669)],
        const Color(0xFF10B981),
        Icons.arrow_upward_rounded,
      ),
    };

    return Semantics(
      label: 'Decision: $label',
      liveRegion: true,
      excludeSemantics: true,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 54, vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(24),
            // Inner glowing border effect
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              // Deep colored neon drop-shadow
              BoxShadow(
                color: shadowColor.withValues(alpha: 0.6),
                blurRadius: 24,
                spreadRadius: 4,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 40),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
