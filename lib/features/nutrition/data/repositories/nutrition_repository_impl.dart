import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/food_entity.dart';
import '../../domain/entities/meal_entity.dart';
import '../../domain/entities/nutrition_tracking_entity.dart';
import '../../domain/repositories/nutrition_repository.dart';
import '../datasources/nutrition_local_datasource.dart';
import '../datasources/nutrition_remote_datasource.dart';
import 'nutrition_mock_repository.dart';

class NutritionRepositoryImpl implements NutritionRepository {
  final NutritionLocalDatasource localDatasource;
  final NutritionRemoteDatasource remoteDatasource;

  // We use this just to initialize with fixture data if local storage is completely empty
  final NutritionMockRepository _fallbackMock = NutritionMockRepository();

  NutritionRepositoryImpl({
    required this.localDatasource,
    required this.remoteDatasource,
  });

  String get _uid => firebase_auth.FirebaseAuth.instance.currentUser?.uid ?? 'local_user';
  
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ── Daily Nutrition ────────────────────────────────────────────────────────

  @override
  Future<DailyNutritionEntity> getDailyNutrition(DateTime date) async {
    try {
      var localDaily = await localDatasource.getDailyNutrition(date);
      if (localDaily != null) return localDaily;

      var remoteDaily = await remoteDatasource.getDailyNutrition(_uid, date);
      if (remoteDaily == null) {
        // Create an empty daily template if nothing exists
        final goals = await getGoals();
        final water = await getWaterTracker(date);
        remoteDaily = DailyNutritionEntity(
          date: date,
          meals: MealType.values.map((type) => MealEntity(
            id: 'meal_${date.millisecondsSinceEpoch}_${type.name}',
            type: type,
            entries: const [],
            date: date,
          )).toList(),
          goals: goals,
          waterMl: water.totalMl,
          waterGoalMl: water.goalMl,
        );
      }

      await localDatasource.saveDailyNutrition(date, remoteDaily);
      return remoteDaily;
    } catch (e) {
      log.error('Error fetching daily nutrition: $e');
      return await _fallbackMock.getDailyNutrition(date);
    }
  }

  @override
  Future<NutritionGoals> getGoals() async {
    try {
      var localGoals = await localDatasource.getGoals();
      if (localGoals != null) return localGoals;

      var remoteGoals = await remoteDatasource.getGoals(_uid);
      if (remoteGoals == null) {
        remoteGoals = await _fallbackMock.getGoals();
      }

      await localDatasource.saveGoals(remoteGoals);
      return remoteGoals;
    } catch (e) {
      log.error('Error fetching nutrition goals: $e');
      return await _fallbackMock.getGoals();
    }
  }

  // ── Meal Planner ──────────────────────────────────────────────────────────

  @override
  Future<List<MealEntity>> getMealsForDate(DateTime date) async {
    final daily = await getDailyNutrition(date);
    return daily.meals;
  }

  @override
  Future<void> addFoodToMeal({
    required DateTime date,
    required MealType mealType,
    required FoodEntity food,
    required double servings,
  }) async {
    final daily = await getDailyNutrition(date);
    final meals = List<MealEntity>.from(daily.meals);
    final mealIndex = meals.indexWhere((m) => m.type == mealType);
    if (mealIndex == -1) return;

    final entry = MealFoodEntry(
      id: 'entry_${DateTime.now().millisecondsSinceEpoch}',
      food: food,
      servings: servings,
      loggedAt: DateTime.now(),
    );

    final entries = List<MealFoodEntry>.from(meals[mealIndex].entries)..add(entry);
    
    meals[mealIndex] = MealEntity(
      id: meals[mealIndex].id,
      type: meals[mealIndex].type,
      entries: entries,
      date: date,
    );

    final updatedDaily = DailyNutritionEntity(
      date: daily.date,
      meals: meals,
      goals: daily.goals,
      waterMl: daily.waterMl,
      waterGoalMl: daily.waterGoalMl,
    );

    await localDatasource.saveDailyNutrition(date, updatedDaily);
    await remoteDatasource.saveDailyNutrition(_uid, date, updatedDaily);
  }

  @override
  Future<void> removeFoodFromMeal({
    required DateTime date,
    required MealType mealType,
    required String entryId,
  }) async {
    final daily = await getDailyNutrition(date);
    final meals = List<MealEntity>.from(daily.meals);
    final mealIndex = meals.indexWhere((m) => m.type == mealType);
    if (mealIndex == -1) return;

    final entries = List<MealFoodEntry>.from(meals[mealIndex].entries)
      ..removeWhere((e) => e.id == entryId);
      
    meals[mealIndex] = MealEntity(
      id: meals[mealIndex].id,
      type: meals[mealIndex].type,
      entries: entries,
      date: date,
    );

    final updatedDaily = DailyNutritionEntity(
      date: daily.date,
      meals: meals,
      goals: daily.goals,
      waterMl: daily.waterMl,
      waterGoalMl: daily.waterGoalMl,
    );

    await localDatasource.saveDailyNutrition(date, updatedDaily);
    await remoteDatasource.saveDailyNutrition(_uid, date, updatedDaily);
  }

  // ── Food Database ─────────────────────────────────────────────────────────

  Future<List<FoodEntity>> _getAllFoods() async {
    var localFoods = await localDatasource.getFoods();
    if (localFoods != null && localFoods.isNotEmpty) return localFoods;

    var remoteFoods = await remoteDatasource.getFoods();
    if (remoteFoods.isEmpty) {
      // Use mock to seed the initial database if empty
      // In a real app, this would be a large cloud database or API (like OpenFoodFacts)
      remoteFoods = await _fallbackMock.getFoodsByCategory(FoodCategory.all);
    }

    await localDatasource.saveFoods(remoteFoods);
    return remoteFoods;
  }

  @override
  Future<List<FoodEntity>> searchFoods(String query) async {
    final foods = await _getAllFoods();
    final lowerQuery = query.toLowerCase();
    return foods.where((f) => 
      f.name.toLowerCase().contains(lowerQuery) || 
      f.brand.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  @override
  Future<List<FoodEntity>> getFoodsByCategory(FoodCategory category) async {
    final foods = await _getAllFoods();
    if (category == FoodCategory.all) return foods;
    return foods.where((f) => f.category == category).toList();
  }

  @override
  Future<List<FoodEntity>> getRecentFoods() async {
    final foods = await _getAllFoods();
    return foods.where((f) => f.isRecent).toList();
  }

  @override
  Future<List<FoodEntity>> getFavoriteFoods() async {
    final foods = await _getAllFoods();
    return foods.where((f) => f.isFavorite).toList();
  }

  @override
  Future<FoodEntity?> getFoodById(String id) async {
    final foods = await _getAllFoods();
    try {
      return foods.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<FoodEntity> toggleFoodFavorite(String id) async {
    final foods = await _getAllFoods();
    final idx = foods.indexWhere((f) => f.id == id);
    if (idx == -1) throw ArgumentError('Food $id not found');

    final updated = foods[idx].copyWith(isFavorite: !foods[idx].isFavorite);
    foods[idx] = updated;
    await localDatasource.saveFoods(foods);
    
    // We would also save this to a user-specific 'favorite_foods' collection in Firestore
    
    return updated;
  }

  // ── Water Tracker ─────────────────────────────────────────────────────────

  @override
  Future<WaterTrackerEntity> getWaterTracker(DateTime date) async {
    try {
      var localWater = await localDatasource.getWaterTracker(date);
      if (localWater != null) return localWater;

      var remoteWater = await remoteDatasource.getWaterTracker(_uid, date);
      if (remoteWater == null) {
        final goals = await getGoals();
        remoteWater = WaterTrackerEntity(
          date: date,
          entries: const [],
          goalMl: goals.waterGoalMl,
        );
      }

      await localDatasource.saveWaterTracker(date, remoteWater);
      return remoteWater;
    } catch (e) {
      log.error('Error fetching water tracker: $e');
      return await _fallbackMock.getWaterTracker(date);
    }
  }

  @override
  Future<void> addWaterIntake(DateTime date, int amountMl) async {
    final tracker = await getWaterTracker(date);
    final entries = List<WaterIntakeEntry>.from(tracker.entries);
    entries.add(WaterIntakeEntry(
      id: 'water_${DateTime.now().millisecondsSinceEpoch}',
      amountMl: amountMl,
      loggedAt: DateTime.now(),
    ));

    final updated = WaterTrackerEntity(
      date: tracker.date,
      entries: entries,
      goalMl: tracker.goalMl,
    );

    await localDatasource.saveWaterTracker(date, updated);
    await remoteDatasource.saveWaterTracker(_uid, date, updated);
    
    // Also sync to daily nutrition
    final daily = await getDailyNutrition(date);
    final updatedDaily = DailyNutritionEntity(
      date: daily.date,
      meals: daily.meals,
      goals: daily.goals,
      waterMl: updated.totalMl,
      waterGoalMl: updated.goalMl,
    );
    await localDatasource.saveDailyNutrition(date, updatedDaily);
    await remoteDatasource.saveDailyNutrition(_uid, date, updatedDaily);
  }

  @override
  Future<void> removeWaterEntry(DateTime date, String entryId) async {
    final tracker = await getWaterTracker(date);
    final entries = List<WaterIntakeEntry>.from(tracker.entries)
      ..removeWhere((e) => e.id == entryId);

    final updated = WaterTrackerEntity(
      date: tracker.date,
      entries: entries,
      goalMl: tracker.goalMl,
    );

    await localDatasource.saveWaterTracker(date, updated);
    await remoteDatasource.saveWaterTracker(_uid, date, updated);
    
    // Sync to daily nutrition
    final daily = await getDailyNutrition(date);
    final updatedDaily = DailyNutritionEntity(
      date: daily.date,
      meals: daily.meals,
      goals: daily.goals,
      waterMl: updated.totalMl,
      waterGoalMl: updated.goalMl,
    );
    await localDatasource.saveDailyNutrition(date, updatedDaily);
    await remoteDatasource.saveDailyNutrition(_uid, date, updatedDaily);
  }

  // ── Weight Tracker ────────────────────────────────────────────────────────

  @override
  Future<WeightTrackerEntity> getWeightTracker() async {
    try {
      var localWeight = await localDatasource.getWeightTracker();
      if (localWeight != null) return localWeight;

      var remoteWeight = await remoteDatasource.getWeightTracker(_uid);
      if (remoteWeight == null) {
        remoteWeight = await _fallbackMock.getWeightTracker();
      }

      await localDatasource.saveWeightTracker(remoteWeight);
      return remoteWeight;
    } catch (e) {
      log.error('Error fetching weight tracker: $e');
      return await _fallbackMock.getWeightTracker();
    }
  }

  @override
  Future<void> logWeight(double kg, {String? notes}) async {
    final tracker = await getWeightTracker();
    final entry = WeightEntry(
      id: 'weight_${DateTime.now().millisecondsSinceEpoch}',
      weightKg: kg,
      measuredAt: DateTime.now(),
      notes: notes,
    );
    
    final entries = List<WeightEntry>.from(tracker.entries)..insert(0, entry);
    final updated = WeightTrackerEntity(
      entries: entries,
      goalKg: tracker.goalKg,
      heightCm: tracker.heightCm,
    );
    
    await localDatasource.saveWeightTracker(updated);
    await remoteDatasource.saveWeightTracker(_uid, updated);
  }

  // ── Analytics ─────────────────────────────────────────────────────────────

  @override
  Future<NutritionAnalyticsEntity> getAnalytics() async {
    try {
      var localAnalytics = await localDatasource.getAnalytics();
      if (localAnalytics != null) return localAnalytics;

      var remoteAnalytics = await remoteDatasource.getAnalytics(_uid);
      if (remoteAnalytics == null) {
        remoteAnalytics = await _fallbackMock.getAnalytics();
      }

      await localDatasource.saveAnalytics(remoteAnalytics);
      return remoteAnalytics;
    } catch (e) {
      log.error('Error fetching analytics: $e');
      return await _fallbackMock.getAnalytics();
    }
  }
}
