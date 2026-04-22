import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poker_hand_suggester/models/position.dart';
import 'package:poker_hand_suggester/ui/widgets/position_selector.dart';

void main() {
  Widget buildSelector({
    TablePosition? selected,
    ValueChanged<TablePosition?>? onChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 200,
          child: PositionSelector(
            selectedPosition: selected,
            onPositionChanged: onChanged ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('PositionSelector', () {
    testWidgets('renders 9 seat position labels', (tester) async {
      await tester.pumpWidget(buildSelector());
      await tester.pumpAndSettle();

      // All 9 seat labels should appear.
      for (final pos in TablePosition.values) {
        expect(find.text(positionLabel(pos)), findsOneWidget);
      }
    });

    testWidgets('tapping a seat selects it', (tester) async {
      TablePosition? selected;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 200,
                child: PositionSelector(
                  selectedPosition: selected,
                  onPositionChanged: (pos) =>
                      setState(() => selected = pos),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the Button seat label.
      await tester.tap(find.text(positionLabel(TablePosition.button)));
      await tester.pumpAndSettle();

      expect(selected, TablePosition.button);
    });

    testWidgets('tapping the selected seat deselects it', (tester) async {
      TablePosition? selected = TablePosition.button;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 200,
                child: PositionSelector(
                  selectedPosition: selected,
                  onPositionChanged: (pos) =>
                      setState(() => selected = pos),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tapping the already-selected seat should deselect (null).
      await tester.tap(find.text(positionLabel(TablePosition.button)));
      await tester.pumpAndSettle();

      expect(selected, isNull);
    });

    testWidgets('seats have Semantics labels', (tester) async {
      await tester.pumpWidget(buildSelector());
      await tester.pumpAndSettle();

      // Each seat should have a Semantics node with '<LABEL> seat'.
      expect(
        find.bySemanticsLabel(
          RegExp('${positionLabel(TablePosition.button)} seat'),
        ),
        findsOneWidget,
      );
    });
  });
}
