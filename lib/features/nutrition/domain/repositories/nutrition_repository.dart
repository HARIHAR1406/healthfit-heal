import '../entities/food_entity.dart';
import '../entities/meal_entity.dart';
import '../entities/nutrition_tracking_entity.dart';

/// Abstract Nutrition repository interface.
///
/// Swap [NutritionMockRepository] for [NutritionRepositoryImpl] when backend
/// is ready. The presentation layer depends only on this interface.
abstract class NutritionRepository {
  // ── Daily Nutrition ────────────────────────────────────────────────────────

  Future<DailyNutritionEntity> getDailyNutrition(DateTime date);

  Future<NutritionGoals> getGoals();

  // ── Meal Planner ──────────────────────────────────────────────────────────

  Future<List<MealEntity>> getMealsForDate(DateTime date);

  Future<void> addFoodToMeal({
    required DateTime date,
    required MealType mealType,
    required FoodEntity food,
    required double servings,
  });

  Future<void> removeFoodFromMeal({
    required DateTime date,
    required MealType mealType,
    required String entryId,
  });

  // ── Food Database ─────────────────────────────────────────────────────────

  Future<List<FoodEntity>> searchFoods(String query);

  Future<List<FoodEntity>> getFoodsByCategory(FoodCategory category);

  Future<List<FoodEntity>> getRecentFoods();

  Future<List<FoodEntity>> getFavoriteFoods();

  Future<FoodEntity?> getFoodById(String id);

  Future<FoodEntity> toggleFoodFavorite(String id);

  // ── Water Tracker ─────────────────────────────────────────────────────────

  Future<WaterTrackerEntity> getWaterTracker(DateTime date);

  Future<void> addWaterIntake(DateTime date, int amountMl);

  Future<void> removeWaterEntry(DateTime date, String entryId);

  // ── Weight Tracker ────────────────────────────────────────────────────────

  Future<WeightTrackerEntity> getWeightTracker();

  Future<void> logWeight(double kg, {String? notes});

  // ── Analytics ─────────────────────────────────────────────────────────────

  Future<NutritionAnalyticsEntity> getAnalytics();
}

