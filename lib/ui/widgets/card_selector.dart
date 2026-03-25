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
        // Dynamically adjust spacing for tablet/desktop vs mobile
        final isWide = constraints.maxWidth > 600;
        final crossAxisSpacing = isWide ? 6.0 : 3.0;
        final mainAxisSpacing = isWide ? 6.0 : 4.0;

        return GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 13,
            childAspectRatio: 48 / 68,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
          ),
          itemCount: deck.length,
          itemBuilder: (context, index) {
            final card = deck[index];
            final isSelected = selectedCards.contains(card);
            final isDisabled = disabledCards.contains(card) ||
                (!isSelected && selectedCards.length >= maxSelectable);

            // Using Animated widgets gives the selector a premium, fluid feel
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              opacity: isDisabled ? 0.2 : 1.0,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                scale: isSelected ? 1.08 : (isDisabled ? 0.95 : 1.0),
                child: CardWidget(
                  card: card,
                  selected: isSelected,
                  size: CardSize.small,
                  onTap: isDisabled ? null : () => onCardToggled(card),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
