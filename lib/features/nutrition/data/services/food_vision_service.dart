import 'dart:typed_data';

import '../../domain/entities/detected_food.dart';

/// Options controlling how recognition is performed.
class RecognitionOptions {
  const RecognitionOptions({
    this.maxFoods = 8,
    this.minimumConfidence = 0.30,
    this.requestBoundingBoxes = false,
    this.requestQuantityEstimate = true,
    this.languageCode = 'en',
    this.timeoutSeconds = 30,
  });

  /// Maximum number of food items to return.
  final int maxFoods;

  /// Discard detections below this confidence threshold.
  final double minimumConfidence;

  /// Whether to request bounding-box coordinates.
  final bool requestBoundingBoxes;

  /// Whether to request quantity/portion estimates.
  final bool requestQuantityEstimate;

  /// Language code for food names in results.
  final String languageCode;

  /// Recognition timeout in seconds.
  final int timeoutSeconds;

  static const RecognitionOptions defaults = RecognitionOptions();
}

/// Provider-independent abstraction for food image recognition.
///
/// ── Architecture principle ─────────────────────────────────────────────────────
/// This interface isolates the computer-vision layer from the rest of the app.
/// The implementing class may use:
///   - A real remote AI (Gemini Vision, Google Cloud Vision, etc.)
///   - A local on-device model
///   - A mock/stub for offline/testing use
///
/// Swapping the provider = implementing this interface.
/// NO changes to UI, domain, or trust layer required.
///
/// ── What this interface must NOT do ───────────────────────────────────────────
///   - Return nutrition values (those come from TrustedNutritionRepository)
///   - Call the nutrition calculation engine
///   - Store image bytes permanently
///   - Expose raw API errors to callers (use RecognitionResult.failed)
abstract interface class FoodVisionService {
  /// Recognizes food items in the provided [imageBytes].
  ///
  /// [imageBytes] must be JPEG, PNG, or WEBP.
  /// [options] controls confidence threshold, timeouts, etc.
  ///
  /// Always returns a [RecognitionResult] — never throws.
  /// Check [RecognitionResult.status] before using the detected foods.
  Future<RecognitionResult> recognize(
    Uint8List imageBytes, {
    RecognitionOptions options = RecognitionOptions.defaults,
  });

  /// Whether this provider is currently available.
  ///
  /// Returns false if a required API key is missing or the provider
  /// cannot be initialized. The caller should fall back to the mock.
  bool get isAvailable;

  /// Human-readable provider name (safe to display / log).
  String get providerName;

  /// Whether this is a mock/stub implementation.
  bool get isMock;
}

