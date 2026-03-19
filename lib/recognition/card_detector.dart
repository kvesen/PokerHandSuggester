/// Card detection from images using Google ML Kit text recognition.
library;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/card.dart';

/// Result of a card-detection attempt on a single image.
class DetectionResult {
  const DetectionResult({
    required this.detectedCards,
    required this.unrecognizedTexts,
  });

  /// Cards successfully parsed from the image.
  final List<PokerCard> detectedCards;

  /// Text fragments that looked card-like but could not be parsed.
  final List<String> unrecognizedTexts;

  /// Whether at least one card was detected.
  bool get isSuccessful => detectedCards.isNotEmpty;
}

/// Detects playing cards in an image by running ML Kit text recognition and
/// parsing the resulting text with [CardTextParser].
class CardDetector {
  CardDetector() : _recognizer = TextRecognizer();

  final TextRecognizer _recognizer;

  /// Analyse [imagePath] and return a [DetectionResult].
  Future<DetectionResult> detectCards(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    try {
      final recognized = await _recognizer.processImage(inputImage);
      final allText = recognized.blocks
          .expand((b) => b.lines)
          .expand((l) => l.elements)
          .map((e) => e.text)
          .toList();
      return CardTextParser.parse(allText);
    } finally {
      // Do NOT close the recognizer here — it may be reused.
    }
  }

  /// Must be called when this detector is no longer needed.
  Future<void> close() => _recognizer.close();
}

/// Pure text-parsing logic: converts raw text tokens into [PokerCard] objects.
///
/// Supported formats
/// -----------------
/// * Unicode suits : `A♠`, `K♥`, `Q♦`, `J♣`, `10♠`
/// * Letter suits  : `Ah`, `Ks`, `Qd`, `Jc`, `Td`, `2c`
/// * Full names    : `Ace of Spades`, `King of Hearts`
class CardTextParser {
  const CardTextParser._();

  // --------------------------------------------------------------------------
  // Rank mappings
  // --------------------------------------------------------------------------

  static const Map<String, Rank> _rankFromLabel = {
    'a': Rank.ace,
    'ace': Rank.ace,
    'k': Rank.king,
    'king': Rank.king,
    'q': Rank.queen,
    'queen': Rank.queen,
    'j': Rank.jack,
    'jack': Rank.jack,
    't': Rank.ten,
    '10': Rank.ten,
    'ten': Rank.ten,
    '9': Rank.nine,
    'nine': Rank.nine,
    '8': Rank.eight,
    'eight': Rank.eight,
    '7': Rank.seven,
    'seven': Rank.seven,
    '6': Rank.six,
    'six': Rank.six,
    '5': Rank.five,
    'five': Rank.five,
    '4': Rank.four,
    'four': Rank.four,
    '3': Rank.three,
    'three': Rank.three,
    '2': Rank.two,
    'two': Rank.two,
  };

  static const Map<String, Suit> _suitFromLabel = {
    // unicode
    '♥': Suit.hearts,
    '♦': Suit.diamonds,
    '♣': Suit.clubs,
    '♠': Suit.spades,
    // letter abbreviations
    'h': Suit.hearts,
    'd': Suit.diamonds,
    'c': Suit.clubs,
    's': Suit.spades,
    // full names
    'hearts': Suit.hearts,
    'heart': Suit.hearts,
    'diamonds': Suit.diamonds,
    'diamond': Suit.diamonds,
    'clubs': Suit.clubs,
    'club': Suit.clubs,
    'spades': Suit.spades,
    'spade': Suit.spades,
  };

  // --------------------------------------------------------------------------
  // Regexes
  // --------------------------------------------------------------------------

  /// Matches compact notation like `A♠`, `K♥`, `10♦`, `Ah`, `Ks`, `Td`.
  static final RegExp _compactRe = RegExp(
    r'(10|[2-9AKQJT])([\u2660\u2665\u2666\u2663hsdc])',
    caseSensitive: false,
  );

  /// Matches "Ace of Spades", "King of Hearts", etc.
  static final RegExp _fullNameRe = RegExp(
    r'(ace|king|queen|jack|ten|nine|eight|seven|six|five|four|three|two)\s+of\s+'
    r'(spades?|hearts?|diamonds?|clubs?)',
    caseSensitive: false,
  );

  // --------------------------------------------------------------------------
  // Public API
  // --------------------------------------------------------------------------

  /// Parse a list of raw text tokens and return a [DetectionResult].
  static DetectionResult parse(List<String> tokens) {
    final detected = <PokerCard>{};
    final unrecognized = <String>[];

    for (final token in tokens) {
      final trimmed = token.trim();
      if (trimmed.isEmpty) continue;

      // Try full-name match first on the whole token (handles multi-word)
      final fullMatches = _fullNameRe.allMatches(trimmed.toLowerCase());
      for (final m in fullMatches) {
        final rank = _rankFromLabel[m.group(1)!.toLowerCase()];
        final suit = _suitFromLabel[m.group(2)!.toLowerCase()] ??
            _suitFromLabel['${m.group(2)!.toLowerCase()}s'];
        if (rank != null && suit != null) {
          detected.add(PokerCard(suit: suit, rank: rank));
        }
      }

      // Try compact notation on the token
      final compactMatches = _compactRe.allMatches(trimmed);
      for (final m in compactMatches) {
        final rankStr = m.group(1)!.toLowerCase();
        final suitStr = m.group(2)!.toLowerCase();
        final rank = _rankFromLabel[rankStr];
        final suit = _suitFromLabel[suitStr];
        if (rank != null && suit != null) {
          detected.add(PokerCard(suit: suit, rank: rank));
        } else {
          // Looked like a card but couldn't parse
          unrecognized.add(m.group(0)!);
        }
      }

      // If the token looks card-like but matched nothing, record it
      if (fullMatches.isEmpty && compactMatches.isEmpty) {
        if (_looksCardLike(trimmed)) {
          unrecognized.add(trimmed);
        }
      }
    }

    return DetectionResult(
      detectedCards: detected.toList(),
      unrecognizedTexts: unrecognized,
    );
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  /// Returns true for short tokens that look like they might be card notation
  /// but didn't match any known pattern (e.g. "1s", "Xx").
  static bool _looksCardLike(String text) {
    if (text.length > 10 || text.length < 2) return false;
    // Contains a digit or a face-card letter
    return RegExp(r'[2-9AKQJT]', caseSensitive: false).hasMatch(text);
  }
}
