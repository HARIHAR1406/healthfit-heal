import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_logger.dart';
import '../../data/datasources/nutrition_local_datasource.dart';
import '../../data/datasources/nutrition_remote_datasource.dart';
import '../../data/repositories/nutrition_repository_impl.dart';
import '../../domain/entities/food_entity.dart';
import '../../domain/entities/meal_entity.dart';
import '../../domain/entities/nutrition_tracking_entity.dart';
import '../../domain/repositories/nutrition_repository.dart';
import 'nutrition_state.dart';

// ── Repository Provider ────────────────────────────────────────────────────────

final nutritionLocalDatasourceProvider = Provider<NutritionLocalDatasource>(
  (_) => NutritionLocalDatasource(),
  name: 'nutritionLocalDatasourceProvider',
);

final nutritionRemoteDatasourceProvider = Provider<NutritionRemoteDatasource>(
  (_) => NutritionRemoteDatasource(),
  name: 'nutritionRemoteDatasourceProvider',
);

final nutritionRepositoryProvider = Provider<NutritionRepository>(
  (ref) => NutritionRepositoryImpl(
    localDatasource: ref.watch(nutritionLocalDatasourceProvider),
    remoteDatasource: ref.watch(nutritionRemoteDatasourceProvider),
  ),
  name: 'nutritionRepositoryProvider',
);

// ── Main Nutrition Notifier ────────────────────────────────────────────────────

class NutritionNotifier extends StateNotifier<NutritionState> {
  NutritionNotifier({required NutritionRepository repository})
      : _repo = repository,
        super(const NutritionInitial());

  final NutritionRepository _repo;

  Future<void> load({DateTime? date}) async {
    if (state is NutritionLoaded) return;
    state = const NutritionLoading();
    await _fetch(date: date ?? DateTime.now());
  }

  Future<void> refresh({DateTime? date}) async {
    final current = state.data;
    state = current != null
        ? NutritionRefreshing(data: current)
        : const NutritionLoading();
    await _fetch(date: date ?? DateTime.now());
  }

  Future<void> _fetch({required DateTime date}) async {
    try {
      final dailyFuture = _repo.getDailyNutrition(date);
      final analyticsFuture = _repo.getAnalytics();
      final waterFuture = _repo.getWaterTracker(date);
      final weightFuture = _repo.getWeightTracker();
      final daily = await dailyFuture;
      final analytics = await analyticsFuture;
      final water = await waterFuture;
      final weight = await weightFuture;
      state = NutritionLoaded(
        daily: daily,
        analytics: analytics,
        waterTracker: water,
        weightTracker: weight,
      );
    } catch (e, st) {
      log.error('NutritionNotifier: load failed', error: e, stackTrace: st);
      state = NutritionError(message: 'Failed to load nutrition data.');
    }
  }
}

// ── Meal Planner Notifier ─────────────────────────────────────────────────────

class MealPlannerNotifier extends StateNotifier<MealPlannerState> {
  MealPlannerNotifier({required NutritionRepository repository})
      : _repo = repository,
        super(const MealPlannerLoading()) {
    _load(DateTime.now());
  }

  final NutritionRepository _repo;

  Future<void> _load(DateTime date) async {
    try {
      final meals = await _repo.getMealsForDate(date);
      state = MealPlannerLoaded(meals: meals, date: date);
    } catch (e) {
      state = MealPlannerError(message: e.toString());
    }
  }

  Future<void> changeDate(DateTime date) async {
    state = const MealPlannerLoading();
    await _load(date);
  }

  Future<void> addFoodToMeal({
    required MealType mealType,
    required FoodEntity food,
    required double servings,
  }) async {
    final current = state;
    if (current is! MealPlannerLoaded) return;
    try {
      await _repo.addFoodToMeal(
        date: current.date,
        mealType: mealType,
        food: food,
        servings: servings,
      );
      await _load(current.date);
    } catch (e) {
      log.error('MealPlannerNotifier: addFoodToMeal failed', error: e);
    }
  }

  Future<void> removeFoodFromMeal({
    required MealType mealType,
    required String entryId,
  }) async {
    final current = state;
    if (current is! MealPlannerLoaded) return;
    try {
      await _repo.removeFoodFromMeal(
        date: current.date,
        mealType: mealType,
        entryId: entryId,
      );
      await _load(current.date);
    } catch (e) {
      log.error('MealPlannerNotifier: removeFoodFromMeal failed', error: e);
    }
  }
}

// ── Food Search Notifier ──────────────────────────────────────────────────────

class FoodSearchNotifier extends StateNotifier<FoodSearchState> {
  FoodSearchNotifier({required NutritionRepository repository})
      : _repo = repository,
        super(const FoodSearchIdle());

  final NutritionRepository _repo;

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const FoodSearchIdle();
      return;
    }
    state = const FoodSearchLoading();
    try {
      final results = await _repo.searchFoods(query);
      state = FoodSearchLoaded(results: results);
    } catch (e) {
      state = FoodSearchError(message: e.toString());
    }
  }

  Future<void> loadAll() async {
    state = const FoodSearchLoading();
    try {
      final results = await _repo.searchFoods('');
      state = FoodSearchLoaded(results: results);
    } catch (e) {
      state = FoodSearchError(message: e.toString());
    }
  }

  Future<void> filterByCategory(FoodCategory category) async {
    state = const FoodSearchLoading();
    try {
      final results = await _repo.getFoodsByCategory(category);
      state = FoodSearchLoaded(results: results);
    } catch (e) {
      state = FoodSearchError(message: e.toString());
    }
  }

  Future<void> toggleFavorite(String foodId) async {
    final current = state;
    if (current is! FoodSearchLoaded) return;
    try {
      final updated = await _repo.toggleFoodFavorite(foodId);
      final idx = current.results.indexWhere((f) => f.id == foodId);
      if (idx == -1) return;
      final list = List<FoodEntity>.from(current.results);
      list[idx] = updated;
      state = FoodSearchLoaded(results: list);
    } catch (e) {
      log.error('FoodSearchNotifier: toggleFavorite failed', error: e);
    }
  }
}

// ── Water Tracker Notifier ────────────────────────────────────────────────────

class WaterTrackerNotifier extends StateNotifier<WaterState> {
  WaterTrackerNotifier({required NutritionRepository repository})
      : _repo = repository,
        super(const WaterLoading()) {
    _load(DateTime.now());
  }

  final NutritionRepository _repo;

  Future<void> _load(DateTime date) async {
    try {
      final tracker = await _repo.getWaterTracker(date);
      state = WaterLoaded(tracker: tracker);
    } catch (e) {
      state = WaterError(message: e.toString());
    }
  }

  Future<void> addWater(int amountMl) async {
    if (state is! WaterLoaded) return;
    final date = (state as WaterLoaded).tracker.date;
    try {
      await _repo.addWaterIntake(date, amountMl);
      await _load(date);
    } catch (e) {
      log.error('WaterTrackerNotifier: addWater failed', error: e);
    }
  }

  Future<void> removeEntry(String entryId) async {
    if (state is! WaterLoaded) return;
    final date = (state as WaterLoaded).tracker.date;
    try {
      await _repo.removeWaterEntry(date, entryId);
      await _load(date);
    } catch (e) {
      log.error('WaterTrackerNotifier: removeEntry failed', error: e);
    }
  }
}

// ── Weight Tracker Notifier ───────────────────────────────────────────────────

class WeightTrackerNotifier extends StateNotifier<WeightState> {
  WeightTrackerNotifier({required NutritionRepository repository})
      : _repo = repository,
        super(const WeightLoading()) {
    _load();
  }

  final NutritionRepository _repo;

  Future<void> _load() async {
    try {
      final tracker = await _repo.getWeightTracker();
      state = WeightLoaded(tracker: tracker);
    } catch (e) {
      state = WeightError(message: e.toString());
    }
  }

  Future<void> logWeight(double kg, {String? notes}) async {
    try {
      await _repo.logWeight(kg, notes: notes);
      await _load();
    } catch (e) {
      log.error('WeightTrackerNotifier: logWeight failed', error: e);
    }
  }
}

