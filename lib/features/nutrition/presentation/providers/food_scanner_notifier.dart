import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/trust/domain/entities/nutrition_input.dart';
import '../../../../core/trust/recommendation/recommendation_context.dart';
import '../../../../core/trust/recommendation/recommendation_failure.dart';
import '../../../../core/trust/recommendation/recommendation_safety_layer.dart';
import '../../../../core/utils/app_logger.dart';
import '../../data/services/food_vision_service.dart';
import '../../data/services/image_processing_service.dart';
import '../../domain/entities/detected_food.dart';
import 'food_scanner_state.dart';

/// Business logic controller for the Food Scanner feature.
///
/// ── Responsibilities ──────────────────────────────────────────────────────────
///   1. Pick/validate images via [ImageProcessingService]
///   2. Recognize foods via [FoodVisionService]
///   3. Manage the user confirmation/edit flow
///   4. Convert confirmed items → Phase 12 [NutritionInput] models
///   5. Run the Phase 12 safety pipeline
///   6. Deliver [FoodScannerResult] or [FoodScannerError]
///
/// ── Phase 12 integration ──────────────────────────────────────────────────────
///   All nutrition calculation flows through [RecommendationSafetyLayer].
///   This notifier NEVER touches nutrition math or health rule evaluation.
///
/// ── Privacy rules ─────────────────────────────────────────────────────────────
///   - Never log image bytes
///   - Never log food names alongside user health data
///   - Log only item counts and status codes in production
class FoodScannerNotifier extends StateNotifier<FoodScannerState> {
  FoodScannerNotifier({
    required FoodVisionService visionService,
    required ImageProcessingService imageService,
    required RecommendationSafetyLayer safetyLayer,
    Map<String, double> userHealthMetrics = const {},
    Map<String, double> userGoals = const {},
  })  : _vision = visionService,
        _images = imageService,
        _safety = safetyLayer,
        _userHealthMetrics = userHealthMetrics,
        _userGoals = userGoals,
        super(const FoodScannerInitial());

  final FoodVisionService _vision;
  final ImageProcessingService _images;
  final RecommendationSafetyLayer _safety;
  final Map<String, double> _userHealthMetrics;
  final Map<String, double> _userGoals;

  // ── Step 1: Source selection ────────────────────────────────────────────────

  Future<void> pickFromCamera() async {
    state = const FoodScannerSelectingSource();
    final result = await _images.pickFromCamera();
    await _handlePickResult(result, ImageSource.camera);
  }

  Future<void> pickFromGallery() async {
    state = const FoodScannerSelectingSource();
    final result = await _images.pickFromGallery();
    await _handlePickResult(result, ImageSource.gallery);
  }

  Future<void> _handlePickResult(
    ImagePickResult result,
    ImageSource source,
  ) async {
    if (result.isCancelled) {
      state = const FoodScannerInitial();
      return;
    }

    if (result.isError) {
      state = FoodScannerError(
        type: result.isPermissionDenied
            ? ScannerErrorType.permissionDenied
            : ScannerErrorType.invalidImage,
        userMessage: result.userMessage ??
            'Could not process the selected image.',
      );
      return;
    }

    await _processImage(result.bytes!, source);
  }

  // ── Step 2: Image processing + recognition ─────────────────────────────────

  Future<void> _processImage(Uint8List bytes, ImageSource source) async {
    state = FoodScannerProcessingImage(source: source);

    // Validate
    final validation = _images.validate(bytes);
    if (!validation.isValid) {
      state = FoodScannerError(
        type: ScannerErrorType.invalidImage,
        userMessage: validation.errorMessage ??
            'The image could not be processed.',
      );
      return;
    }

    // Prepare for AI
    final prepared = await _images.prepareForRecognition(bytes);

    // Recognize
    state = FoodScannerRecognizing(imageBytes: bytes, source: source);
    await _runRecognition(prepared, bytes);
  }

  Future<void> _runRecognition(
    Uint8List aiBytes,
    Uint8List displayBytes,
  ) async {
    final result = await _vision.recognize(
      aiBytes,
      options: const RecognitionOptions(
        maxFoods: 8,
        minimumConfidence: 0.30,
        requestQuantityEstimate: true,
      ),
    );

    log.info(
      'FoodScannerNotifier: recognition complete — '
      'status=${result.status.name}, '
      'foods=${result.detectedFoods.length}, '
      'provider=${result.providerName}',
    );

    switch (result.status) {
      case OverallRecognitionStatus.noFoodDetected:
      case OverallRecognitionStatus.imageTooLow:
        state = FoodScannerNoFoodFound(
          imageBytes: displayBytes,
          providerName: result.providerName,
        );

      case OverallRecognitionStatus.failed:
        state = FoodScannerError(
          type: ScannerErrorType.visionProviderError,
          userMessage:
              'Food recognition is temporarily unavailable. '
              'Please try again or add items manually.',
          previousImageBytes: displayBytes,
        );

      case OverallRecognitionStatus.success:
      case OverallRecognitionStatus.partialDetection:
        final hasLow = result.detectedFoods.any((f) => f.isLowConfidence);
        state = FoodScannerDetected(
          imageBytes: displayBytes,
          detectedFoods: result.detectedFoods,
          providerName: result.providerName,
          processingTimeMs: result.processingTimeMs,
          hasLowConfidenceItems: hasLow,
        );
    }
  }

  // ── Step 3: Retry recognition ───────────────────────────────────────────────

  Future<void> retryRecognition() async {
    final currentState = state;
    if (currentState is FoodScannerError &&
        currentState.previousImageBytes != null) {
      final bytes = currentState.previousImageBytes!;
      state = FoodScannerRecognizing(
        imageBytes: bytes,
        source: ImageSource.camera,
      );
      await _runRecognition(bytes, bytes);
    } else {
      reset();
    }
  }

  // ── Step 4: Proceed to confirmation ────────────────────────────────────────

  void proceedToConfirmation(List<DetectedFood> detectedFoods, Uint8List imageBytes) {
    final items = detectedFoods
        .where((f) => f.status.isUsable)
        .map(_toConfirmedItem)
        .toList();

    state = FoodScannerConfirming(
      imageBytes: imageBytes,
      items: items,
    );
  }

  void proceedToConfirmationFromNoFood(Uint8List imageBytes) {
    state = FoodScannerConfirming(
      imageBytes: imageBytes,
      items: const [],
    );
  }

  // ── Step 5: Edit confirmed items ────────────────────────────────────────────

  void updateFoodName(String id, String newName) {
    _mutateItems((items) {
      return items
          .map((item) => item.id == id
              ? ConfirmedFoodItem(
                  id: item.id,
                  name: newName.trim(),
                  quantity: item.quantity,
                  unit: item.unit,
                  servingSizeG: item.servingSizeG,
                  originalDetection: item.originalDetection,
                )
              : item)
          .toList();
    });
  }

  void updateQuantity(String id, double quantity) {
    _mutateItems((items) {
      return items
          .map((item) => item.id == id
              ? ConfirmedFoodItem(
                  id: item.id,
                  name: item.name,
                  quantity: quantity,
                  unit: item.unit,
                  servingSizeG: item.servingSizeG,
                  originalDetection: item.originalDetection,
                )
              : item)
          .toList();
    });
  }

  void updateUnit(String id, ServingUnit unit) {
    _mutateItems((items) {
      return items
          .map((item) => item.id == id
              ? ConfirmedFoodItem(
                  id: item.id,
                  name: item.name,
                  quantity: item.quantity,
                  unit: unit,
                  servingSizeG: item.servingSizeG,
                  originalDetection: item.originalDetection,
                )
              : item)
          .toList();
    });
  }

  void removeFood(String id) {
    _mutateItems((items) => items.where((item) => item.id != id).toList());
  }

  void addFoodManually({
    required String name,
    double quantity = 1.0,
    ServingUnit unit = ServingUnit.servings,
  }) {
    if (name.trim().isEmpty) return;
    final newItem = ConfirmedFoodItem(
      id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      quantity: quantity,
      unit: unit,
    );
    _mutateItems((items) => [...items, newItem]);
  }

  void _mutateItems(List<ConfirmedFoodItem> Function(List<ConfirmedFoodItem>) fn) {
    final currentState = state;
    if (currentState is! FoodScannerConfirming) return;
    state = FoodScannerConfirming(
      imageBytes: currentState.imageBytes,
      items: fn(currentState.items),
    );
  }

  // ── Step 6: Run nutrition pipeline ─────────────────────────────────────────

  Future<void> calculateNutrition() async {
    final currentState = state;
    if (currentState is! FoodScannerConfirming) return;
    if (currentState.items.isEmpty) return;

    final items = currentState.items;
    final imageBytes = currentState.imageBytes;

    state = FoodScannerCalculating(items: items);

    // Convert ConfirmedFoodItems → RawFoodInputs for Phase 12
    final rawInputs = items.map(_toRawFoodInput).toList();

    // Run the Phase 12 safety pipeline
    final result = await _safety.buildContext(
      inputs: rawInputs,
      healthMetrics: _userHealthMetrics,
      userGoals: _userGoals,
    );

    switch (result) {
      case Failure(:final failure):
        log.warning(
          'FoodScannerNotifier: pipeline failure — ${failure.code}',
        );
        state = FoodScannerError(
          type: _mapPipelineFailure(failure),
          userMessage: failure.message,
          previousImageBytes: imageBytes,
          pipelineFailure: failure,
        );

      case Success(:final value):
        final recommendation = _safety.buildRecommendation(
          context: value,
          title: _buildRecommendationTitle(items),
        );

        log.info(
          'FoodScannerNotifier: nutrition pipeline complete — '
          'calories=${value.calculatedNutrition.totalCalories.toStringAsFixed(0)}, '
          'flags=${value.safetyFlags.length}',
        );

        state = FoodScannerResult(
          imageBytes: imageBytes,
          confirmedItems: items,
          mealResult: value.calculatedNutrition,
          recommendation: recommendation,
          context: value,
        );
    }
  }

  // ── Reset ───────────────────────────────────────────────────────────────────

  void reset() {
    state = const FoodScannerInitial();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  ConfirmedFoodItem _toConfirmedItem(DetectedFood food) {
    double? servingSizeG = food.estimatedServingSizeG;

    // For piece-based foods, compute total serving size
    if (food.estimatedUnit == ServingUnit.pieces && servingSizeG != null) {
      servingSizeG = servingSizeG; // per-piece size kept; total = qty × servingSizeG
    }

    return ConfirmedFoodItem(
      id: food.id,
      name: food.name,
      quantity: food.estimatedQuantity,
      unit: food.estimatedUnit,
      servingSizeG: servingSizeG,
      originalDetection: food,
    );
  }

  RawFoodInput _toRawFoodInput(ConfirmedFoodItem item) {
    // Compute serving size for the Phase 12 input
    final double? servingSizeG;

    if (item.servingSizeG != null) {
      servingSizeG = item.servingSizeG;
    } else {
      servingSizeG = item.unit.gramsEquivalent;
      // null is valid for RawFoodInput — validator will use food-DB default
    }

    return RawFoodInput(
      foodName: item.name,
      servingSizeG: servingSizeG,
      quantity: item.quantity,
      unit: item.unit.label,
    );
  }

  ScannerErrorType _mapPipelineFailure(RecommendationFailure failure) =>
      switch (failure) {
        EmptyMealFailure() => ScannerErrorType.invalidImage,
        InvalidInputFailure() => ScannerErrorType.invalidImage,
        AllItemsUnresolvableFailure() => ScannerErrorType.allUnresolvable,
        LowConfidenceFailure() => ScannerErrorType.allLowConfidence,
        UnknownFoodFailure() => ScannerErrorType.allUnresolvable,
        DataSourceUnavailableFailure() => ScannerErrorType.dataUnavailable,
        CalculationFailure() => ScannerErrorType.pipelineFailure,
        AiUnavailableFailure() => ScannerErrorType.visionProviderError,
      };

  String _buildRecommendationTitle(List<ConfirmedFoodItem> items) {
    if (items.length == 1) return '${items.first.name} Nutrition';
    if (items.length <= 3) {
      return items.map((i) => i.name).join(', ');
    }
    return 'Meal Nutrition (${items.length} items)';
  }
}

