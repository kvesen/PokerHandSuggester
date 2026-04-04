import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_hand_suggester/models/card.dart';
import 'package:poker_hand_suggester/recognition/card_detector.dart';
import 'package:poker_hand_suggester/ui/screens/detection_review_screen.dart';
import 'package:poker_hand_suggester/ui/screens/manual_input_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  late File testImageFile;

  setUp(() async {
    // Create a minimal temporary file as a stand-in for the captured image.
    testImageFile = File('/tmp/detection_review_test.jpg');
    if (!testImageFile.existsSync()) {
      await testImageFile.create(recursive: true);
    }
  });

  const detectedCards = [
    PokerCard(suit: Suit.spades, rank: Rank.ace),
    PokerCard(suit: Suit.hearts, rank: Rank.king),
    PokerCard(suit: Suit.clubs, rank: Rank.ten),
  ];

  Widget buildScreen({List<PokerCard> cards = detectedCards}) {
    return MaterialApp(
      home: DetectionReviewScreen(
        imagePath: testImageFile.path,
        detectionResult: DetectionResult(
          detectedCards: cards,
          unrecognizedTexts: [],
        ),
      ),
    );
  }

  group('DetectionReviewScreen', () {
    testWidgets('renders the screen title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Review Detected Cards'), findsOneWidget);
    });

    testWidgets('shows detected card count header', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.textContaining('3 cards detected'), findsOneWidget);
    });

    testWidgets('renders detected card labels', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Ace of ♠ Spades'), findsOneWidget);
      expect(find.text('King of ♥ Hearts'), findsOneWidget);
      expect(find.text('10 of ♣ Clubs'), findsOneWidget);
    });

    testWidgets('all cards default to My Hand assignment', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      // Every assignment chip should start as "My Hand".
      expect(find.text('My Hand'), findsNWidgets(detectedCards.length));
    });

    testWidgets('tapping an assignment chip toggles to Community',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      // Tap the first "My Hand" chip.
      await tester.tap(find.text('My Hand').first);
      await tester.pumpAndSettle();

      // One card should now show 'Community'.
      expect(find.text('Community'), findsOneWidget);
    });

    testWidgets('tapping Community chip toggles back to My Hand',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.tap(find.text('My Hand').first);
      await tester.pumpAndSettle();

      // Now tap the Community chip to toggle back.
      await tester.tap(find.text('Community').first);
      await tester.pumpAndSettle();

      expect(find.text('Community'), findsNothing);
      expect(find.text('My Hand'), findsNWidgets(detectedCards.length));
    });

    testWidgets('"Continue" button is present', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('"Continue" button navigates to ManualInputScreen',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.byType(ManualInputScreen), findsOneWidget);
    });

    testWidgets('"Retake Photo" button is present', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Retake Photo'), findsOneWidget);
    });

    testWidgets('shows empty state when no cards are detected', (tester) async {
      await tester.pumpWidget(buildScreen(cards: []));
      await tester.pump();

      expect(find.text('No cards detected.\nAdd cards manually below.'),
          findsOneWidget);
    });

    testWidgets('"Add Card Manually" button is present', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Add Card Manually'), findsOneWidget);
    });
  });
}
