import '../../utils/app_logger.dart';
import '../domain/entities/data_source_info.dart';
import '../domain/entities/meal_nutrition_result.dart';
import '../domain/entities/nutrition_input.dart';
import '../domain/entities/verified_nutrition.dart';
import '../domain/repositories/trusted_nutrition_repository.dart';
import '../validation/nutrition_input_validator.dart';
import '../validation/nutrition_validation_result.dart';
import 'calculation_result.dart';
import '../../../features/nutrition/domain/entities/food_entity.dart';

/// Deterministic nutrition calculation engine.
///
/// ── Core design principle ─────────────────────────────────────────────────────
/// This class contains ONLY math. No AI, no network calls, no side effects.
/// All inputs must be pre-validated by [NutritionInputValidator].
/// All data must come from [TrustedNutritionRepository].
///
/// Calculation formula:
///   nutrient = (nutritionPer100g.nutrient / 100.0) × totalGrams
///
/// Where:
///   totalGrams = input.servingSizeG × input.quantity
///
/// ── Accuracy note ─────────────────────────────────────────────────────────────
/// All rounding is deferred to the presentation layer.
/// The engine works with full-precision doubles throughout.
///
/// ── Multi-food meals ──────────────────────────────────────────────────────────
/// [calculateMeal] accepts a list of validated inputs and a map of resolved
/// nutrition data. Unresolved foods are tracked separately and do not
/// corrupt the result — the status reflects data completeness.
class NutritionCalculationEngine {
  const NutritionCalculationEngine({
    required TrustedNutritionRepository repository,
    NutritionInputValidator validator = const NutritionInputValidator(),
  })  : _repository = repository,
        _validator = validator;

  final TrustedNutritionRepository _repository;
  final NutritionInputValidator _validator;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Calculates nutrition for a single validated food input.
  ///
  /// Steps:
  ///   1. Resolves the food from the trusted repository (by ID or name search).
  ///   2. Validates the resolved nutrition data.
  ///   3. Applies deterministic scaling: (servingSize × quantity) / 100.
  ///
  /// Returns [SingleFoodCalculationResult.failed] if the food cannot be
  /// resolved or if the nutrition data fails validation.
  Future<SingleFoodCalculationResult> calculateSingle(
    NutritionInput input,
  ) async {
    // Step 1: Resolve trusted nutrition data
    final verified = await _resolve(input);
    if (verified == null) {
      log.warning(
        'NutritionCalculationEngine: could not resolve "${input.foodName}"',
      );
      return SingleFoodCalculationResult.failed(
        foodName: input.foodName,
        requestedGrams: input.totalGrams,
        reason: '"${input.foodName}" could not be found in the trusted database. '
            'Nutrition cannot be calculated.',
      );
    }

    // Step 2: Validate the resolved data (critical nutrition check)
    final validationResult = _validator.validate(
      RawFoodInput(
        foodName: input.foodName,
        servingSizeG: input.servingSizeG,
        quantity: input.quantity,
        unit: input.unit,
        foodId: input.foodId,
      ),
      resolvedFood: verified,
    );

    if (validationResult case ValidationFailure(errors: final errors)) {
      final criticalErrors = errors.where((e) => e.isCritical).toList();
      if (criticalErrors.isNotEmpty) {
        return SingleFoodCalculationResult.failed(
          foodName: input.foodName,
          requestedGrams: input.totalGrams,
          reason: criticalErrors.first.message,
        );
      }
    }

    // Step 3: Calculate — deterministic scaling
    final calculatedFacts = _scale(verified, input.totalGrams);

    final itemResult = FoodNutritionResult(
      input: input,
      verifiedNutrition: verified,
      calculatedFacts: calculatedFacts,
      dataSource: const DataSourceInfo.calculated(),
    );

    log.debug(
      'NutritionCalculationEngine: calculated "${input.foodName}" '
      '(${input.totalGrams}g) → ${calculatedFacts.calories.toStringAsFixed(1)} kcal',
    );

    return SingleFoodCalculationResult.success(
      result: itemResult,
      requestedGrams: input.totalGrams,
    );
  }

  /// Calculates combined nutrition for multiple food inputs in a single meal.
  ///
  /// Steps:
  ///   1. Calculates each food individually using [calculateSingle].
  ///   2. Aggregates totals across all successfully resolved foods.
  ///   3. Tracks unresolvable foods separately.
  ///   4. Sets overall [MealCalculationStatus] based on completeness.
  ///
  /// Guarantees:
  ///   - Never returns fabricated totals for unresolved foods.
  ///   - Unresolved foods are listed in [MealNutritionResult.unresolvableItems].
  ///   - If ALL foods fail, returns [MealCalculationStatus.dataUnavailable].
  Future<MealNutritionResult> calculateMeal(
    List<NutritionInput> inputs,
  ) async {
    final itemResults = <FoodNutritionResult>[];
    final unresolvableItems = <String>[];

    for (final input in inputs) {
      final result = await calculateSingle(input);
      if (result.isSuccess || result.isPartial) {
        itemResults.add(result.result!);
      } else {
        unresolvableItems.add(input.foodName);
        log.warning(
          'NutritionCalculationEngine: unresolvable "${input.foodName}" '
          '— ${result.failureReason}',
        );
      }
    }

    // Aggregate totals from verified items only
    var totalCalories = 0.0;
    var totalProteinG = 0.0;
    var totalCarbsG = 0.0;
    var totalFatG = 0.0;
    var totalFiberG = 0.0;
    var totalSugarG = 0.0;
    var totalSodiumMg = 0.0;

    for (final item in itemResults) {
      totalCalories += item.calories;
      totalProteinG += item.proteinG;
      totalCarbsG += item.carbsG;
      totalFatG += item.fatG;
      totalFiberG += item.fiberG;
      totalSugarG += item.sugarG;
      totalSodiumMg += item.sodiumMg;
    }

    // Determine overall status
    final status = _determineMealStatus(
      resolvedCount: itemResults.length,
      totalCount: inputs.length,
    );

    // Combined source = lowest confidence source used
    final combinedSource = _lowestConfidenceSource(itemResults);

    log.info(
      'NutritionCalculationEngine: meal calculation complete — '
      '${itemResults.length}/${inputs.length} resolved, '
      '${totalCalories.toStringAsFixed(1)} kcal total, '
      'status=${status.name}',
    );

    return MealNutritionResult(
      itemResults: itemResults,
      totalCalories: totalCalories,
      totalProteinG: totalProteinG,
      totalCarbsG: totalCarbsG,
      totalFatG: totalFatG,
      totalFiberG: totalFiberG,
      totalSugarG: totalSugarG,
      totalSodiumMg: totalSodiumMg,
      status: status,
      combinedSource: combinedSource,
      calculatedAt: DateTime.now(),
      unresolvableItems: List.unmodifiable(unresolvableItems),
    );
  }

  // ── Pure math ──────────────────────────────────────────────────────────────

  /// Scales [VerifiedNutrition] to the given [totalGrams].
  ///
  /// Formula: nutrient = nutritionPer100g.nutrient × (totalGrams / 100.0)
  ///
  /// This method is the ONLY place in the codebase that performs this
  /// calculation. All other scaling goes through here.
  static NutritionFacts scaleToGrams(
    NutritionFacts per100g,
    double totalGrams,
  ) {
    assert(totalGrams > 0, 'totalGrams must be positive');
    final factor = totalGrams / 100.0;
    return per100g.scale(factor);
  }

  // ── Private ────────────────────────────────────────────────────────────────

  /// Resolves a [NutritionInput] to [VerifiedNutrition] from the repository.
  Future<VerifiedNutrition?> _resolve(NutritionInput input) async {
    // Prefer ID-based lookup (exact match, fastest)
    if (input.foodId != null) {
      try {
        final byId = await _repository.getById(input.foodId!);
        if (byId != null) return byId;
      } catch (e) {
        log.warning(
          'NutritionCalculationEngine: getById failed for "${input.foodId}"',
          error: e,
        );
      }
    }

    // Barcode lookup for Food Vision integration
    if (input.barcode != null) {
      try {
        final byBarcode = await _repository.getByBarcode(input.barcode!);
        if (byBarcode != null) return byBarcode;
      } catch (e) {
        log.warning(
          'NutritionCalculationEngine: barcode lookup failed "${input.barcode}"',
          error: e,
        );
      }
    }

    // Name-based search (fuzzy, may return multiple results)
    try {
      final results = await _repository.search(input.foodName, limit: 5);
      if (results.isNotEmpty) {
        // Take the best match (first result, ordered by relevance)
        return results.first;
      }
    } catch (e) {
      log.warning(
        'NutritionCalculationEngine: search failed for "${input.foodName}"',
        error: e,
      );
    }

    return null;
  }

  NutritionFacts _scale(VerifiedNutrition verified, double totalGrams) {
    return scaleToGrams(verified.nutritionPer100g, totalGrams);
  }

  MealCalculationStatus _determineMealStatus({
    required int resolvedCount,
    required int totalCount,
  }) {
    if (totalCount == 0) return MealCalculationStatus.dataUnavailable;
    if (resolvedCount == 0) return MealCalculationStatus.dataUnavailable;
    if (resolvedCount == totalCount) return MealCalculationStatus.complete;
    return MealCalculationStatus.partialData;
  }

  DataSourceInfo _lowestConfidenceSource(
    List<FoodNutritionResult> results,
  ) {
    if (results.isEmpty) return const DataSourceInfo.unknown();
    return results
        .map((r) => r.dataSource)
        .reduce((a, b) => a.confidenceScore < b.confidenceScore ? a : b);
  }
}

