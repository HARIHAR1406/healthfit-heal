import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_fit_heal/core/trust/domain/entities/meal_nutrition_result.dart';
import 'package:health_fit_heal/core/trust/domain/entities/nutrition_input.dart';
import 'package:health_fit_heal/core/trust/domain/entities/trusted_recommendation.dart';
import 'package:health_fit_heal/core/trust/recommendation/recommendation_context.dart';
import 'package:health_fit_heal/core/trust/recommendation/recommendation_failure.dart';
import 'package:health_fit_heal/core/trust/recommendation/recommendation_safety_layer.dart';
import 'package:health_fit_heal/features/nutrition/data/services/food_vision_service.dart';
import 'package:health_fit_heal/features/nutrition/data/services/image_processing_service.dart';
import 'package:health_fit_heal/features/nutrition/domain/entities/detected_food.dart';
import 'package:health_fit_heal/features/nutrition/presentation/providers/food_scanner_notifier.dart';
import 'package:health_fit_heal/features/nutrition/presentation/providers/food_scanner_state.dart';

class MockFoodVisionService implements FoodVisionService {
  late RecognitionResult nextResult;

  @override
  bool get isAvailable => true;

  @override
  bool get isMock => true;

  @override
  String get providerName => 'TestProvider';

  @override
  Future<RecognitionResult> recognize(
    Uint8List imageBytes, {
    RecognitionOptions options = RecognitionOptions.defaults,
  }) async {
    return nextResult;
  }
}

class MockImageProcessingService implements ImageProcessingService {
  late ImagePickResult nextPickResult;
  late ImageValidationResult nextValidationResult;
  late Uint8List nextPreparedBytes;

  @override
  Future<ImagePickResult> pickFromCamera() async => nextPickResult;

  @override
  Future<ImagePickResult> pickFromGallery() async => nextPickResult;

  @override
  Future<Uint8List> prepareForRecognition(Uint8List bytes) async =>
      nextPreparedBytes;

  @override
  ImageValidationResult validate(Uint8List bytes) => nextValidationResult;
}

class MockRecommendationSafetyLayer implements RecommendationSafetyLayer {
  late Result<RecommendationContext, RecommendationFailure> nextContextResult;
  late TrustedRecommendation nextRecommendation;

  @override
  Future<Result<RecommendationContext, RecommendationFailure>> buildContext({
    required List<RawFoodInput> inputs,
    Map<String, double>? healthMetrics,
    Map<String, double>? userGoals,
  }) async {
    return nextContextResult;
  }

  @override
  TrustedRecommendation buildRecommendation({
    required RecommendationContext context,
    required String title,
  }) {
    return nextRecommendation;
  }
}

void main() {
  late ProviderContainer container;
  late MockFoodVisionService visionService;
  late MockImageProcessingService imageService;
  late MockRecommendationSafetyLayer safetyLayer;
  late FoodScannerNotifier notifier;

  final testBytes = Uint8List.fromList([1, 2, 3]);

  setUp(() {
    visionService = MockFoodVisionService();
    imageService = MockImageProcessingService();
    safetyLayer = MockRecommendationSafetyLayer();

    notifier = FoodScannerNotifier(
      visionService: visionService,
      imageService: imageService,
      safetyLayer: safetyLayer,
    );
  });

  group('FoodScannerNotifier image picking', () {
    test('initial state is FoodScannerInitial', () {
      expect(notifier.state, const TypeMatcher<FoodScannerInitial>());
    });

    test('pickFromCamera handles cancellation', () async {
      imageService.nextPickResult = const ImagePickResult.cancelled();
      await notifier.pickFromCamera();
      expect(notifier.state, const TypeMatcher<FoodScannerInitial>());
    });

    test('pickFromCamera handles permission denial', () async {
      imageService.nextPickResult = const ImagePickResult.error(
        error: ImagePickError.permissionDenied,
        userMessage: 'Denied',
      );
      await notifier.pickFromCamera();
      
      final state = notifier.state;
      expect(state, const TypeMatcher<FoodScannerError>());
      if (state is FoodScannerError) {
        expect(state.type, ScannerErrorType.permissionDenied);
      }
    });

    test('valid image transitions to FoodScannerRecognizing', () async {
      imageService.nextPickResult = ImagePickResult.success(
        bytes: testBytes,
        source: ImageSource.camera,
        mimeType: 'image/jpeg',
      );
      imageService.nextValidationResult = ImageValidationResult.valid(
        bytes: testBytes,
        detectedFormat: ImageValidationResult.valid(bytes: testBytes, detectedFormat: null).detectedFormat ?? null as dynamic, // Mocking format is tricky, just needs isValid
      ); // Workaround: Mock validation
      
      // Better way to construct valid mock validation result
      final validValidation = ImageValidationResult.failure(ImageValidationError.corrupted, '');
      imageService.nextValidationResult = validValidation; // Overridden below
      
      // Let's just override correctly since we have factories
      imageService.nextValidationResult = ImageValidationResult.valid(
        bytes: testBytes,
        detectedFormat: null as dynamic, // Not accessed by notifier
      );
      
      imageService.nextPreparedBytes = testBytes;
      visionService.nextResult = RecognitionResult.noFood(providerName: 'Mock');

      await notifier.pickFromCamera();
      
      final state = notifier.state;
      // Because we awaited the whole thing, it should process all the way to NoFoodFound
      expect(state, const TypeMatcher<FoodScannerNoFoodFound>());
    });
  });

  group('FoodScannerNotifier recognition results', () {
    setUp(() {
      imageService.nextPickResult = ImagePickResult.success(
        bytes: testBytes,
        source: ImageSource.camera,
        mimeType: 'image/jpeg',
      );
      imageService.nextValidationResult = ImageValidationResult.valid(
        bytes: testBytes,
        detectedFormat: null as dynamic,
      );
      imageService.nextPreparedBytes = testBytes;
    });

    test('failed recognition sets visionProviderError', () async {
      visionService.nextResult = RecognitionResult.failed(
        reason: 'API Down',
        providerName: 'Mock',
      );
      
      await notifier.pickFromCamera();
      final state = notifier.state as FoodScannerError;
      expect(state.type, ScannerErrorType.visionProviderError);
      expect(state.previousImageBytes, testBytes); // Check retry payload
    });

    test('successful recognition with foods transitions to Detected', () async {
      visionService.nextResult = const RecognitionResult(
        status: OverallRecognitionStatus.success,
        detectedFoods: [
          DetectedFood(
            id: '1',
            name: 'Apple',
            confidenceScore: 0.9,
            status: RecognitionStatus.identified,
            providerName: 'Mock',
          ),
        ],
        providerName: 'Mock',
        processingTimeMs: 100,
      );

      await notifier.pickFromCamera();
      final state = notifier.state as FoodScannerDetected;
      expect(state.detectedFoods.length, 1);
      expect(state.providerName, 'Mock');
    });
  });

  group('FoodScannerNotifier state machine flow', () {
    test('proceedToConfirmation converts usable DetectedFoods to ConfirmedFoodItem', () {
      notifier.proceedToConfirmation([
        const DetectedFood(
          id: '1',
          name: 'Apple',
          confidenceScore: 0.9,
          status: RecognitionStatus.identified,
          providerName: 'Mock',
        ),
        const DetectedFood(
          id: '2',
          name: 'Unknown',
          confidenceScore: 0.2,
          status: RecognitionStatus.lowConfidence,
          providerName: 'Mock',
        ),
      ], testBytes);

      final state = notifier.state as FoodScannerConfirming;
      expect(state.items.length, 1); // lowConfidence is filtered out
      expect(state.items.first.name, 'Apple');
    });

    test('can edit items during confirmation', () {
      notifier.proceedToConfirmationFromNoFood(testBytes);
      notifier.addFoodManually(name: 'Banana', quantity: 2.0);
      
      var state = notifier.state as FoodScannerConfirming;
      expect(state.items.length, 1);
      final id = state.items.first.id;

      notifier.updateQuantity(id, 3.0);
      state = notifier.state as FoodScannerConfirming;
      expect(state.items.first.quantity, 3.0);

      notifier.updateUnit(id, ServingUnit.grams);
      state = notifier.state as FoodScannerConfirming;
      expect(state.items.first.unit, ServingUnit.grams);

      notifier.removeFood(id);
      state = notifier.state as FoodScannerConfirming;
      expect(state.items.isEmpty, isTrue);
    });
  });

  group('FoodScannerNotifier nutrition pipeline', () {
    test('successful pipeline transitions to Result', () async {
      // 1. Enter confirming state
      notifier.proceedToConfirmationFromNoFood(testBytes);
      notifier.addFoodManually(name: 'Banana', quantity: 1.0);
      
      // 2. Mock safety layer
      final context = RecommendationContext(
        inputs: [],
        calculatedNutrition: const MealNutritionResult(
          status: MealCalculationStatus.complete,
          itemResults: [],
          totalCalories: 100,
          totalProteinG: 10,
          totalCarbsG: 10,
          totalFatG: 1,
          totalFiberG: 0,
          totalSugarG: 0,
          totalSodiumMg: 0,
        ),
        healthMetrics: {},
        userGoals: {},
        classifications: [],
        safetyFlags: [],
      );
      
      safetyLayer.nextContextResult = Success(context);
      safetyLayer.nextRecommendation = const TrustedRecommendation(
        title: 'Banana',
        aiExplanation: 'It is a banana.',
        disclaimer: 'Standard disclaimer',
        safetyFlags: [],
      );

      // 3. Trigger calculation
      await notifier.calculateNutrition();

      final state = notifier.state as FoodScannerResult;
      expect(state.mealResult.totalCalories, 100);
      expect(state.recommendation.title, 'Banana');
    });

    test('pipeline failure transitions to Error', () async {
      notifier.proceedToConfirmationFromNoFood(testBytes);
      notifier.addFoodManually(name: 'Unknown item XYZ', quantity: 1.0);
      
      safetyLayer.nextContextResult = const Failure(AllItemsUnresolvableFailure());

      await notifier.calculateNutrition();

      final state = notifier.state as FoodScannerError;
      expect(state.type, ScannerErrorType.allUnresolvable);
    });
  });
}
