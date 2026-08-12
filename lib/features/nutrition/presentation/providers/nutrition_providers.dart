import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/food_entity.dart';
import '../../domain/entities/meal_entity.dart';
import '../../domain/entities/nutrition_tracking_entity.dart';
import 'nutrition_notifier.dart';
import 'nutrition_state.dart';

// ── Master Providers ──────────────────────────────────────────────────────────

final nutritionNotifierProvider =
    StateNotifierProvider<NutritionNotifier, NutritionState>(
  (ref) => NutritionNotifier(
    repository: ref.watch(nutritionRepositoryProvider),
  ),
  name: 'nutritionNotifierProvider',
);

// ── Selectors ──────────────────────────────────────────────────────────────────

final nutritionLoadedProvider = Provider<NutritionLoaded?>(
  (ref) => ref.watch(nutritionNotifierProvider).data,
  name: 'nutritionLoadedProvider',
);

final dailyNutritionProvider = Provider<DailyNutritionEntity?>(
  (ref) => ref.watch(nutritionLoadedProvider)?.daily,
  name: 'dailyNutritionProvider',
);

final nutritionGoalsProvider = Provider<NutritionGoals?>(
  (ref) => ref.watch(dailyNutritionProvider)?.goals,
  name: 'nutritionGoalsProvider',
);

final nutritionAnalyticsProvider = Provider<NutritionAnalyticsEntity?>(
  (ref) => ref.watch(nutritionLoadedProvider)?.analytics,
  name: 'nutritionAnalyticsProvider',
);

final waterTrackerFromDashboardProvider = Provider<WaterTrackerEntity?>(
  (ref) => ref.watch(nutritionLoadedProvider)?.waterTracker,
  name: 'waterTrackerFromDashboardProvider',
);

final weightTrackerFromDashboardProvider = Provider<WeightTrackerEntity?>(
  (ref) => ref.watch(nutritionLoadedProvider)?.weightTracker,
  name: 'weightTrackerFromDashboardProvider',
);

// ── Meal Planner ───────────────────────────────────────────────────────────────

final mealPlannerProvider =
    StateNotifierProvider<MealPlannerNotifier, MealPlannerState>(
  (ref) => MealPlannerNotifier(
    repository: ref.watch(nutritionRepositoryProvider),
  ),
  name: 'mealPlannerProvider',
);

/// Today's expanded meal type (for AccordionExpansion).
final expandedMealTypeProvider = StateProvider<MealType?>(
  (_) => MealType.breakfast,
  name: 'expandedMealTypeProvider',
);

// ── Food Database ──────────────────────────────────────────────────────────────

final foodSearchProvider =
    StateNotifierProvider<FoodSearchNotifier, FoodSearchState>(
  (ref) => FoodSearchNotifier(
    repository: ref.watch(nutritionRepositoryProvider),
  ),
  name: 'foodSearchProvider',
);

/// Active food search query string.
final foodSearchQueryProvider = StateProvider<String>(
  (_) => '',
  name: 'foodSearchQueryProvider',
);

/// Active food category filter.
final foodCategoryFilterProvider = StateProvider<FoodCategory>(
  (_) => FoodCategory.all,
  name: 'foodCategoryFilterProvider',
);

/// Food being viewed in detail.
final selectedFoodIdProvider = StateProvider<String?>(
  (_) => null,
  name: 'selectedFoodIdProvider',
);

// ── Water Tracker ─────────────────────────────────────────────────────────────

final waterTrackerProvider =
    StateNotifierProvider<WaterTrackerNotifier, WaterState>(
  (ref) => WaterTrackerNotifier(
    repository: ref.watch(nutritionRepositoryProvider),
  ),
  name: 'waterTrackerProvider',
);

final waterDataProvider = Provider<WaterTrackerEntity?>(
  (ref) {
    final state = ref.watch(waterTrackerProvider);
    return state is WaterLoaded ? state.tracker : null;
  },
  name: 'waterDataProvider',
);

// ── Weight Tracker ────────────────────────────────────────────────────────────

final weightTrackerProvider =
    StateNotifierProvider<WeightTrackerNotifier, WeightState>(
  (ref) => WeightTrackerNotifier(
    repository: ref.watch(nutritionRepositoryProvider),
  ),
  name: 'weightTrackerProvider',
);

final weightDataProvider = Provider<WeightTrackerEntity?>(
  (ref) {
    final state = ref.watch(weightTrackerProvider);
    return state is WeightLoaded ? state.tracker : null;
  },
  name: 'weightDataProvider',
);

// ── Analytics ─────────────────────────────────────────────────────────────────

enum NutritionPeriod { week, month }

final nutritionPeriodProvider = StateProvider<NutritionPeriod>(
  (_) => NutritionPeriod.week,
  name: 'nutritionPeriodProvider',
);

// ── Quick-add water amounts (ml) ──────────────────────────────────────────────

const kWaterQuickAmounts = [150, 200, 250, 350, 500];

