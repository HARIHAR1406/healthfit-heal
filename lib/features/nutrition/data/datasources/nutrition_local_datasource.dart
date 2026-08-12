import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/storage/hive_service.dart';
import '../../domain/entities/food_entity.dart';
import '../../domain/entities/meal_entity.dart';
import '../../domain/entities/nutrition_tracking_entity.dart';

class NutritionLocalDatasource {
  Box<String> get _box => HiveService.instance.nutritionBox;

  String _dateKey(DateTime date) => 'daily_${date.year}_${date.month}_${date.day}';
  String _waterKey(DateTime date) => 'water_${date.year}_${date.month}_${date.day}';

  // ── Daily Nutrition ────────────────────────────────────────────────────────

  Future<void> saveDailyNutrition(DateTime date, DailyNutritionEntity entity) async {
    await _box.put(_dateKey(date), jsonEncode(entity.toMap()));
  }

  Future<DailyNutritionEntity?> getDailyNutrition(DateTime date) async {
    final str = _box.get(_dateKey(date));
    if (str == null) return null;
    try {
      final map = jsonDecode(str) as Map<String, dynamic>;
      return DailyNutritionEntity.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveGoals(NutritionGoals goals) async {
    await _box.put('goals', jsonEncode(goals.toMap()));
  }

  Future<NutritionGoals?> getGoals() async {
    final str = _box.get('goals');
    if (str == null) return null;
    try {
      final map = jsonDecode(str) as Map<String, dynamic>;
      return NutritionGoals.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  // ── Food Database ─────────────────────────────────────────────────────────

  Future<void> saveFoods(List<FoodEntity> foods) async {
    final list = foods.map((e) => e.toMap()).toList();
    await _box.put('foods', jsonEncode(list));
  }

  Future<List<FoodEntity>?> getFoods() async {
    final str = _box.get('foods');
    if (str == null) return null;
    try {
      final List<dynamic> list = jsonDecode(str) as List<dynamic>;
      return list.map((e) => FoodEntity.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }
  
  // ── Water Tracker ─────────────────────────────────────────────────────────

  Future<void> saveWaterTracker(DateTime date, WaterTrackerEntity entity) async {
    await _box.put(_waterKey(date), jsonEncode(entity.toMap()));
  }

  Future<WaterTrackerEntity?> getWaterTracker(DateTime date) async {
    final str = _box.get(_waterKey(date));
    if (str == null) return null;
    try {
      final map = jsonDecode(str) as Map<String, dynamic>;
      return WaterTrackerEntity.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  // ── Weight Tracker ────────────────────────────────────────────────────────

  Future<void> saveWeightTracker(WeightTrackerEntity entity) async {
    await _box.put('weight_tracker', jsonEncode(entity.toMap()));
  }

  Future<WeightTrackerEntity?> getWeightTracker() async {
    final str = _box.get('weight_tracker');
    if (str == null) return null;
    try {
      final map = jsonDecode(str) as Map<String, dynamic>;
      return WeightTrackerEntity.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  // ── Analytics ─────────────────────────────────────────────────────────────

  Future<void> saveAnalytics(NutritionAnalyticsEntity entity) async {
    await _box.put('analytics', jsonEncode(entity.toMap()));
  }

  Future<NutritionAnalyticsEntity?> getAnalytics() async {
    final str = _box.get('analytics');
    if (str == null) return null;
    try {
      final map = jsonDecode(str) as Map<String, dynamic>;
      return NutritionAnalyticsEntity.fromMap(map);
    } catch (_) {
      return null;
    }
  }
}
