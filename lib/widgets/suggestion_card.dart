/// Reusable suggestion / decision result card.
library;

import 'package:flutter/material.dart';

import '../engine/decision_engine.dart';

/// Displays the recommended action (Fold / Call / Raise) as a prominent card.
class SuggestionCard extends StatelessWidget {
  const SuggestionCard({super.key, required this.decision});

  final Decision decision;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, bgColor, icon) = switch (decision.action) {
      PlayerAction.fold => (
        'FOLD',
        const Color(0xFFF43F5E),
        Icons.close_rounded,
      ),
      PlayerAction.call => (
        'CALL',
        const Color(0xFFFBBF24),
        Icons.drag_handle_rounded,
      ),
      PlayerAction.raise => (
        'RAISE',
        const Color(0xFF34D399),
        Icons.arrow_upward_rounded,
      ),
    };

    return Semantics(
      label: 'Suggested action: $label',
      liveRegion: true,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Card(
          key: ValueKey(decision.action),
          color: bgColor,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 36),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
