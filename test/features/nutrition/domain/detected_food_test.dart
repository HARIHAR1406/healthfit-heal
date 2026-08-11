import 'package:flutter_test/flutter_test.dart';

import 'package:health_fit_heal/features/nutrition/domain/entities/detected_food.dart';

void main() {
  group('ServingUnit extension', () {
    test('gramsEquivalent returns null for pieces and servings', () {
      expect(ServingUnit.pieces.gramsEquivalent, isNull);
      expect(ServingUnit.servings.gramsEquivalent, isNull);
    });

    test('gramsEquivalent returns correct values for known units', () {
      expect(ServingUnit.grams.gramsEquivalent, 1.0);
      expect(ServingUnit.cups.gramsEquivalent, 240.0);
      expect(ServingUnit.tablespoons.gramsEquivalent, 15.0);
      expect(ServingUnit.teaspoons.gramsEquivalent, 5.0);
      expect(ServingUnit.milliliters.gramsEquivalent, 1.0);
    });

    test('label returns correct short strings', () {
      expect(ServingUnit.grams.label, 'g');
      expect(ServingUnit.cups.label, 'cup');
      expect(ServingUnit.tablespoons.label, 'tbsp');
      expect(ServingUnit.teaspoons.label, 'tsp');
      expect(ServingUnit.pieces.label, 'piece(s)');
    });
  });

  group('parseServingUnit', () {
    test('parses known unit strings correctly', () {
      expect(parseServingUnit('g'), ServingUnit.grams);
      expect(parseServingUnit('gram'), ServingUnit.grams);
      expect(parseServingUnit('grams'), ServingUnit.grams);
      expect(parseServingUnit('ml'), ServingUnit.milliliters);
      expect(parseServingUnit('cup'), ServingUnit.cups);
      expect(parseServingUnit('cups'), ServingUnit.cups);
      expect(parseServingUnit('tbsp'), ServingUnit.tablespoons);
      expect(parseServingUnit('tsp'), ServingUnit.teaspoons);
      expect(parseServingUnit('piece'), ServingUnit.pieces);
      expect(parseServingUnit('pieces'), ServingUnit.pieces);
    });

    test('returns servings for unknown strings', () {
      expect(parseServingUnit('unknown'), ServingUnit.servings);
      expect(parseServingUnit('oz'), ServingUnit.servings);
    });

    test('is case insensitive', () {
      expect(parseServingUnit('G'), ServingUnit.grams);
      expect(parseServingUnit('CUP'), ServingUnit.cups);
    });
  });

  group('DetectedFood', () {
    const food = DetectedFood(
      id: 'test_id',
      name: 'Apple',
      confidenceScore: 0.87,
      status: RecognitionStatus.identified,
      providerName: 'MockProvider',
      estimatedQuantity: 1.0,
      estimatedUnit: ServingUnit.pieces,
    );

    test('isHighConfidence is true at >= 0.80', () {
      expect(food.isHighConfidence, isTrue);
    });

    test('isLowConfidence is false at >= 0.50', () {
      expect(food.isLowConfidence, isFalse);
    });

    test('confidencePercent formats correctly', () {
      expect(food.confidencePercent, '87%');
    });

    test('copyWith updates name and keeps other fields', () {
      final updated = food.copyWith(name: 'Green Apple');
      expect(updated.name, 'Green Apple');
      expect(updated.id, food.id);
      expect(updated.providerName, food.providerName);
    });

    test('copyWith with lower confidence updates status', () {
      final lowConf = food.copyWith(confidenceScore: 0.25);
      expect(lowConf.status, RecognitionStatus.lowConfidence);
    });

    test('needsQuantityConfirmation is true when isQuantityReliable is false', () {
      expect(food.needsQuantityConfirmation, isTrue);
    });
  });

  group('RecognitionStatus', () {
    test('identified.isUsable is true', () {
      expect(RecognitionStatus.identified.isUsable, isTrue);
    });

    test('uncertain.isUsable is true', () {
      expect(RecognitionStatus.uncertain.isUsable, isTrue);
    });

    test('lowConfidence.isUsable is false', () {
      expect(RecognitionStatus.lowConfidence.isUsable, isFalse);
    });

    test('unknownFood.isUsable is false', () {
      expect(RecognitionStatus.unknownFood.isUsable, isFalse);
    });
  });

  group('ConfirmedFoodItem', () {
    const item = ConfirmedFoodItem(
      id: 'item_1',
      name: 'Banana',
      quantity: 2.0,
      unit: ServingUnit.pieces,
    );

    test('isManuallyAdded is true when originalDetection is null', () {
      expect(item.isManuallyAdded, isTrue);
    });

    test('totalGramsIfKnown is null for pieces (food-dependent unit)', () {
      expect(item.totalGramsIfKnown, isNull);
    });

    test('effectiveServingSizeG falls back to unit gramsEquivalent', () {
      // pieces have null equivalent → effectiveServingSizeG is null
      expect(item.effectiveServingSizeG, isNull);
    });

    test('effectiveServingSizeG uses servingSizeG when set', () {
      const withServing = ConfirmedFoodItem(
        id: 'item_2',
        name: 'Rice',
        quantity: 1.0,
        unit: ServingUnit.grams,
        servingSizeG: 150.0,
      );
      expect(withServing.effectiveServingSizeG, 150.0);
    });

    test('totalGramsIfKnown returns quantity × gramsEquivalent for grams', () {
      const gramItem = ConfirmedFoodItem(
        id: 'item_3',
        name: 'Rice',
        quantity: 200.0,
        unit: ServingUnit.grams,
      );
      expect(gramItem.totalGramsIfKnown, 200.0);
    });

    test('totalGramsIfKnown works for cups', () {
      const cupItem = ConfirmedFoodItem(
        id: 'item_4',
        name: 'Oats',
        quantity: 1.5,
        unit: ServingUnit.cups,
      );
      expect(cupItem.totalGramsIfKnown, 360.0); // 1.5 × 240
    });
  });

  group('RecognitionResult', () {
    test('factory failed sets failed status with empty foods', () {
      final result = RecognitionResult.failed(
        reason: 'API timeout',
        providerName: 'Gemini',
      );
      expect(result.isFailed, isTrue);
      expect(result.hasFoods, isFalse);
      expect(result.failureReason, 'API timeout');
    });

    test('factory noFood sets noFoodDetected status', () {
      final result = RecognitionResult.noFood(providerName: 'Mock');
      expect(result.status, OverallRecognitionStatus.noFoodDetected);
      expect(result.hasFoods, isFalse);
    });

    test('usableFoods filters out lowConfidence items', () {
      const result = RecognitionResult(
        status: OverallRecognitionStatus.partialDetection,
        detectedFoods: [
          DetectedFood(
            id: '1',
            name: 'Apple',
            confidenceScore: 0.9,
            status: RecognitionStatus.identified,
            providerName: 'Mock',
          ),
          DetectedFood(
            id: '2',
            name: 'Unknown',
            confidenceScore: 0.2,
            status: RecognitionStatus.lowConfidence,
            providerName: 'Mock',
          ),
        ],
        providerName: 'Mock',
        processingTimeMs: 100,
      );

      expect(result.usableFoods.length, 1);
      expect(result.usableFoods.first.name, 'Apple');
      expect(result.highConfidenceCount, 1);
      expect(result.lowConfidenceCount, 1);
    });
  });
}
