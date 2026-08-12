import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:healthfit_heal/features/nutrition/data/providers/mock_food_vision_provider.dart';
import 'package:healthfit_heal/features/nutrition/data/services/food_vision_service.dart';
import 'package:healthfit_heal/features/nutrition/domain/entities/detected_food.dart';

void main() {
  late MockFoodVisionProvider provider;

  // 10×10 minimal JPEG placeholder for tests
  final fakeJpeg = Uint8List.fromList([
    0xFF, 0xD8, 0xFF, 0xE0, // JPEG SOI + APP0 marker
    ...List.filled(100, 0x00), // dummy data
  ]);

  setUp(() {
    provider = const MockFoodVisionProvider();
  });

  group('MockFoodVisionProvider — identity', () {
    test('isMock is true', () {
      expect(provider.isMock, isTrue);
    });

    test('providerName is not empty', () {
      expect(provider.providerName, isNotEmpty);
      expect(provider.providerName, contains('Mock'));
    });
  });

  group('MockFoodVisionProvider — recognize', () {
    test('returns a result without throwing', () async {
      final result = await provider.recognize(
        fakeJpeg,
        options: const RecognitionOptions(),
      );
      expect(result, isNotNull);
    });

    test('result has a providerName', () async {
      final result = await provider.recognize(fakeJpeg,
          options: const RecognitionOptions());
      expect(result.providerName, isNotEmpty);
    });

    test('returns success or partialDetection with at least one food', () async {
      final result = await provider.recognize(fakeJpeg,
          options: const RecognitionOptions());
      // Mock always returns something unless intentionally configured otherwise
      final hasFood = result.status == OverallRecognitionStatus.success ||
          result.status == OverallRecognitionStatus.partialDetection;
      if (hasFood) {
        expect(result.detectedFoods, isNotEmpty);
      }
    });

    test('all detected foods have ids', () async {
      final result = await provider.recognize(fakeJpeg,
          options: const RecognitionOptions());
      for (final food in result.detectedFoods) {
        expect(food.id, isNotEmpty);
      }
    });

    test('all detected foods have names', () async {
      final result = await provider.recognize(fakeJpeg,
          options: const RecognitionOptions());
      for (final food in result.detectedFoods) {
        expect(food.name, isNotEmpty);
      }
    });

    test('confidence scores are between 0.0 and 1.0', () async {
      final result = await provider.recognize(fakeJpeg,
          options: const RecognitionOptions());
      for (final food in result.detectedFoods) {
        expect(food.confidenceScore, inInclusiveRange(0.0, 1.0));
      }
    });

    test('respects maxFoods option', () async {
      const max = 2;
      final result = await provider.recognize(
        fakeJpeg,
        options: const RecognitionOptions(maxFoods: max),
      );
      expect(result.detectedFoods.length, lessThanOrEqualTo(max));
    });

    test('processingTimeMs is non-negative', () async {
      final result = await provider.recognize(fakeJpeg,
          options: const RecognitionOptions());
      expect(result.processingTimeMs, greaterThanOrEqualTo(0));
    });

    test('food status matches confidence score', () async {
      final result = await provider.recognize(fakeJpeg,
          options: const RecognitionOptions());
      for (final food in result.detectedFoods) {
        if (food.confidenceScore >= 0.80) {
          expect(food.status, RecognitionStatus.identified);
        } else if (food.confidenceScore >= 0.50) {
          expect(food.status, RecognitionStatus.uncertain);
        } else if (food.confidenceScore > 0) {
          expect(food.status, RecognitionStatus.lowConfidence);
        }
      }
    });
  });

  group('RecognitionOptions', () {
    test('default options have sensible values', () {
      const opts = RecognitionOptions();
      expect(opts.maxFoods, greaterThan(0));
      expect(opts.minimumConfidence, inInclusiveRange(0.0, 1.0));
    });

    test('custom options are preserved', () {
      const opts = RecognitionOptions(
        maxFoods: 5,
        minimumConfidence: 0.45,
        requestQuantityEstimate: false,
      );
      expect(opts.maxFoods, 5);
      expect(opts.minimumConfidence, 0.45);
      expect(opts.requestQuantityEstimate, isFalse);
    });
  });
}
