import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poker_hand_suggester/engine/decision_engine.dart';
import 'package:poker_hand_suggester/ui/widgets/decision_badge.dart';

void main() {
  group('DecisionBadge', () {
    Widget buildBadge(PlayerAction action) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: DecisionBadge(action: action),
          ),
        ),
      );
    }

    testWidgets('shows FOLD text for fold action', (tester) async {
      await tester.pumpWidget(buildBadge(PlayerAction.fold));
      await tester.pumpAndSettle();
      expect(find.text('FOLD'), findsOneWidget);
    });

    testWidgets('shows CALL text for call action', (tester) async {
      await tester.pumpWidget(buildBadge(PlayerAction.call));
      await tester.pumpAndSettle();
      expect(find.text('CALL'), findsOneWidget);
    });

    testWidgets('shows RAISE text for raise action', (tester) async {
      await tester.pumpWidget(buildBadge(PlayerAction.raise));
      await tester.pumpAndSettle();
      expect(find.text('RAISE'), findsOneWidget);
    });

    testWidgets('FOLD badge uses red gradient colors', (tester) async {
      await tester.pumpWidget(buildBadge(PlayerAction.fold));
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(ScaleTransition),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;
      final gradient = decoration.gradient! as LinearGradient;
      expect(gradient.colors.first, const Color(0xFFF43F5E));
    });

    testWidgets('CALL badge uses yellow gradient colors', (tester) async {
      await tester.pumpWidget(buildBadge(PlayerAction.call));
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(ScaleTransition),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;
      final gradient = decoration.gradient! as LinearGradient;
      expect(gradient.colors.first, const Color(0xFFFBBF24));
    });

    testWidgets('RAISE badge uses green gradient colors', (tester) async {
      await tester.pumpWidget(buildBadge(PlayerAction.raise));
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(ScaleTransition),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;
      final gradient = decoration.gradient! as LinearGradient;
      expect(gradient.colors.first, const Color(0xFF34D399));
    });
  });
}
