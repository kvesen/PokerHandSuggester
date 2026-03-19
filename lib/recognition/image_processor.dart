/// Image pre-processing utilities for improved card recognition.
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Provides image pre-processing helpers to improve OCR accuracy.
class ImageProcessor {
  const ImageProcessor._();

  // --------------------------------------------------------------------------
  // Public API
  // --------------------------------------------------------------------------

  /// Converts [inputPath] to grayscale and saves the result.
  /// Returns the path to the processed image.
  static Future<String> toGrayscale(String inputPath) async {
    final source = await _loadImage(inputPath);
    if (source == null) return inputPath;
    final gray = img.grayscale(source);
    return _saveTmp(gray, 'gray');
  }

  /// Enhances contrast of the image at [inputPath] and saves the result.
  /// [factor] 1.0 = no change; >1.0 = more contrast.
  static Future<String> enhanceContrast(
    String inputPath, {
    double factor = 1.5,
  }) async {
    final source = await _loadImage(inputPath);
    if (source == null) return inputPath;
    final enhanced = img.adjustColor(
      source,
      contrast: factor,
    );
    return _saveTmp(enhanced, 'contrast');
  }

  /// Crops [inputPath] to the rectangle defined by [left], [top], [width],
  /// [height] (all in pixels). Returns the path to the cropped image.
  static Future<String> crop(
    String inputPath, {
    required int left,
    required int top,
    required int width,
    required int height,
  }) async {
    final source = await _loadImage(inputPath);
    if (source == null) return inputPath;
    final cropped = img.copyCrop(
      source,
      x: left,
      y: top,
      width: width,
      height: height,
    );
    return _saveTmp(cropped, 'crop');
  }

  /// Rotates [inputPath] by [degrees] (0 / 90 / 180 / 270) and saves the
  /// result.
  static Future<String> rotate(String inputPath, int degrees) async {
    final source = await _loadImage(inputPath);
    if (source == null) return inputPath;
    final angle = _normalizeAngle(degrees);
    final rotated = img.copyRotate(source, angle: angle.toDouble());
    return _saveTmp(rotated, 'rot');
  }

  /// Applies grayscale + contrast enhancement in one step, which is the
  /// recommended pre-processing pipeline before running OCR.
  static Future<String> prepareForOcr(
    String inputPath, {
    double contrastFactor = 1.5,
  }) async {
    final gray = await toGrayscale(inputPath);
    return enhanceContrast(gray, factor: contrastFactor);
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  static Future<img.Image?> _loadImage(String path) async {
    final bytes = await File(path).readAsBytes();
    return img.decodeImage(bytes);
  }

  static Future<String> _saveTmp(img.Image image, String tag) async {
    final tmpDir = await getTemporaryDirectory();
    final name = '${tag}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File('${tmpDir.path}/$name');
    await file.writeAsBytes(img.encodeJpg(image, quality: 90));
    return file.path;
  }

  static int _normalizeAngle(int degrees) {
    // Round to nearest 90°
    final rounded = ((degrees / 90).round() * 90) % 360;
    return math.max(0, rounded);
  }
}
