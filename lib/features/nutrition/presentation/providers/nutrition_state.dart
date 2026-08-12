import '../../domain/entities/food_entity.dart';
import '../../domain/entities/meal_entity.dart';
import '../../domain/entities/nutrition_tracking_entity.dart';

// ── Daily Nutrition State ─────────────────────────────────────────────────────

sealed class NutritionState {
  const NutritionState();
}

final class NutritionInitial extends NutritionState {
  const NutritionInitial();
}

final class NutritionLoading extends NutritionState {
  const NutritionLoading();
}

final class NutritionLoaded extends NutritionState {
  const NutritionLoaded({
    required this.daily,
    required this.analytics,
    required this.waterTracker,
    required this.weightTracker,
  });
  final DailyNutritionEntity daily;
  final NutritionAnalyticsEntity analytics;
  final WaterTrackerEntity waterTracker;
  final WeightTrackerEntity weightTracker;
}

final class NutritionRefreshing extends NutritionState {
  const NutritionRefreshing({required this.data});
  final NutritionLoaded data;
}

final class NutritionError extends NutritionState {
  const NutritionError({required this.message});
  final String message;
}

extension NutritionStateX on NutritionState {
  NutritionLoaded? get data => switch (this) {
        NutritionLoaded d => d,
        NutritionRefreshing r => r.data,
        _ => null,
      };
  bool get hasData => data != null;
}

// ── Food Search State ─────────────────────────────────────────────────────────

sealed class FoodSearchState {
  const FoodSearchState();
}

final class FoodSearchIdle extends FoodSearchState {
  const FoodSearchIdle();
}

final class FoodSearchLoading extends FoodSearchState {
  const FoodSearchLoading();
}

final class FoodSearchLoaded extends FoodSearchState {
  const FoodSearchLoaded({required this.results});
  final List<FoodEntity> results;
}

final class FoodSearchError extends FoodSearchState {
  const FoodSearchError({required this.message});
  final String message;
}

// ── Water Tracker State ───────────────────────────────────────────────────────

sealed class WaterState {
  const WaterState();
}

final class WaterLoading extends WaterState {
  const WaterLoading();
}

final class WaterLoaded extends WaterState {
  const WaterLoaded({required this.tracker});
  final WaterTrackerEntity tracker;
}

final class WaterError extends WaterState {
  const WaterError({required this.message});
  final String message;
}

// ── Weight Tracker State ──────────────────────────────────────────────────────

sealed class WeightState {
  const WeightState();
}

final class WeightLoading extends WeightState {
  const WeightLoading();
}

final class WeightLoaded extends WeightState {
  const WeightLoaded({required this.tracker});
  final WeightTrackerEntity tracker;
}

final class WeightError extends WeightState {
  const WeightError({required this.message});
  final String message;
}

// ── Meal Planner State ────────────────────────────────────────────────────────

sealed class MealPlannerState {
  const MealPlannerState();
}

final class MealPlannerLoading extends MealPlannerState {
  const MealPlannerLoading();
}

final class MealPlannerLoaded extends MealPlannerState {
  const MealPlannerLoaded({required this.meals, required this.date});
  final List<MealEntity> meals;
  final DateTime date;
}

final class MealPlannerError extends MealPlannerState {
  const MealPlannerError({required this.message});
  final String message;
}

