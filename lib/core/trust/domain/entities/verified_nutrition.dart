import '../../../../features/nutrition/domain/entities/food_entity.dart';
import 'data_source_info.dart';

/// Nutrition facts enriched with provenance and verification metadata.
///
/// Wraps the existing [NutritionFacts] (domain entity) to add:
///   - Source attribution ([DataSourceInfo])
///   - Field-level availability tracking
///   - Potassium / extended micronutrient support (Phase 12 extension)
///
/// The existing [NutritionFacts] and [FoodEntity] are **not modified**.
/// [VerifiedNutrition] is a new layer that decorates them.
///
/// ── Key Design Rule ───────────────────────────────────────────────────────────
/// All numeric values come from the wrapped [NutritionFacts] or are null
/// when unavailable. A null value MUST be surfaced to the user as
/// "not available" — it must NEVER be silently replaced with 0.
class VerifiedNutrition {
  const VerifiedNutrition({
    required this.foodId,
    required this.foodName,
    required this.source,
    required this.nutritionPer100g,
    required this.defaultServingSize,
    required this.defaultServingUnit,
    this.potassiumMg,
    this.availableFields = const {},
  });

  /// ID from the originating food database.
  final String foodId;

  /// Food name as it appears in the trusted source.
  final String foodName;

  /// Provenance of this nutrition data.
  final DataSourceInfo source;

  /// Core nutrition facts per 100 g (from [NutritionFacts]).
  final NutritionFacts nutritionPer100g;

  /// Default serving size in grams/ml.
  final double defaultServingSize;

  /// Unit label (e.g. "g", "ml", "piece").
  final String defaultServingUnit;

  // ── Extended micronutrients (not in existing NutritionFacts) ──────────────

  /// Potassium in mg per 100 g — null if not available.
  final double? potassiumMg;

  /// Set of field names that have confirmed non-null values.
  ///
  /// Used by the validation engine to detect missing fields.
  final Set<String> availableFields;

  // ── Convenience factory ────────────────────────────────────────────────────

  /// Creates [VerifiedNutrition] from an existing [FoodEntity] in the
  /// app seed database with [DataSourceInfo.appSeed] provenance.
  factory VerifiedNutrition.fromFoodEntity(FoodEntity food) {
    final facts = food.nutritionPer100g;
    return VerifiedNutrition(
      foodId: food.id,
      foodName: food.name,
      source: const DataSourceInfo.appSeed(),
      nutritionPer100g: facts,
      defaultServingSize: food.servingSize,
      defaultServingUnit: food.servingUnit,
      availableFields: _computeAvailableFields(facts),
    );
  }

  // ── Derived ────────────────────────────────────────────────────────────────

  /// Returns scaled nutrition for [servings] of the default serving size.
  NutritionFacts nutritionForServings(double servings) {
    final factor = (defaultServingSize * servings) / 100.0;
    return nutritionPer100g.scale(factor);
  }

  /// Whether the data is trustworthy enough for recommendations.
  bool get isTrusted => source.isTrustworthy;

  /// Whether the data has all required macronutrient fields.
  bool get hasCompleteMacros => {
        'calories',
        'proteinG',
        'carbsG',
        'fatG',
      }.every(availableFields.contains);

  /// Whether potassium data is available.
  bool get hasPotassium => potassiumMg != null;

  @override
  String toString() =>
      'VerifiedNutrition(food=$foodName, source=${source.sourceType.name}, '
      'trusted=$isTrusted)';

  // ── Internal ────────────────────────────────────────────────────────────────

  static Set<String> _computeAvailableFields(NutritionFacts facts) {
    final fields = <String>{};
    if (facts.calories > 0) fields.add('calories');
    if (facts.proteinG > 0) fields.add('proteinG');
    if (facts.carbsG > 0) fields.add('carbsG');
    if (facts.fatG > 0) fields.add('fatG');
    if (facts.fiberG > 0) fields.add('fiberG');
    if (facts.sugarG > 0) fields.add('sugarG');
    if (facts.sodiumMg > 0) fields.add('sodiumMg');
    if (facts.saturatedFatG > 0) fields.add('saturatedFatG');
    if (facts.cholesterolMg > 0) fields.add('cholesterolMg');
    if (facts.calcium > 0) fields.add('calcium');
    if (facts.iron > 0) fields.add('iron');
    return Set.unmodifiable(fields);
  }
}

