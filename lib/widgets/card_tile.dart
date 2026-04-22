/// Reusable card slot tile -- shows a card or an empty placeholder.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/card.dart';
import '../ui/widgets/card_widget.dart';

/// An interactive card slot that shows either a [PokerCard] or an empty
/// placeholder. Tapping the slot calls [onTap].
class CardTile extends StatelessWidget {
  const CardTile({
    super.key,
    this.card,
    required this.onTap,
    this.semanticLabel,
  });

  final PokerCard? card;
  final VoidCallback onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label:
          semanticLabel ??
          (card == null ? 'Empty card slot — tap to add' : 'Card slot'),
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: card != null
            ? CardWidget(card: card!, size: CardSize.medium)
            : Container(
                width: 52,
                height: 74,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                  size: 24,
                ),
              ),
      ),
    );
  }
}
