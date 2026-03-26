/// Card detection from images using a custom TFLite object detection model.
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/card.dart';

/// A single detection from the model — card identity, confidence, and location.
class Detection {
  const Detection({
    required this.card,
    required this.confidence,
    required this.boundingBox,
  });

  final PokerCard card;

  /// Confidence score in the range [0, 1].
  final double confidence;

  /// Normalized bounding box `[top, left, bottom, right]` in the range [0, 1].
  final List<double> boundingBox;
}

/// Result of a card-detection attempt on a single image.
class DetectionResult {
  const DetectionResult({
    required this.detectedCards,
    required this.unrecognizedTexts,
    this.detections = const [],
  });

  /// Cards successfully identified in the image.
  final List<PokerCard> detectedCards;

  /// Text / label tokens that looked card-like but could not be mapped to a
  /// known card (kept for debugging / review UI).
  final List<String> unrecognizedTexts;

  /// Full detection list including confidence scores and bounding boxes.
  final List<Detection> detections;

  /// Whether at least one card was detected.
  bool get isSuccessful => detectedCards.isNotEmpty;
}

/// Detects playing cards using an on-device TFLite object detection model.
///
/// Call [loadModel] once before using [detectCards]. Call [close] when the
/// detector is no longer needed to release native resources.
class CardDetector {
  Interpreter? _interpreter;
  List<String> _labels = [];

  /// Model input image size (width == height). Must match the trained model.
  static const int _inputSize = 320;

  /// Detections below this score are discarded.
  static const double _confidenceThreshold = 0.5;

  /// Maximum number of detections the model can return per image.
  static const int _maxDetections = 25;

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  /// Loads the TFLite interpreter and label list from bundled assets.
  ///
  /// Safe to call multiple times — subsequent calls are no-ops when the model
  /// is already loaded.
  ///
  /// Throws a [StateError] if the model asset is a placeholder stub rather than
  /// a valid TFLite flatbuffer. Replace `assets/models/card_detection_model.tflite`
  /// with a trained model — see `assets/models/README.md` for instructions.
  Future<void> loadModel() async {
    if (_interpreter != null) return;
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/card_detection_model.tflite',
      );
    } on Exception catch (e) {
      throw StateError(
        'Failed to load card detection model. '
        'The bundled .tflite file is a placeholder stub — replace it with a '
        'trained model. See assets/models/README.md for instructions.\n'
        'Underlying error: $e',
      );
    }
    _labels = await _loadLabels('assets/models/card_labels.txt');
  }

  Future<List<String>> _loadLabels(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Detection
  // ---------------------------------------------------------------------------

  /// Analyses [imagePath] and returns a [DetectionResult].
  ///
  /// Loads the model automatically if [loadModel] has not been called yet.
  Future<DetectionResult> detectCards(String imagePath) async {
    if (_interpreter == null) await loadModel();

    // Load and resize the image to the model's expected input dimensions.
    final bytes = await File(imagePath).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      return const DetectionResult(
        detectedCards: [],
        unrecognizedTexts: [],
      );
    }

    final resized = img.copyResize(image, width: _inputSize, height: _inputSize);
    final input = _imageToInput(resized);

    // Output buffers — SSD-style: boxes, classes, scores, count.
    final outputBoxes = List.generate(
      1,
      (_) => List.generate(_maxDetections, (_) => List.filled(4, 0.0)),
    );
    final outputClasses =
        List.generate(1, (_) => List.filled(_maxDetections, 0.0));
    final outputScores =
        List.generate(1, (_) => List.filled(_maxDetections, 0.0));
    final outputCount = List.filled(1, 0.0);

    final outputs = <int, Object>{
      0: outputBoxes,
      1: outputClasses,
      2: outputScores,
      3: outputCount,
    };

    _interpreter!.runForMultipleInputs([input], outputs);

    // Parse detections.
    final detections = <Detection>[];
    final cards = <PokerCard>{};
    final unrecognized = <String>[];
    final count = outputCount[0].toInt().clamp(0, _maxDetections);

    for (var i = 0; i < count; i++) {
      final score = outputScores[0][i];
      if (score < _confidenceThreshold) continue;

      final classIndex = outputClasses[0][i].toInt();
      if (classIndex < 0 || classIndex >= _labels.length) continue;

      final label = _labels[classIndex];
      final card = labelToPokerCard(label);
      if (card == null) {
        unrecognized.add(label);
        continue;
      }

      cards.add(card);
      detections.add(Detection(
        card: card,
        confidence: score,
        boundingBox: List<double>.from(outputBoxes[0][i]),
      ));
    }

    return DetectionResult(
      detectedCards: cards.toList(),
      unrecognizedTexts: unrecognized,
      detections: detections,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Converts an [img.Image] to the float32 input tensor expected by the model.
  ///
  /// Pixel values are normalized to [0, 1].
  List<List<List<List<double>>>> _imageToInput(img.Image image) {
    return List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(_inputSize, (x) {
          final pixel = image.getPixel(x, y);
          return [
            pixel.r / 255.0,
            pixel.g / 255.0,
            pixel.b / 255.0,
          ];
        }),
      ),
    );
  }

  /// Maps a label string like `"ace_spades"` to a [PokerCard].
  ///
  /// Returns `null` if the label cannot be parsed.
  static PokerCard? labelToPokerCard(String label) {
    final parts = label.toLowerCase().split('_');
    if (parts.length != 2) return null;

    final rank = _rankFromName[parts[0]];
    final suit = _suitFromName[parts[1]];
    if (rank == null || suit == null) return null;

    return PokerCard(rank: rank, suit: suit);
  }

  static const Map<String, Rank> _rankFromName = {
    'ace': Rank.ace,
    '2': Rank.two,
    '3': Rank.three,
    '4': Rank.four,
    '5': Rank.five,
    '6': Rank.six,
    '7': Rank.seven,
    '8': Rank.eight,
    '9': Rank.nine,
    '10': Rank.ten,
    'jack': Rank.jack,
    'queen': Rank.queen,
    'king': Rank.king,
  };

  static const Map<String, Suit> _suitFromName = {
    'spades': Suit.spades,
    'hearts': Suit.hearts,
    'diamonds': Suit.diamonds,
    'clubs': Suit.clubs,
  };

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Releases the TFLite interpreter. Call when the detector is no longer needed.
  Future<void> close() async {
    _interpreter?.close();
    _interpreter = null;
  }
}

