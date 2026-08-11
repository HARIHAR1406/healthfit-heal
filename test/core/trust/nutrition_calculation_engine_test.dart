import 'package:flutter_test/flutter_test.dart';
import 'package:healthfit_heal/core/trust/calculation/nutrition_calculation_engine.dart';
import 'package:healthfit_heal/core/trust/domain/entities/data_source_info.dart';
import 'package:healthfit_heal/core/trust/domain/entities/meal_nutrition_result.dart';
import 'package:healthfit_heal/core/trust/domain/entities/nutrition_input.dart';
import 'package:healthfit_heal/core/trust/domain/entities/verified_nutrition.dart';
import 'package:healthfit_heal/core/trust/domain/repositories/trusted_nutrition_repository.dart';
import 'package:healthfit_heal/features/nutrition/domain/entities/food_entity.dart';

// ── Mock Repository ────────────────────────────────────────────────────────────

class _MockNutritionRepository implements TrustedNutritionRepository {
  _MockNutritionRepository(this._foods);

  final List<VerifiedNutrition> _foods;

  @override
  Future<VerifiedNutrition?> getById(String foodId) async =>
      _foods.cast<VerifiedNutrition?>().firstWhere(
            (f) => f!.foodId == foodId,
            orElse: () => null,
          );

  @override
  Future<List<VerifiedNutrition>> search(String query, {int limit = 20}) async {
    final q = query.toLowerCase();
    return _foods
        .where((f) => f.foodName.toLowerCase().contains(q))
        .take(limit)
        .toList();
  }

  @override
  Future<VerifiedNutrition?> getByBarcode(String barcode) async => null;

  @override
  Future<List<VerifiedNutrition>> getByCategory(String category,
      {int limit = 50}) async =>
      _foods.take(limit).toList();

  @override
  Future<List<VerifiedNutrition>> getRecentlyAccessed({int limit = 20}) async =>
      _foods.take(limit).toList();

  @override
  Future<void> cache(VerifiedNutrition nutrition) async {}

  @override
  Future<void> clearCache() async {}

  @override
  Future<int> getCachedCount() async => _foods.length;
}

// ── Test helpers ───────────────────────────────────────────────────────────────

VerifiedNutrition _makeFood({
  required String id,
  required String name,
  required double calories,
  required double protein,
  required double carbs,
  required double fat,
  double fiber = 0,
  double sugar = 0,
  double sodium = 0,
  double servingSize = 100,
}) {
  return VerifiedNutrition(
    foodId: id,
    foodName: name,
    source: const DataSourceInfo.appSeed(),
    nutritionPer100g: NutritionFacts(
      calories: calories,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
      fiberG: fiber,
      sugarG: sugar,
      sodiumMg: sodium,
    ),
    defaultServingSize: servingSize,
    defaultServingUnit: 'g',
  );
}

NutritionInput _makeInput({
  required String name,
  required double servingSize,
  required double quantity,
  String? foodId,
}) {
  return NutritionInput.validated(
    foodName: name,
    servingSizeG: servingSize,
    quantity: quantity,
    foodId: foodId,
  );
}

// ── Test foods ─────────────────────────────────────────────────────────────────

final _apple = _makeFood(
  id: 'fruit_apple',
  name: 'Apple',
  calories: 52,
  protein: 0.3,
  carbs: 13.8,
  fat: 0.2,
  fiber: 2.4,
);

final _egg = _makeFood(
  id: 'protein_egg',
  name: 'Egg',
  calories: 155,
  protein: 12.6,
  carbs: 1.1,
  fat: 10.6,
  servingSize: 50,
);

final _rice = _makeFood(
  id: 'grain_rice',
  name: 'Rice',
  calories: 130,
  protein: 2.7,
  carbs: 28.2,
  fat: 0.3,
  fiber: 0.4,
  servingSize: 200,
);

void main() {
  late _MockNutritionRepository mockRepo;
  late NutritionCalculationEngine engine;

  setUp(() {
    mockRepo = _MockNutritionRepository([_apple, _egg, _rice]);
    engine = NutritionCalculationEngine(repository: mockRepo);
  });

  // ── scaleToGrams (static, pure math) ─────────────────────────────────────

  group('scaleToGrams — static pure math', () {
    test('100 g → same as nutritionPer100g', () {
      final facts = const NutritionFacts(
        calories: 52,
        proteinG: 0.3,
        carbsG: 13.8,
        fatG: 0.2,
      );
      final scaled = NutritionCalculationEngine.scaleToGrams(facts, 100);
      expect(scaled.calories, closeTo(52, 0.001));
      expect(scaled.proteinG, closeTo(0.3, 0.001));
      expect(scaled.carbsG, closeTo(13.8, 0.001));
      expect(scaled.fatG, closeTo(0.2, 0.001));
    });

    test('50 g → half of per100g', () {
      final facts = const NutritionFacts(
        calories: 200,
        proteinG: 10,
        carbsG: 20,
        fatG: 5,
      );
      final scaled = NutritionCalculationEngine.scaleToGrams(facts, 50);
      expect(scaled.calories, closeTo(100, 0.001));
      expect(scaled.proteinG, closeTo(5, 0.001));
    });

    test('200 g → double per100g', () {
      final facts = const NutritionFacts(
        calories: 100,
        proteinG: 5,
        carbsG: 10,
        fatG: 2,
      );
      final scaled = NutritionCalculationEngine.scaleToGrams(facts, 200);
      expect(scaled.calories, closeTo(200, 0.001));
    });

    test('0.5 g → fraction preserved', () {
      final facts = const NutritionFacts(
        calories: 1000,
        proteinG: 100,
        carbsG: 100,
        fatG: 50,
      );
      final scaled = NutritionCalculationEngine.scaleToGrams(facts, 0.5);
      expect(scaled.calories, closeTo(5, 0.001));
    });
  });

  // ── calculateSingle ───────────────────────────────────────────────────────

  group('calculateSingle', () {
    test('apple 1 serving (182 g) → correct calories', () async {
      final input = _makeInput(
        name: 'Apple',
        servingSize: 182,
        quantity: 1,
        foodId: 'fruit_apple',
      );
      final result = await engine.calculateSingle(input);
      expect(result.isSuccess || result.isPartial, isTrue);
      // 52 kcal/100g × 1.82 = 94.64 kcal
      expect(result.result!.calories, closeTo(52 * 1.82, 0.5));
    });

    test('egg × 2 (50 g each = 100 g) → ~155 kcal', () async {
      final input = _makeInput(
        name: 'Egg',
        servingSize: 50,
        quantity: 2,
        foodId: 'protein_egg',
      );
      final result = await engine.calculateSingle(input);
      expect(result.isSuccess || result.isPartial, isTrue);
      // 155 kcal/100g × 100g/100 = 155 kcal
      expect(result.result!.calories, closeTo(155, 0.5));
    });

    test('unknown food → failed result, not exception', () async {
      final input = _makeInput(
        name: 'XYZ Unknown',
        servingSize: 100,
        quantity: 1,
      );
      final result = await engine.calculateSingle(input);
      expect(result.isFailed, isTrue);
      expect(result.failureReason, isNotNull);
      expect(result.result, isNull);
    });

    test('half serving (0.5) → half calories', () async {
      final input = _makeInput(
        name: 'Apple',
        servingSize: 100,
        quantity: 0.5,
        foodId: 'fruit_apple',
      );
      final result = await engine.calculateSingle(input);
      expect(result.isSuccess || result.isPartial, isTrue);
      // 52 kcal/100g × 50g = 26 kcal
      expect(result.result!.calories, closeTo(26, 0.5));
    });
  });

  // ── calculateMeal (multi-food) ─────────────────────────────────────────────

  group('calculateMeal — multi-food', () {
    test('apple × 5 + egg × 2 + rice × 1 → correct total calories', () async {
      final inputs = [
        // Apple × 5: 5 × 182g = 910g → 52/100 × 910 = 473.2 kcal
        _makeInput(name: 'Apple', servingSize: 182, quantity: 5, foodId: 'fruit_apple'),
        // Egg × 2: 2 × 50g = 100g → 155 kcal
        _makeInput(name: 'Egg', servingSize: 50, quantity: 2, foodId: 'protein_egg'),
        // Rice × 1: 200g → 130 kcal/100g × 2 = 260 kcal
        _makeInput(name: 'Rice', servingSize: 200, quantity: 1, foodId: 'grain_rice'),
      ];

      final result = await engine.calculateMeal(inputs);

      // Expected total: 473.2 + 155 + 260 = ~888 kcal
      final expectedCalories = (52 / 100 * 910) + (155 / 100 * 100) + (130 / 100 * 200);
      expect(result.totalCalories, closeTo(expectedCalories, 2.0));
      expect(result.itemResults.length, 3);
      expect(result.status, MealCalculationStatus.complete);
    });

    test('total protein aggregated correctly', () async {
      final inputs = [
        _makeInput(name: 'Apple', servingSize: 100, quantity: 1, foodId: 'fruit_apple'),
        _makeInput(name: 'Egg', servingSize: 50, quantity: 1, foodId: 'protein_egg'),
      ];

      final result = await engine.calculateMeal(inputs);
      // Apple: 0.3 kcal protein, Egg: 12.6/100 × 50 = 6.3 g
      final expectedProtein = 0.3 + (12.6 / 100 * 50);
      expect(result.totalProteinG, closeTo(expectedProtein, 0.1));
    });

    test('all unknown foods → dataUnavailable status', () async {
      final inputs = [
        _makeInput(name: 'Unicorn Salad', servingSize: 100, quantity: 1),
        _makeInput(name: 'Dragon Fruit Supreme', servingSize: 100, quantity: 1),
      ];

      final result = await engine.calculateMeal(inputs);
      expect(result.status, MealCalculationStatus.dataUnavailable);
      expect(result.unresolvableItems.length, 2);
      expect(result.totalCalories, 0);
    });

    test('partial data → partialData status', () async {
      final inputs = [
        _makeInput(name: 'Apple', servingSize: 100, quantity: 1, foodId: 'fruit_apple'),
        _makeInput(name: 'Unknown Food XYZ', servingSize: 100, quantity: 1),
      ];

      final result = await engine.calculateMeal(inputs);
      expect(result.status, MealCalculationStatus.partialData);
      expect(result.itemResults.length, 1); // Only Apple
      expect(result.unresolvableItems.length, 1);
      expect(result.hasUnresolvableItems, isTrue);
    });

    test('single food → complete status', () async {
      final inputs = [
        _makeInput(name: 'Apple', servingSize: 100, quantity: 1, foodId: 'fruit_apple'),
      ];
      final result = await engine.calculateMeal(inputs);
      expect(result.status, MealCalculationStatus.complete);
    });

    test('empty input list → dataUnavailable', () async {
      final result = await engine.calculateMeal([]);
      expect(result.status, MealCalculationStatus.dataUnavailable);
      expect(result.totalCalories, 0);
    });

    test('meal result has correct item count', () async {
      final inputs = [
        _makeInput(name: 'Apple', servingSize: 100, quantity: 1, foodId: 'fruit_apple'),
        _makeInput(name: 'Egg', servingSize: 50, quantity: 2, foodId: 'protein_egg'),
        _makeInput(name: 'Rice', servingSize: 200, quantity: 1, foodId: 'grain_rice'),
      ];
      final result = await engine.calculateMeal(inputs);
      expect(result.totalItemCount, 3);
      expect(result.verifiedItemCount, 3);
    });
  });

  // ── Serving scaling accuracy ──────────────────────────────────────────────

  group('Serving scaling accuracy', () {
    test('10 g of apple → 10% of 100g values', () async {
      final input = _makeInput(
        name: 'Apple',
        servingSize: 10,
        quantity: 1,
        foodId: 'fruit_apple',
      );
      final result = await engine.calculateSingle(input);
      expect(result.result!.calories, closeTo(52 * 0.1, 0.1));
    });

    test('apple 3 × 100 g = 300 g → 3× per100g calories', () async {
      final input = _makeInput(
        name: 'Apple',
        servingSize: 100,
        quantity: 3,
        foodId: 'fruit_apple',
      );
      final result = await engine.calculateSingle(input);
      expect(result.result!.calories, closeTo(52 * 3, 0.1));
    });

    test('minimum valid serving 1 g → tiny non-zero value', () async {
      final input = _makeInput(
        name: 'Egg',
        servingSize: 1,
        quantity: 1,
        foodId: 'protein_egg',
      );
      final result = await engine.calculateSingle(input);
      expect(result.isSuccess || result.isPartial, isTrue);
      expect(result.result!.calories, greaterThan(0));
      expect(result.result!.calories, lessThan(5)); // 155 × 0.01 = 1.55
    });
  });
}
