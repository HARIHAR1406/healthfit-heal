import '../../../../features/nutrition/domain/entities/food_entity.dart';
import 'data_source_info.dart';
import 'nutrition_input.dart';
import 'verified_nutrition.dart';

/// The result of calculating nutrition for a single validated food item.
class FoodNutritionResult {
  const FoodNutritionResult({
    required this.input,
    required this.verifiedNutrition,
    required this.calculatedFacts,
    required this.dataSource,
  });

  /// The validated input that produced this result.
  final NutritionInput input;

  /// The verified base nutrition data used for calculation.
  final VerifiedNutrition verifiedNutrition;

  /// The scaled nutrition facts for the actual serving/quantity.
  final NutritionFacts calculatedFacts;

  /// Provenance of the calculation.
  final DataSourceInfo dataSource;

  // ── Convenience accessors ─────────────────────────────────────────────────

  double get calories => calculatedFacts.calories;
  double get proteinG => calculatedFacts.proteinG;
  double get carbsG => calculatedFacts.carbsG;
  double get fatG => calculatedFacts.fatG;
  double get fiberG => calculatedFacts.fiberG;
  double get sugarG => calculatedFacts.sugarG;
  double get sodiumMg => calculatedFacts.sodiumMg;

  String get foodName => input.foodName;
  double get totalGrams => input.totalGrams;
  bool get isTrusted => verifiedNutrition.isTrusted;
}

/// Calculation status for a full meal.
enum MealCalculationStatus {
  /// All foods were verified and calculated successfully.
  complete,

  /// Calculation completed but some foods had missing or low-confidence data.
  partialData,

  /// No foods could be verified — result should not be used for recommendations.
  dataUnavailable,
}

/// The complete result of a multi-food meal nutrition calculation.
///
/// This is the output of [NutritionCalculationEngine.calculateMeal].
///
/// ── Provenance ────────────────────────────────────────────────────────────────
/// Each item in [itemResults] carries its own [DataSourceInfo].
/// The [combinedSource] reflects the lowest-confidence source used.
class MealNutritionResult {
  const MealNutritionResult({
    required this.itemResults,
    required this.totalCalories,
    required this.totalProteinG,
    required this.totalCarbsG,
    required this.totalFatG,
    required this.totalFiberG,
    required this.totalSugarG,
    required this.totalSodiumMg,
    required this.status,
    required this.combinedSource,
    required this.calculatedAt,
    this.unresolvableItems = const [],
  });

  /// Per-food calculation results.
  final List<FoodNutritionResult> itemResults;

  // ── Totals ─────────────────────────────────────────────────────────────────

  final double totalCalories;
  final double totalProteinG;
  final double totalCarbsG;
  final double totalFatG;
  final double totalFiberG;
  final double totalSugarG;
  final double totalSodiumMg;

  /// Overall calculation status.
  final MealCalculationStatus status;

  /// Lowest-confidence data source across all foods in the meal.
  final DataSourceInfo combinedSource;

  /// When this calculation was performed.
  final DateTime calculatedAt;

  /// Food names that could not be resolved to a verified record.
  final List<String> unresolvableItems;

  // ── Derived ────────────────────────────────────────────────────────────────

  /// Whether all items had verified data.
  bool get isComplete => status == MealCalculationStatus.complete;

  /// Whether any items had unresolvable data.
  bool get hasUnresolvableItems => unresolvableItems.isNotEmpty;

  /// The minimum confidence score across all item results.
  double get minimumConfidence => itemResults.isEmpty
      ? 0.0
      : itemResults
          .map((r) => r.dataSource.confidenceScore)
          .reduce((a, b) => a < b ? a : b);

  /// Count of verified food items.
  int get verifiedItemCount =>
      itemResults.where((r) => r.isTrusted).length;

  /// Total items attempted (verified + unresolvable).
  int get totalItemCount =>
      itemResults.length + unresolvableItems.length;

  /// Summary label for UI display.
  String get statusLabel => switch (status) {
        MealCalculationStatus.complete => 'Fully Verified',
        MealCalculationStatus.partialData => 'Partial Data',
        MealCalculationStatus.dataUnavailable => 'Data Unavailable',
      };

  @override
  String toString() =>
      'MealNutritionResult('
      'items=${itemResults.length}, '
      'calories=${totalCalories.toStringAsFixed(0)}, '
      'status=${status.name})';
}

