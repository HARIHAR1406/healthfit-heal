/// Typed failures from the recommendation safety layer.
///
/// These map to user-facing error messages. The AI must NOT be called
/// if any of these failures is present.
///
/// ── Design note ───────────────────────────────────────────────────────────────
/// This is a sealed class — every caller must handle every case.
/// Adding a new failure type requires updating all switch expressions.
sealed class RecommendationFailure {
  const RecommendationFailure({required this.message, required this.code});

  /// User-facing message (safe to display in UI).
  final String message;

  /// Internal error code for logging and analytics.
  final String code;
}

/// The food or health item could not be found in the trusted database.
final class UnknownFoodFailure extends RecommendationFailure {
  const UnknownFoodFailure({required this.foodName})
      : super(
          message: '"$foodName" could not be found in our nutrition database. '
              'Nutrition information cannot be verified for this item.',
          code: 'UNKNOWN_FOOD',
        );

  final String foodName;
}

/// Nutrition data was found but confidence is too low for a recommendation.
final class LowConfidenceFailure extends RecommendationFailure {
  const LowConfidenceFailure({
    required this.foodName,
    required this.confidenceScore,
  }) : super(
          message: 'Nutrition data for "$foodName" has low confidence '
              '(${(confidenceScore * 100).toStringAsFixed(0)}%). '
              'A reliable recommendation cannot be generated.',
          code: 'LOW_CONFIDENCE',
        );

  final String foodName;
  final double confidenceScore;
}

/// The food/metric input failed validation.
final class InvalidInputFailure extends RecommendationFailure {
  const InvalidInputFailure({required String details})
      : super(
          message: 'The input contains invalid values: $details',
          code: 'INVALID_INPUT',
        );
}

/// The trusted data source was unavailable (network or cache miss).
final class DataSourceUnavailableFailure extends RecommendationFailure {
  const DataSourceUnavailableFailure({String? details})
      : super(
          message: details != null
              ? 'Nutrition data is temporarily unavailable: $details'
              : 'Nutrition information could not be verified. '
                  'Please check your connection or try again later.',
          code: 'DATA_SOURCE_UNAVAILABLE',
        );
}

/// No foods could be calculated (all items unresolvable).
final class AllItemsUnresolvableFailure extends RecommendationFailure {
  const AllItemsUnresolvableFailure({required this.itemNames})
      : super(
          message: 'None of the food items could be found in the nutrition database: '
              '${itemNames.join(", ")}. '
              'Nutrition cannot be calculated.',
          code: 'ALL_ITEMS_UNRESOLVABLE',
        );

  final List<String> itemNames;
}

/// The AI model is not available or encountered an error.
final class AiUnavailableFailure extends RecommendationFailure {
  const AiUnavailableFailure({String? details})
      : super(
          message: details != null
              ? 'AI explanation is temporarily unavailable: $details'
              : 'AI explanation is temporarily unavailable. '
                  'Verified nutrition data is still shown above.',
          code: 'AI_UNAVAILABLE',
        );
}

/// The calculation failed unexpectedly.
final class CalculationFailure extends RecommendationFailure {
  const CalculationFailure({required String details})
      : super(
          message: 'An error occurred during nutrition calculation: $details',
          code: 'CALCULATION_ERROR',
        );
}

/// The request was blocked because the input is a zero-quantity meal.
final class EmptyMealFailure extends RecommendationFailure {
  const EmptyMealFailure()
      : super(
          message: 'No food items were provided. '
              'Add at least one food item to get a nutrition summary.',
          code: 'EMPTY_MEAL',
        );
}

