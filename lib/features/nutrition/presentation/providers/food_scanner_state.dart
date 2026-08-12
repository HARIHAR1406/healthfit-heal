import 'dart:typed_data';

import '../../../../core/trust/domain/entities/meal_nutrition_result.dart';
import '../../../../core/trust/domain/entities/trusted_recommendation.dart';
import '../../../../core/trust/recommendation/recommendation_context.dart';
import '../../../../core/trust/recommendation/recommendation_failure.dart';
import '../../domain/entities/detected_food.dart';

// ── Food Scanner State Machine ─────────────────────────────────────────────────

/// All possible states of the Food Scanner feature.
///
/// The state machine follows this flow:
///
///   [Initial]
///       ↓ user taps camera/gallery
///   [SelectingSource]
///       ↓ image picked
///   [ProcessingImage]
///       ↓ image validated
///   [Recognizing]
///       ↓ AI returns result
///   [Detected] / [NoFoodFound] / [Error]
///       ↓ user confirms foods
///   [Confirming] (user editing)
///       ↓ user taps "Calculate Nutrition"
///   [Calculating]
///       ↓ pipeline completes
///   [Result] / [Error]
///       ↓ user taps retry → back to [Initial]
///
/// Error can be reached from any step. Retry always returns to [Initial].
sealed class FoodScannerState {
  const FoodScannerState();
}

// ── Step 0: Initial ────────────────────────────────────────────────────────────

/// No scan has been initiated.
final class FoodScannerInitial extends FoodScannerState {
  const FoodScannerInitial();
}

// ── Step 1: Selecting source ───────────────────────────────────────────────────

/// The source picker (camera/gallery) is open or about to open.
final class FoodScannerSelectingSource extends FoodScannerState {
  const FoodScannerSelectingSource();
}

// ── Step 2: Processing image ───────────────────────────────────────────────────

/// An image was selected and is being validated/compressed.
final class FoodScannerProcessingImage extends FoodScannerState {
  const FoodScannerProcessingImage({required this.source});
  final ImageSource source;
}

// ── Step 3: Recognizing ────────────────────────────────────────────────────────

/// The image is being sent to the vision provider.
final class FoodScannerRecognizing extends FoodScannerState {
  const FoodScannerRecognizing({
    required this.imageBytes,
    required this.source,
  });

  /// Raw image bytes for display only (thumbnail preview).
  /// Do NOT pass these to logging.
  final Uint8List imageBytes;
  final ImageSource source;
}

// ── Step 4a: Detection success ─────────────────────────────────────────────────

/// One or more foods were detected. Awaiting user review.
final class FoodScannerDetected extends FoodScannerState {
  const FoodScannerDetected({
    required this.imageBytes,
    required this.detectedFoods,
    required this.providerName,
    required this.processingTimeMs,
    this.hasLowConfidenceItems = false,
  });

  final Uint8List imageBytes;
  final List<DetectedFood> detectedFoods;
  final String providerName;
  final int processingTimeMs;
  final bool hasLowConfidenceItems;
}

// ── Step 4b: No food found ─────────────────────────────────────────────────────

/// The image was valid but no food was detected.
final class FoodScannerNoFoodFound extends FoodScannerState {
  const FoodScannerNoFoodFound({
    required this.imageBytes,
    required this.providerName,
  });

  final Uint8List imageBytes;
  final String providerName;
}

// ── Step 5: User is editing confirmed items ────────────────────────────────────

/// The user is reviewing/editing the confirmed food list.
final class FoodScannerConfirming extends FoodScannerState {
  const FoodScannerConfirming({
    required this.imageBytes,
    required this.items,
    this.pendingAddition,
  });

  final Uint8List imageBytes;
  final List<ConfirmedFoodItem> items;

  /// A food item the user is in the middle of adding manually.
  final ConfirmedFoodItem? pendingAddition;

  bool get hasItems => items.isNotEmpty;
  bool get canProceed => items.isNotEmpty;
}

// ── Step 6: Nutrition calculation ──────────────────────────────────────────────

/// The confirmed foods are being sent through the Phase 12 pipeline.
final class FoodScannerCalculating extends FoodScannerState {
  const FoodScannerCalculating({
    required this.items,
  });

  final List<ConfirmedFoodItem> items;
}

// ── Step 7: Result ─────────────────────────────────────────────────────────────

/// The nutrition pipeline completed. Results are ready to display.
final class FoodScannerResult extends FoodScannerState {
  const FoodScannerResult({
    required this.imageBytes,
    required this.confirmedItems,
    required this.mealResult,
    required this.recommendation,
    required this.context,
  });

  final Uint8List imageBytes;
  final List<ConfirmedFoodItem> confirmedItems;
  final MealNutritionResult mealResult;
  final TrustedRecommendation recommendation;
  final RecommendationContext context;

  bool get hasCriticalFlags => context.hasCriticalFlags;
  bool get requiresProfessionalConsultation =>
      context.requiresProfessionalConsultation;
}

// ── Error state ────────────────────────────────────────────────────────────────

/// Categorized scanner errors with typed recovery actions.
enum ScannerErrorType {
  /// Camera/gallery permission was denied.
  permissionDenied,

  /// The user cancelled without selecting an image.
  cancelled,

  /// The selected image failed validation.
  invalidImage,

  /// Image too large to process.
  imageTooLarge,

  /// No food was detected in the image.
  noFoodDetected,

  /// All detected foods had unacceptably low confidence.
  allLowConfidence,

  /// All confirmed foods were unrecognized by the nutrition DB.
  allUnresolvable,

  /// The nutrition data source was unavailable.
  dataUnavailable,

  /// Network error during recognition.
  networkError,

  /// The AI vision provider failed.
  visionProviderError,

  /// The nutrition pipeline reported a failure.
  pipelineFailure,

  /// An unexpected error occurred.
  unknown,
}

extension ScannerErrorTypeX on ScannerErrorType {
  bool get isRecoverable => this != ScannerErrorType.permissionDenied;

  String get recoveryAction => switch (this) {
        ScannerErrorType.permissionDenied =>
          'Open Settings to allow camera/photo access.',
        ScannerErrorType.cancelled => 'Tap the camera or gallery icon to try again.',
        ScannerErrorType.invalidImage =>
          'Try a different image (JPEG, PNG, or WEBP).',
        ScannerErrorType.imageTooLarge =>
          'Use a smaller image (under 10 MB).',
        ScannerErrorType.noFoodDetected =>
          'Try a clearer photo with the food in frame.',
        ScannerErrorType.allLowConfidence =>
          'Try again with better lighting or a closer shot.',
        ScannerErrorType.allUnresolvable =>
          'Add the food name manually.',
        ScannerErrorType.dataUnavailable =>
          'Check your connection and try again.',
        ScannerErrorType.networkError =>
          'Check your internet connection and try again.',
        ScannerErrorType.visionProviderError =>
          'Try again in a moment.',
        ScannerErrorType.pipelineFailure =>
          'Try again or add the food manually.',
        ScannerErrorType.unknown =>
          'Please try again.',
      };
}

/// An error occurred at any point in the scanner pipeline.
final class FoodScannerError extends FoodScannerState {
  const FoodScannerError({
    required this.type,
    required this.userMessage,
    this.previousImageBytes,
    this.pipelineFailure,
  });

  final ScannerErrorType type;
  final String userMessage;

  /// Image from the failed scan (for retry display). May be null.
  final Uint8List? previousImageBytes;

  /// Underlying pipeline failure, if any.
  final RecommendationFailure? pipelineFailure;

  bool get isPermissionError => type == ScannerErrorType.permissionDenied;
  bool get canRetry => type.isRecoverable;
  String get recoveryAction => type.recoveryAction;
}

// ── Convenience extension ──────────────────────────────────────────────────────

extension FoodScannerStateX on FoodScannerState {
  bool get isInitial => this is FoodScannerInitial;
  bool get isLoading =>
      this is FoodScannerSelectingSource ||
      this is FoodScannerProcessingImage ||
      this is FoodScannerRecognizing ||
      this is FoodScannerCalculating;
  bool get isError => this is FoodScannerError;
  bool get isResult => this is FoodScannerResult;
  bool get showsImage =>
      this is FoodScannerRecognizing ||
      this is FoodScannerDetected ||
      this is FoodScannerNoFoodFound ||
      this is FoodScannerConfirming ||
      this is FoodScannerResult;
}

