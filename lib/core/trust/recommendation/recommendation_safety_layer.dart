import '../../utils/app_logger.dart';
import '../calculation/nutrition_calculation_engine.dart';
import '../domain/entities/data_source_info.dart';
import '../domain/entities/meal_nutrition_result.dart';
import '../domain/entities/nutrition_input.dart';
import '../domain/entities/trusted_recommendation.dart';
import '../domain/repositories/trusted_nutrition_repository.dart';
import '../health_rules/health_classification.dart';
import '../health_rules/health_rule_engine.dart';
import '../health_rules/rule_set_registry.dart';
import '../validation/nutrition_input_validator.dart';
import '../validation/nutrition_validation_result.dart';
import 'recommendation_context.dart';
import 'recommendation_failure.dart';

/// The safety gate between raw input and AI recommendation.
///
/// ── Pipeline ──────────────────────────────────────────────────────────────────
///
///   RawFoodInput(s)
///       ↓
///   [1] validateInputs       → reject bad inputs
///       ↓
///   [2] calculateNutrition   → deterministic math on trusted data
///       ↓
///   [3] checkDataQuality     → reject if data unavailable/too low confidence
///       ↓
///   [4] applyHealthRules     → classify health metric values
///       ↓
///   [5] buildContext         → assemble RecommendationContext for AI
///       ↓
///   [6] buildRecommendation  → assemble TrustedRecommendation (no AI yet)
///
/// The AI call is intentionally NOT part of this class — the AI provider
/// receives the [RecommendationContext] and returns an explanation that
/// is attached via [TrustedRecommendation.withAiExplanation].
///
/// ── Failure semantics ─────────────────────────────────────────────────────────
/// All methods return a [Result] union. If any step fails, the pipeline stops
/// and returns the appropriate [RecommendationFailure].
/// The AI is NEVER called on failure.
class RecommendationSafetyLayer {
  RecommendationSafetyLayer({
    required TrustedNutritionRepository repository,
    NutritionCalculationEngine? calculationEngine,
    HealthRuleEngine? ruleEngine,
    NutritionInputValidator? validator,
  })  : _repository = repository,
        _engine = calculationEngine ??
            NutritionCalculationEngine(repository: repository),
        _ruleEngine = ruleEngine ?? const HealthRuleEngine(),
        _validator = validator ?? const NutritionInputValidator();

  final TrustedNutritionRepository _repository;
  final NutritionCalculationEngine _engine;
  final HealthRuleEngine _ruleEngine;
  final NutritionInputValidator _validator;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Validates inputs, calculates nutrition, and assembles a
  /// [RecommendationContext] ready for the AI provider.
  ///
  /// Returns a [Result] — either [Success<RecommendationContext>]
  /// or [Failure<RecommendationFailure>].
  Future<Result<RecommendationContext, RecommendationFailure>> buildContext({
    required List<RawFoodInput> inputs,
    Map<String, double> userGoals = const {},
    Map<String, double> healthMetrics = const {},
  }) async {
    // ── Step 1: Guard empty input ──────────────────────────────────────────
    if (inputs.isEmpty) {
      return Result.failure(const EmptyMealFailure());
    }

    // ── Step 2: Validate inputs ────────────────────────────────────────────
    final batchResult = _validator.validateBatch(inputs);
    if (batchResult.allFailed) {
      final firstError = batchResult.failures.first;
      final criticalMsg = firstError.failure.errors
          .where((e) => e.isCritical)
          .map((e) => e.message)
          .join('; ');
      log.warning(
        'RecommendationSafetyLayer: all inputs failed validation — $criticalMsg',
      );
      return Result.failure(InvalidInputFailure(details: criticalMsg));
    }

    // ── Step 3: Calculate nutrition ────────────────────────────────────────
    final validatedInputs =
        batchResult.successes.map((s) => s.validatedInput).toList();

    MealNutritionResult mealResult;
    try {
      mealResult = await _engine.calculateMeal(validatedInputs);
    } catch (e, st) {
      log.error(
        'RecommendationSafetyLayer: calculation engine threw unexpectedly',
        error: e,
        stackTrace: st,
      );
      return Result.failure(CalculationFailure(details: e.toString()));
    }

    // ── Step 4: Check data quality ────────────────────────────────────────
    if (mealResult.status == MealCalculationStatus.dataUnavailable) {
      log.warning(
        'RecommendationSafetyLayer: all items unresolvable — '
        '${mealResult.unresolvableItems}',
      );
      return Result.failure(
        AllItemsUnresolvableFailure(itemNames: mealResult.unresolvableItems),
      );
    }

    // Low confidence check
    if (mealResult.minimumConfidence < 0.30 && mealResult.itemResults.isNotEmpty) {
      log.warning(
        'RecommendationSafetyLayer: minimum confidence too low '
        '(${(mealResult.minimumConfidence * 100).toStringAsFixed(0)}%)',
      );
      final lowestItem = mealResult.itemResults
          .reduce((a, b) => a.dataSource.confidenceScore < b.dataSource.confidenceScore
              ? a
              : b);
      return Result.failure(LowConfidenceFailure(
        foodName: lowestItem.foodName,
        confidenceScore: lowestItem.dataSource.confidenceScore,
      ));
    }

    // ── Step 5: Apply health rules ─────────────────────────────────────────
    final healthClassifications = <HealthClassification>[];
    for (final entry in healthMetrics.entries) {
      if (RuleSetRegistry.registeredMetrics.contains(entry.key)) {
        healthClassifications.add(
          _ruleEngine.classify(metricType: entry.key, value: entry.value),
        );
      }
    }

    // Also classify nutrition values if they can be mapped
    healthClassifications.addAll(
      _classifyNutritionMetrics(mealResult, userGoals),
    );

    // ── Step 6: Build safety flags ─────────────────────────────────────────
    final safetyFlags = _buildSafetyFlags(
      mealResult: mealResult,
      classifications: healthClassifications,
      failedValidations: batchResult.failures,
    );

    // ── Step 7: Assemble context ───────────────────────────────────────────
    final context = RecommendationContext(
      id: _generateContextId(),
      calculatedNutrition: mealResult,
      healthClassifications: healthClassifications,
      userGoals: userGoals,
      safetyFlags: safetyFlags,
      dataSource: mealResult.combinedSource,
      createdAt: DateTime.now(),
    );

    log.info(
      'RecommendationSafetyLayer: context built — '
      'items=${mealResult.itemResults.length}, '
      'flags=${safetyFlags.length}, '
      'worstLevel=${context.worstHealthLevel.name}',
    );

    return Result.success(context);
  }

  /// Assembles a [TrustedRecommendation] from a [RecommendationContext].
  ///
  /// This is called AFTER [buildContext] succeeds.
  /// The AI explanation is NOT attached here — call
  /// [TrustedRecommendation.withAiExplanation] after the AI call.
  TrustedRecommendation buildRecommendation({
    required RecommendationContext context,
    required String title,
  }) {
    final values = <RecommendationValue>[];

    // Calculated nutrition values
    final calc = context.calculatedNutrition;
    final source = context.dataSource;

    void addCalculated(String label, double value, String unit) {
      values.add(RecommendationValue(
        label: label,
        value: value.toStringAsFixed(1),
        type: RecommendationValueType.calculated,
        source: source,
        unit: unit,
      ));
    }

    addCalculated('Calories', calc.totalCalories, 'kcal');
    addCalculated('Protein', calc.totalProteinG, 'g');
    addCalculated('Carbohydrates', calc.totalCarbsG, 'g');
    addCalculated('Fat', calc.totalFatG, 'g');
    addCalculated('Fiber', calc.totalFiberG, 'g');
    addCalculated('Sodium', calc.totalSodiumMg, 'mg');

    // Health classification values
    for (final c in context.healthClassifications) {
      values.add(RecommendationValue(
        label: _formatMetricLabel(c.metricType),
        value: '${c.value.toStringAsFixed(c.value.truncateToDouble() == c.value ? 0 : 1)} ${c.unit}',
        type: RecommendationValueType.measured,
        source: const DataSourceInfo.calculated(),
        unit: c.unit,
        safetyNote:
            c.level.requiresSafetyNotice ? c.actionGuidance : null,
      ));
    }

    // Safety warnings from critical/highRisk classifications
    final safetyWarnings = context.safetyFlags
        .where((f) => f.level == SafetyFlagLevel.critical ||
            f.level == SafetyFlagLevel.highRisk)
        .map((f) => f.message)
        .toList();

    final disclaimer = context.requiresProfessionalConsultation
        ? '${TrustedRecommendation.kHealthDisclaimer}\n'
            '${TrustedRecommendation.kAiDisclaimer}'
        : TrustedRecommendation.kNutritionDisclaimer;

    return TrustedRecommendation(
      id: 'rec_${context.id}',
      title: title,
      values: values,
      safetyWarnings: safetyWarnings,
      disclaimer: disclaimer,
      generatedAt: DateTime.now(),
      overallSource: context.dataSource,
      requiresProfessionalConsultation: context.requiresProfessionalConsultation,
    );
  }

  // ── Private ────────────────────────────────────────────────────────────────

  List<HealthClassification> _classifyNutritionMetrics(
    MealNutritionResult meal,
    Map<String, double> userGoals,
  ) {
    final classifications = <HealthClassification>[];

    // Only classify if data is sufficiently complete
    if (meal.status == MealCalculationStatus.dataUnavailable) return classifications;

    // Classify sodium if it's meaningful (> 0)
    if (meal.totalSodiumMg > 0) {
      classifications.add(_ruleEngine.classify(
        metricType: RuleSetRegistry.sodiumIntake,
        value: meal.totalSodiumMg,
      ));
    }

    // Classify fiber if it's meaningful
    if (meal.totalFiberG > 0) {
      classifications.add(_ruleEngine.classify(
        metricType: RuleSetRegistry.fiberIntake,
        value: meal.totalFiberG,
      ));
    }

    return classifications;
  }

  List<SafetyFlag> _buildSafetyFlags({
    required MealNutritionResult mealResult,
    required List<HealthClassification> classifications,
    required List<({String foodName, ValidationFailure failure})>
        failedValidations,
  }) {
    final flags = <SafetyFlag>[];

    // Flag critical/highRisk classifications
    for (final c in classifications) {
      if (c.level == HealthLevel.critical) {
        flags.add(SafetyFlag(
          level: SafetyFlagLevel.critical,
          message: '${c.message} ${c.actionGuidance}',
          category: 'health',
        ));
      } else if (c.level == HealthLevel.highRisk) {
        flags.add(SafetyFlag(
          level: SafetyFlagLevel.highRisk,
          message: '${c.message} ${c.actionGuidance}',
          category: 'health',
        ));
      }
    }

    // Flag partial data
    if (mealResult.status == MealCalculationStatus.partialData) {
      flags.add(SafetyFlag(
        level: SafetyFlagLevel.warning,
        message:
            'Some food items could not be verified: '
            '${mealResult.unresolvableItems.join(", ")}. '
            'Nutrition totals are based on verified items only.',
        category: 'nutrition',
      ));
    }

    // Flag failed validations (warnings only — critical ones already rejected)
    for (final f in failedValidations) {
      flags.add(SafetyFlag(
        level: SafetyFlagLevel.warning,
        message: '"${f.foodName}" was excluded: '
            '${f.failure.errors.map((e) => e.message).join("; ")}',
        category: 'validation',
      ));
    }

    return flags;
  }

  String _generateContextId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'ctx_$ts';
  }

  String _formatMetricLabel(String metricType) => switch (metricType) {
        RuleSetRegistry.heartRate => 'Heart Rate',
        RuleSetRegistry.bloodPressureSystolic => 'Systolic BP',
        RuleSetRegistry.bloodPressureDiastolic => 'Diastolic BP',
        RuleSetRegistry.bloodSugarFasting => 'Fasting Blood Sugar',
        RuleSetRegistry.bloodSugarPostMeal => 'Post-Meal Blood Sugar',
        RuleSetRegistry.spo2 => 'Oxygen Saturation',
        RuleSetRegistry.bmi => 'BMI',
        RuleSetRegistry.dailyCalories => 'Daily Calories',
        RuleSetRegistry.sodiumIntake => 'Sodium Intake',
        RuleSetRegistry.fiberIntake => 'Fiber Intake',
        _ => metricType,
      };
}

// ── Result type ────────────────────────────────────────────────────────────────

/// A simple Result union for the safety layer pipeline.
///
/// Either contains a successful [value] or a [failure].
sealed class Result<S, F> {
  const Result();

  factory Result.success(S value) = Success<S, F>;
  factory Result.failure(F failure) = Failure<S, F>;

  bool get isSuccess => this is Success<S, F>;
  bool get isFailure => this is Failure<S, F>;
}

final class Success<S, F> extends Result<S, F> {
  const Success(this.value);
  final S value;
}

final class Failure<S, F> extends Result<S, F> {
  const Failure(this.failure);
  final F failure;
}
