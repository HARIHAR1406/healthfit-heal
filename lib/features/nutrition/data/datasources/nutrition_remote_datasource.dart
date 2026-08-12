import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/food_entity.dart';
import '../../domain/entities/meal_entity.dart';
import '../../domain/entities/nutrition_tracking_entity.dart';

class NutritionRemoteDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _dateKey(DateTime date) => 'daily_${date.year}_${date.month}_${date.day}';
  String _waterKey(DateTime date) => 'water_${date.year}_${date.month}_${date.day}';

  // ── Daily Nutrition ────────────────────────────────────────────────────────

  Future<void> saveDailyNutrition(String uid, DateTime date, DailyNutritionEntity entity) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('nutrition_daily')
        .doc(_dateKey(date))
        .set(entity.toMap());
  }

  Future<DailyNutritionEntity?> getDailyNutrition(String uid, DateTime date) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('nutrition_daily')
        .doc(_dateKey(date))
        .get();
        
    if (doc.exists && doc.data() != null) {
      return DailyNutritionEntity.fromMap(doc.data()!);
    }
    return null;
  }

  Future<void> saveGoals(String uid, NutritionGoals goals) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('nutrition_data')
        .doc('goals')
        .set(goals.toMap());
  }

  Future<NutritionGoals?> getGoals(String uid) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('nutrition_data')
        .doc('goals')
        .get();
        
    if (doc.exists && doc.data() != null) {
      return NutritionGoals.fromMap(doc.data()!);
    }
    return null;
  }

  // ── Food Database ─────────────────────────────────────────────────────────

  Future<List<FoodEntity>> getFoods() async {
    final snapshot = await _firestore.collection('foods').get();
    return snapshot.docs.map((doc) => FoodEntity.fromMap(doc.data())).toList();
  }
  
  // ── Water Tracker ─────────────────────────────────────────────────────────

  Future<void> saveWaterTracker(String uid, DateTime date, WaterTrackerEntity entity) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('water_daily')
        .doc(_waterKey(date))
        .set(entity.toMap());
  }

  Future<WaterTrackerEntity?> getWaterTracker(String uid, DateTime date) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('water_daily')
        .doc(_waterKey(date))
        .get();
        
    if (doc.exists && doc.data() != null) {
      return WaterTrackerEntity.fromMap(doc.data()!);
    }
    return null;
  }

  // ── Weight Tracker ────────────────────────────────────────────────────────

  Future<void> saveWeightTracker(String uid, WeightTrackerEntity entity) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('nutrition_data')
        .doc('weight_tracker')
        .set(entity.toMap());
  }

  Future<WeightTrackerEntity?> getWeightTracker(String uid) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('nutrition_data')
        .doc('weight_tracker')
        .get();
        
    if (doc.exists && doc.data() != null) {
      return WeightTrackerEntity.fromMap(doc.data()!);
    }
    return null;
  }

  // ── Analytics ─────────────────────────────────────────────────────────────

  Future<void> saveAnalytics(String uid, NutritionAnalyticsEntity entity) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('nutrition_data')
        .doc('analytics')
        .set(entity.toMap());
  }

  Future<NutritionAnalyticsEntity?> getAnalytics(String uid) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('nutrition_data')
        .doc('analytics')
        .get();
        
    if (doc.exists && doc.data() != null) {
      return NutritionAnalyticsEntity.fromMap(doc.data()!);
    }
    return null;
  }
}
