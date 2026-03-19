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

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 13,
        childAspectRatio: 48 / 68,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
      ),
      itemCount: deck.length,
      itemBuilder: (context, index) {
        final card = deck[index];
        final isSelected = selectedCards.contains(card);
        final isDisabled = disabledCards.contains(card) ||
            (!isSelected && selectedCards.length >= maxSelectable);

        return Opacity(
          opacity: isDisabled ? 0.3 : 1.0,
          child: CardWidget(
            card: card,
            selected: isSelected,
            size: CardSize.small,
            onTap: isDisabled ? null : () => onCardToggled(card),
          ),
        );
      },
    );
  }
}
