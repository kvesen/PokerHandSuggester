/// Interactive card picker — grid of all 52 cards.
library;

import 'package:flutter/material.dart';

import '../../models/card.dart';
import 'card_widget.dart';

/// A scrollable grid showing all 52 cards. Tapping a card toggles its
/// selected state. [selectedCards] is the external selection state;
/// [onCardToggled] is called whenever the user taps a card.
///
/// [disabledCards] – cards that cannot be selected (already used elsewhere).
/// [maxSelectable] – maximum cards that can be selected at once.
class CardSelector extends StatelessWidget {
  const CardSelector({
    super.key,
    required this.selectedCards,
    required this.onCardToggled,
    this.disabledCards = const [],
    this.maxSelectable = 52,
  });

  final List<PokerCard> selectedCards;
  final void Function(PokerCard card) onCardToggled;
  final List<PokerCard> disabledCards;
  final int maxSelectable;

  @override
  Widget build(BuildContext context) {
    final deck = PokerCard.fullDeck();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Dynamic column count: clamp between 4 (one per suit, readable on
        // very narrow screens) and 13 (one per rank, full-deck layout on wide
        // screens). Each cell is ≥ 44 dp wide to meet the 48 dp touch-target
        // recommendation with a small margin for spacing.
        final int crossCount =
            (constraints.maxWidth / 44).floor().clamp(4, 13);

        return GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            childAspectRatio: 1.0,
            crossAxisSpacing: 2.0,
            mainAxisSpacing: 2.0,
          ),
          itemCount: deck.length,
          itemBuilder: (context, index) {
            final card = deck[index];
            final isSelected = selectedCards.contains(card);
            final isDisabled = disabledCards.contains(card) ||
                (!isSelected && selectedCards.length >= maxSelectable);

            // Stagger the entry animation by varying duration per card index,
            // so cards animate in sequentially rather than all at once.
            return SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: isDisabled ? 0.2 : 1.0),
                  duration:
                      Duration(milliseconds: 250 + (index * 8).clamp(0, 200)),
                  curve: Curves.easeOutCubic,
                  builder: (context, opacity, child) =>
                      Opacity(opacity: opacity, child: child),
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    scale: isSelected ? 1.08 : (isDisabled ? 0.95 : 1.0),
                    child: CardWidget(
                      card: card,
                      selected: isSelected,
                      size: CardSize.tiny,
                      onTap: isDisabled ? null : () => onCardToggled(card),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
