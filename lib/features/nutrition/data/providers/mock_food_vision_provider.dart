import 'dart:typed_data';

import '../../../../../core/utils/app_logger.dart';
import '../../../domain/entities/detected_food.dart';
import '../food_vision_service.dart';

/// Mock food vision provider for offline development and testing.
///
/// ── Purpose ───────────────────────────────────────────────────────────────────
/// This provider is used when:
///   - No real AI API key is configured
///   - Running tests
///   - Development/debug mode without network
///
/// It returns deterministic results based on the image size — different
/// "scenarios" are triggered by the image byte length, making tests
/// predictable without mocking the network.
///
/// ── It does NOT ───────────────────────────────────────────────────────────────
///   - Make any network calls
///   - Log image bytes
///   - Return nutrition values (those come from TrustedNutritionRepository)
class MockFoodVisionProvider implements FoodVisionService {
  const MockFoodVisionProvider();

  @override
  String get providerName => 'HealthFit Mock Vision';

  @override
  bool get isAvailable => true;

  @override
  bool get isMock => true;

  @override
  Future<RecognitionResult> recognize(
    Uint8List imageBytes, {
    RecognitionOptions options = RecognitionOptions.defaults,
  }) async {
    log.debug(
      'MockFoodVisionProvider: recognizing image '
      '(${(imageBytes.length / 1024).toStringAsFixed(0)} KB)',
    );

    // Simulate processing delay (200–600 ms)
    await Future<void>.delayed(const Duration(milliseconds: 400));

    // Select scenario based on image bytes length
    final scenario = _pickScenario(imageBytes);

    return switch (scenario) {
      _MockScenario.noFood => RecognitionResult.noFood(providerName: providerName),
      _MockScenario.lowConfidence => _buildLowConfidenceResult(),
      _MockScenario.multipleHighConfidence => _buildMultipleHighResult(),
      _MockScenario.mixedConfidence => _buildMixedResult(),
      _MockScenario.singleHighConfidence => _buildSingleHighResult(),
    };
  }

  // ── Scenario selection ──────────────────────────────────────────────────────

  _MockScenario _pickScenario(Uint8List bytes) {
    // Use last byte of image data to deterministically pick scenario
    // This gives varied but repeatable results
    if (bytes.isEmpty) return _MockScenario.noFood;
    final discriminator = bytes.last % 5;
    return _MockScenario.values[discriminator];
  }

  // ── Result builders ─────────────────────────────────────────────────────────

  RecognitionResult _buildSingleHighResult() => RecognitionResult(
        status: OverallRecognitionStatus.success,
        providerName: providerName,
        processingTimeMs: 420,
        detectedFoods: [
          DetectedFood(
            id: 'mock_001',
            name: 'Apple',
            confidenceScore: 0.94,
            status: RecognitionStatus.identified,
            providerName: providerName,
            estimatedQuantity: 1.0,
            estimatedUnit: ServingUnit.pieces,
            estimatedServingSizeG: 182,
            isQuantityReliable: true,
          ),
        ],
      );

  RecognitionResult _buildMultipleHighResult() => RecognitionResult(
        status: OverallRecognitionStatus.success,
        providerName: providerName,
        processingTimeMs: 510,
        detectedFoods: [
          DetectedFood(
            id: 'mock_002',
            name: 'Brown Rice',
            confidenceScore: 0.91,
            status: RecognitionStatus.identified,
            providerName: providerName,
            estimatedQuantity: 200,
            estimatedUnit: ServingUnit.grams,
            estimatedServingSizeG: 200,
            isQuantityReliable: false,
          ),
          DetectedFood(
            id: 'mock_003',
            name: 'Chicken Breast',
            confidenceScore: 0.87,
            status: RecognitionStatus.identified,
            providerName: providerName,
            estimatedQuantity: 150,
            estimatedUnit: ServingUnit.grams,
            estimatedServingSizeG: 150,
            isQuantityReliable: false,
          ),
          DetectedFood(
            id: 'mock_004',
            name: 'Broccoli',
            confidenceScore: 0.82,
            status: RecognitionStatus.identified,
            providerName: providerName,
            estimatedQuantity: 80,
            estimatedUnit: ServingUnit.grams,
            estimatedServingSizeG: 80,
            isQuantityReliable: false,
          ),
        ],
      );

  RecognitionResult _buildMixedResult() => RecognitionResult(
        status: OverallRecognitionStatus.success,
        providerName: providerName,
        processingTimeMs: 480,
        detectedFoods: [
          DetectedFood(
            id: 'mock_005',
            name: 'Banana',
            confidenceScore: 0.88,
            status: RecognitionStatus.identified,
            providerName: providerName,
            estimatedQuantity: 2.0,
            estimatedUnit: ServingUnit.pieces,
            estimatedServingSizeG: 118,
            isQuantityReliable: true,
          ),
          DetectedFood(
            id: 'mock_006',
            name: 'Oats',
            confidenceScore: 0.63,
            status: RecognitionStatus.uncertain,
            providerName: providerName,
            estimatedQuantity: 40,
            estimatedUnit: ServingUnit.grams,
            estimatedServingSizeG: 40,
            isQuantityReliable: false,
            alternativeSuggestions: ['Granola', 'Muesli', 'Porridge'],
          ),
          DetectedFood(
            id: 'mock_007',
            name: 'Greek Yogurt',
            confidenceScore: 0.44,
            status: RecognitionStatus.lowConfidence,
            providerName: providerName,
            estimatedQuantity: 1.0,
            estimatedUnit: ServingUnit.servings,
            isQuantityReliable: false,
            alternativeSuggestions: ['Plain Yogurt', 'Cottage Cheese'],
          ),
        ],
      );

  RecognitionResult _buildLowConfidenceResult() => RecognitionResult(
        status: OverallRecognitionStatus.partialDetection,
        providerName: providerName,
        processingTimeMs: 390,
        detectedFoods: [
          DetectedFood(
            id: 'mock_008',
            name: 'Mixed Salad',
            confidenceScore: 0.41,
            status: RecognitionStatus.lowConfidence,
            providerName: providerName,
            estimatedQuantity: 1.0,
            estimatedUnit: ServingUnit.servings,
            isQuantityReliable: false,
            alternativeSuggestions: ['Caesar Salad', 'Green Salad', 'Vegetable Mix'],
          ),
        ],
      );
}

// ── Scenario enum ──────────────────────────────────────────────────────────────

enum _MockScenario {
  singleHighConfidence,
  multipleHighConfidence,
  mixedConfidence,
  lowConfidence,
  noFood,
}
