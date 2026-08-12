import '../domain/entities/data_source_info.dart';
import '../domain/entities/meal_nutrition_result.dart';
import '../health_rules/health_classification.dart';

/// The verified context that is passed to the AI model.
///
/// This is assembled by [RecommendationSafetyLayer] from:
///   1. The [MealNutritionResult] from the calculation engine
///   2. The health rule classifications from [HealthRuleEngine]
///   3. The user's personal nutrition goals (if available)
///
/// ── What the AI receives ──────────────────────────────────────────────────────
/// The AI prompt must be constructed from this context object.
/// The AI should EXPLAIN these values, NOT invent new ones.
///
/// The context distinguishes between:
///   - [calculatedNutrition] — math on verified data
///   - [healthClassifications] — rule-engine outputs
///   - [userGoals] — personalized targets
///   - [safetyFlags] — items requiring special AI handling
///
/// ── What the AI must NOT do ───────────────────────────────────────────────────
/// The AI prompt should explicitly state:
///   "Do not invent nutrition values. Use only the verified values provided."
///   "Do not make medical diagnoses."
///   "Clearly label any general wellness suggestions."
class RecommendationContext {
  const RecommendationContext({
    required this.id,
    required this.calculatedNutrition,
    required this.healthClassifications,
    required this.userGoals,
    required this.safetyFlags,
    required this.dataSource,
    required this.createdAt,
  });

  /// Unique context ID (for logging / correlation with AI call).
  final String id;

  /// The verified, calculated meal nutrition.
  final MealNutritionResult calculatedNutrition;

  /// Health rule classifications for the metrics in this context.
  final List<HealthClassification> healthClassifications;

  /// The user's personal nutrition goals (may be empty if not set).
  final Map<String, double> userGoals;

  /// Items that require special handling in the AI prompt.
  final List<SafetyFlag> safetyFlags;

  /// The lowest-confidence data source used in this context.
  final DataSourceInfo dataSource;

  /// When this context was assembled.
  final DateTime createdAt;

  // ── Derived ────────────────────────────────────────────────────────────────

  bool get hasCriticalFlags =>
      safetyFlags.any((f) => f.level == SafetyFlagLevel.critical);

  bool get hasHighRiskFlags =>
      safetyFlags.any((f) => f.level == SafetyFlagLevel.highRisk);

  bool get requiresProfessionalConsultation =>
      healthClassifications.any((c) => c.requiresProfessionalConsultation);

  bool get isHighConfidence => dataSource.isHighConfidence;

  /// The worst-case health level across all classifications.
  HealthLevel get worstHealthLevel {
    if (healthClassifications.isEmpty) return HealthLevel.normal;
    const order = [
      HealthLevel.critical,
      HealthLevel.highRisk,
      HealthLevel.needsAttention,
      HealthLevel.normal,
    ];
    for (final level in order) {
      if (healthClassifications.any((c) => c.level == level)) return level;
    }
    return HealthLevel.normal;
  }

  /// Builds the structured prompt context for the AI.
  ///
  /// Returns a structured text block that the AI provider should include
  /// in its system or user message.
  String buildAiPromptContext() {
    final buffer = StringBuffer();
    buffer.writeln('=== VERIFIED NUTRITION CONTEXT ===');
    buffer.writeln(
      'IMPORTANT: Use ONLY the values below. '
      'Do NOT invent or estimate any nutrition values.',
    );
    buffer.writeln();

    buffer.writeln('MEAL NUTRITION (Calculated from verified database):');
    buffer.writeln(
      '  Calories: ${calculatedNutrition.totalCalories.toStringAsFixed(1)} kcal',
    );
    buffer.writeln(
      '  Protein: ${calculatedNutrition.totalProteinG.toStringAsFixed(1)} g',
    );
    buffer.writeln(
      '  Carbohydrates: ${calculatedNutrition.totalCarbsG.toStringAsFixed(1)} g',
    );
    buffer.writeln('  Fat: ${calculatedNutrition.totalFatG.toStringAsFixed(1)} g');
    buffer.writeln(
      '  Fiber: ${calculatedNutrition.totalFiberG.toStringAsFixed(1)} g',
    );
    buffer.writeln(
      '  Sodium: ${calculatedNutrition.totalSodiumMg.toStringAsFixed(0)} mg',
    );
    buffer.writeln(
      '  Data completeness: ${calculatedNutrition.statusLabel}',
    );
    if (calculatedNutrition.hasUnresolvableItems) {
      buffer.writeln(
        '  NOTE: The following items could not be verified: '
        '${calculatedNutrition.unresolvableItems.join(", ")}',
      );
    }

    if (userGoals.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('USER NUTRITION GOALS:');
      for (final entry in userGoals.entries) {
        buffer.writeln('  ${entry.key}: ${entry.value}');
      }
    }

    if (healthClassifications.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('HEALTH CLASSIFICATIONS (from rule engine):');
      for (final c in healthClassifications) {
        buffer.writeln(
          '  ${c.metricType}: ${c.value} ${c.unit} → ${c.level.label}',
        );
        buffer.writeln('    ${c.message}');
      }
    }

    if (safetyFlags.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('SAFETY FLAGS (must mention in response):');
      for (final f in safetyFlags) {
        buffer.writeln('  [${f.level.name.toUpperCase()}] ${f.message}');
      }
    }

    buffer.writeln();
    buffer.writeln('=== END CONTEXT ===');
    buffer.writeln(
      'RESPONSE RULES: '
      '(1) Only cite values from the context above. '
      '(2) Do not diagnose conditions. '
      '(3) Clearly distinguish facts from wellness suggestions. '
      '(4) If safety flags are CRITICAL, advise professional consultation.',
    );

    return buffer.toString();
  }

  @override
  String toString() =>
      'RecommendationContext('
      'id=$id, '
      'calories=${calculatedNutrition.totalCalories.toStringAsFixed(0)}, '
      'flags=${safetyFlags.length}, '
      'worstLevel=${worstHealthLevel.name})';
}

// ── Safety Flags ───────────────────────────────────────────────────────────────

/// Severity of a safety flag.
enum SafetyFlagLevel { info, warning, highRisk, critical }

/// A safety flag that must be communicated in the AI recommendation.
class SafetyFlag {
  const SafetyFlag({
    required this.level,
    required this.message,
    this.category,
  });

  final SafetyFlagLevel level;
  final String message;

  /// Category for analytics (e.g. 'nutrition', 'health', 'diet').
  final String? category;

  bool get isCritical => level == SafetyFlagLevel.critical;
}

