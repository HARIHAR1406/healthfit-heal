import '../domain/entities/meal_nutrition_result.dart';
import '../domain/entities/verified_nutrition.dart';

// ── Single Food ────────────────────────────────────────────────────────────────

/// Status of a single food calculation.
enum SingleCalculationStatus {
  /// Calculation succeeded with full trusted data.
  success,

  /// Calculation succeeded but data is incomplete or low confidence.
  partialData,

  /// Calculation failed — the food could not be resolved.
  failed,
}

/// Result of calculating nutrition for a single food item.
///
/// Always inspect [status] before using [result] — [result] is null
/// when [status] == [SingleCalculationStatus.failed].
class SingleFoodCalculationResult {
  const SingleFoodCalculationResult._({
    required this.foodName,
    required this.requestedGrams,
    required this.status,
    this.result,
    this.failureReason,
  });

  final String foodName;
  final double requestedGrams;
  final SingleCalculationStatus status;

  /// The calculated food result. Null when status is [failed].
  final FoodNutritionResult? result;

  /// Human-readable failure reason. Non-null when status is [failed].
  final String? failureReason;

  bool get isSuccess => status == SingleCalculationStatus.success;
  bool get isPartial => status == SingleCalculationStatus.partialData;
  bool get isFailed => status == SingleCalculationStatus.failed;

  factory SingleFoodCalculationResult.success({
    required FoodNutritionResult result,
    required double requestedGrams,
  }) =>
      SingleFoodCalculationResult._(
        foodName: result.foodName,
        requestedGrams: requestedGrams,
        status: result.verifiedNutrition.source.isHighConfidence
            ? SingleCalculationStatus.success
            : SingleCalculationStatus.partialData,
        result: result,
      );

  factory SingleFoodCalculationResult.failed({
    required String foodName,
    required double requestedGrams,
    required String reason,
  }) =>
      SingleFoodCalculationResult._(
        foodName: foodName,
        requestedGrams: requestedGrams,
        status: SingleCalculationStatus.failed,
        failureReason: reason,
      );
}



