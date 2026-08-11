import 'package:flutter_test/flutter_test.dart';
import 'package:healthfit_heal/core/trust/domain/entities/data_source_info.dart';
import 'package:healthfit_heal/core/trust/domain/entities/meal_nutrition_result.dart';
import 'package:healthfit_heal/core/trust/domain/entities/nutrition_input.dart';
import 'package:healthfit_heal/core/trust/domain/entities/verified_nutrition.dart';
import 'package:healthfit_heal/core/trust/domain/repositories/trusted_nutrition_repository.dart';
import 'package:healthfit_heal/core/trust/recommendation/recommendation_context.dart';
import 'package:healthfit_heal/core/trust/recommendation/recommendation_failure.dart';
import 'package:healthfit_heal/core/trust/recommendation/recommendation_safety_layer.dart';
import 'package:healthfit_heal/features/nutrition/domain/entities/food_entity.dart';

// ── Mock Repository ────────────────────────────────────────────────────────────

class _MockRepo implements TrustedNutritionRepository {
  _MockRepo({required this.foods});
  final List<VerifiedNutrition> foods;

  @override
  Future<VerifiedNutrition?> getById(String foodId) async =>
      foods.cast<VerifiedNutrition?>().firstWhere(
            (f) => f!.foodId == foodId,
            orElse: () => null,
          );

  @override
  Future<List<VerifiedNutrition>> search(String query, {int limit = 20}) async {
    final q = query.toLowerCase();
    return foods.where((f) => f.foodName.toLowerCase().contains(q)).toList();
  }

  @override
  Future<VerifiedNutrition?> getByBarcode(String barcode) async => null;

  @override
  Future<List<VerifiedNutrition>> getByCategory(String category,
      {int limit = 50}) async =>
      foods;

  @override
  Future<List<VerifiedNutrition>> getRecentlyAccessed({int limit = 20}) async =>
      foods;

  @override
  Future<void> cache(VerifiedNutrition n) async {}

  @override
  Future<void> clearCache() async {}

  @override
  Future<int> getCachedCount() async => foods.length;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

VerifiedNutrition _food({
  required String id,
  required String name,
  double calories = 100,
  double protein = 10,
  double carbs = 12,
  double fat = 3,
  double confidence = 0.90,
}) {
  return VerifiedNutrition(
    foodId: id,
    foodName: name,
    source: DataSourceInfo(
      sourceType: DataSourceType.appSeedData,
      verificationStatus: VerificationStatus.verified,
      confidenceScore: confidence,
    ),
    nutritionPer100g: NutritionFacts(
      calories: calories,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
    ),
    defaultServingSize: 100,
    defaultServingUnit: 'g',
  );
}

RawFoodInput _raw(String name, {double? serving, double qty = 1.0}) {
  return RawFoodInput(
    foodName: name,
    servingSizeG: serving ?? 100.0,
    quantity: qty,
  );
}

void main() {
  late _MockRepo repo;
  late RecommendationSafetyLayer layer;

  setUp(() {
    repo = _MockRepo(foods: [
      _food(id: 'apple', name: 'Apple', calories: 52, protein: 0.3, carbs: 13.8, fat: 0.2),
      _food(id: 'chicken', name: 'Chicken', calories: 165, protein: 31.0, carbs: 0, fat: 3.6),
    ]);
    layer = RecommendationSafetyLayer(repository: repo);
  });

  // ── Empty input guard ─────────────────────────────────────────────────────

  group('Empty input guard', () {
    test('empty input list → EmptyMealFailure', () async {
      final result = await layer.buildContext(inputs: []);
      expect(result.isFailure, isTrue);
      final f = result as Failure;
      expect(f.failure, isA<EmptyMealFailure>());
    });
  });

  // ── All valid inputs ──────────────────────────────────────────────────────

  group('Valid inputs', () {
    test('single valid food → Success with RecommendationContext', () async {
      final result = await layer.buildContext(
        inputs: [_raw('Apple')],
      );
      expect(result.isSuccess, isTrue);
      final ctx = (result as Success<RecommendationContext, RecommendationFailure>).value;
      expect(ctx.calculatedNutrition.totalCalories, greaterThan(0));
    });

    test('multiple valid foods → combined nutrition', () async {
      final result = await layer.buildContext(
        inputs: [_raw('Apple'), _raw('Chicken')],
      );
      expect(result.isSuccess, isTrue);
      final ctx = (result as Success).value as RecommendationContext;
      expect(ctx.calculatedNutrition.itemResults.length, 2);
      expect(ctx.calculatedNutrition.totalCalories, greaterThan(100));
    });

    test('context has a non-empty id', () async {
      final result = await layer.buildContext(inputs: [_raw('Apple')]);
      final ctx = (result as Success).value as RecommendationContext;
      expect(ctx.id, isNotEmpty);
    });

    test('context.createdAt is recent', () async {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final result = await layer.buildContext(inputs: [_raw('Apple')]);
      final ctx = (result as Success).value as RecommendationContext;
      expect(ctx.createdAt.isAfter(before), isTrue);
    });
  });

  // ── Invalid input rejection ───────────────────────────────────────────────

  group('Invalid input rejection', () {
    test('all null names → InvalidInputFailure', () async {
      final result = await layer.buildContext(
        inputs: [
          const RawFoodInput(foodName: null, servingSizeG: 100, quantity: 1),
          const RawFoodInput(foodName: null, servingSizeG: 100, quantity: 1),
        ],
      );
      expect(result.isFailure, isTrue);
      final f = result as Failure;
      expect(f.failure, isA<InvalidInputFailure>());
    });

    test('all zero servings → InvalidInputFailure', () async {
      final result = await layer.buildContext(
        inputs: [
          const RawFoodInput(foodName: 'Apple', servingSizeG: 0, quantity: 1),
          const RawFoodInput(foodName: 'Chicken', servingSizeG: -1, quantity: 1),
        ],
      );
      expect(result.isFailure, isTrue);
      final f = result as Failure;
      expect(f.failure, isA<InvalidInputFailure>());
    });
  });

  // ── All unresolvable ──────────────────────────────────────────────────────

  group('All items unresolvable', () {
    test('unknown foods only → AllItemsUnresolvableFailure', () async {
      final result = await layer.buildContext(
        inputs: [
          _raw('Unicorn Tears'),
          _raw('Dragon Fruit Supreme XYZ'),
        ],
      );
      expect(result.isFailure, isTrue);
      final f = result as Failure;
      expect(f.failure, isA<AllItemsUnresolvableFailure>());
      final failure = f.failure as AllItemsUnresolvableFailure;
      expect(failure.itemNames.length, 2);
    });
  });

  // ── Health metrics in context ─────────────────────────────────────────────

  group('Health metrics', () {
    test('normal heart rate → no critical flags', () async {
      final result = await layer.buildContext(
        inputs: [_raw('Apple')],
        healthMetrics: {'heartRate': 72},
      );
      expect(result.isSuccess, isTrue);
      final ctx = (result as Success).value as RecommendationContext;
      expect(ctx.hasCriticalFlags, isFalse);
      expect(ctx.healthClassifications.length, greaterThan(0));
    });

    test('critical SpO₂ (89%) → critical flags present', () async {
      final result = await layer.buildContext(
        inputs: [_raw('Apple')],
        healthMetrics: {'spo2': 89},
      );
      expect(result.isSuccess, isTrue);
      final ctx = (result as Success).value as RecommendationContext;
      expect(ctx.hasCriticalFlags, isTrue);
      expect(ctx.requiresProfessionalConsultation, isTrue);
    });

    test('worstHealthLevel reflects classifications', () async {
      final result = await layer.buildContext(
        inputs: [_raw('Apple')],
        healthMetrics: {'bloodPressureSystolic': 185},
      );
      final ctx = (result as Success).value as RecommendationContext;
      expect(ctx.worstHealthLevel, isNot(equals(null)));
    });
  });

  // ── AI prompt context ─────────────────────────────────────────────────────

  group('AI prompt context', () {
    test('buildAiPromptContext returns non-empty string', () async {
      final result = await layer.buildContext(inputs: [_raw('Apple')]);
      final ctx = (result as Success).value as RecommendationContext;
      final prompt = ctx.buildAiPromptContext();
      expect(prompt, isNotEmpty);
    });

    test('prompt contains "Do NOT invent" instruction', () async {
      final result = await layer.buildContext(inputs: [_raw('Apple')]);
      final ctx = (result as Success).value as RecommendationContext;
      final prompt = ctx.buildAiPromptContext();
      expect(prompt.contains('Do NOT invent'), isTrue);
    });

    test('prompt contains verified calorie value', () async {
      final result = await layer.buildContext(inputs: [_raw('Apple')]);
      final ctx = (result as Success).value as RecommendationContext;
      final prompt = ctx.buildAiPromptContext();
      expect(prompt.contains('Calories:'), isTrue);
    });

    test('prompt includes safety flags for critical health', () async {
      final result = await layer.buildContext(
        inputs: [_raw('Apple')],
        healthMetrics: {'spo2': 85},
      );
      final ctx = (result as Success).value as RecommendationContext;
      final prompt = ctx.buildAiPromptContext();
      expect(prompt.contains('SAFETY FLAGS'), isTrue);
    });
  });

  // ── buildRecommendation ───────────────────────────────────────────────────

  group('buildRecommendation', () {
    test('produces TrustedRecommendation with correct title', () async {
      final result = await layer.buildContext(inputs: [_raw('Apple')]);
      final ctx = (result as Success).value as RecommendationContext;
      final rec = layer.buildRecommendation(
        context: ctx,
        title: 'Apple Nutrition Summary',
      );
      expect(rec.title, 'Apple Nutrition Summary');
    });

    test('recommendation has calculated values', () async {
      final result = await layer.buildContext(inputs: [_raw('Apple')]);
      final ctx = (result as Success).value as RecommendationContext;
      final rec = layer.buildRecommendation(context: ctx, title: 'Test');
      expect(rec.calculatedValues.isNotEmpty, isTrue);
    });

    test('aiExplanation is null before AI call', () async {
      final result = await layer.buildContext(inputs: [_raw('Apple')]);
      final ctx = (result as Success).value as RecommendationContext;
      final rec = layer.buildRecommendation(context: ctx, title: 'Test');
      expect(rec.hasAiExplanation, isFalse);
      expect(rec.aiExplanation, isNull);
    });

    test('withAiExplanation attaches explanation', () async {
      final result = await layer.buildContext(inputs: [_raw('Apple')]);
      final ctx = (result as Success).value as RecommendationContext;
      var rec = layer.buildRecommendation(context: ctx, title: 'Test');
      rec = rec.withAiExplanation('Great choice! Apple is rich in fiber.');
      expect(rec.hasAiExplanation, isTrue);
      expect(rec.aiExplanation, contains('fiber'));
    });

    test('disclaimer is non-empty', () async {
      final result = await layer.buildContext(inputs: [_raw('Apple')]);
      final ctx = (result as Success).value as RecommendationContext;
      final rec = layer.buildRecommendation(context: ctx, title: 'Test');
      expect(rec.disclaimer, isNotEmpty);
    });
  });

  // ── Result type ───────────────────────────────────────────────────────────

  group('Result<S,F> type', () {
    test('Result.success isSuccess=true, isFailure=false', () {
      final r = Result<String, String>.success('ok');
      expect(r.isSuccess, isTrue);
      expect(r.isFailure, isFalse);
      expect((r as Success).value, 'ok');
    });

    test('Result.failure isSuccess=false, isFailure=true', () {
      final r = Result<String, String>.failure('error');
      expect(r.isFailure, isTrue);
      expect(r.isSuccess, isFalse);
      expect((r as Failure).failure, 'error');
    });
  });
}
