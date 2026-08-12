import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/achievement_entity.dart';
import '../../domain/entities/fitness_stats_entity.dart';
import '../../domain/entities/workout_entity.dart';

class FitnessRemoteDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Workouts ──────────────────────────────────────────────────────────────

  /// Gets the global library of workouts.
  Future<List<WorkoutEntity>> getWorkouts() async {
    final snapshot = await _firestore.collection('workouts').get();
    return snapshot.docs.map((doc) => WorkoutEntity.fromMap(doc.data())).toList();
  }

  // ── History ────────────────────────────────────────────────────────────────

  Future<List<WorkoutHistoryEntry>> getHistory(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('workout_history')
        .orderBy('completedAt', descending: true)
        .get();
    
    return snapshot.docs.map((doc) => WorkoutHistoryEntry.fromMap(doc.data())).toList();
  }

  Future<void> logSession(String uid, WorkoutHistoryEntry entry) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('workout_history')
        .doc(entry.id)
        .set(entry.toMap());
  }

  // ── Stats ──────────────────────────────────────────────────────────────────

  Future<FitnessStatsEntity?> getStats(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).collection('fitness_data').doc('stats').get();
    if (doc.exists && doc.data() != null) {
      return FitnessStatsEntity.fromMap(doc.data()!);
    }
    return null;
  }

  Future<void> saveStats(String uid, FitnessStatsEntity stats) async {
    await _firestore.collection('users').doc(uid).collection('fitness_data').doc('stats').set(stats.toMap());
  }

  Future<DailyActivityEntity?> getTodayActivity(String uid) async {
    // Usually daily activity is synced per day, but we can store the latest in a single doc for simplicity.
    final doc = await _firestore.collection('users').doc(uid).collection('fitness_data').doc('today_activity').get();
    if (doc.exists && doc.data() != null) {
      return DailyActivityEntity.fromMap(doc.data()!);
    }
    return null;
  }

  Future<void> saveTodayActivity(String uid, DailyActivityEntity activity) async {
    await _firestore.collection('users').doc(uid).collection('fitness_data').doc('today_activity').set(activity.toMap());
  }

  // ── Achievements ───────────────────────────────────────────────────────────

  Future<List<AchievementEntity>> getAchievements(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).collection('achievements').get();
    return snapshot.docs.map((doc) => AchievementEntity.fromMap(doc.data())).toList();
  }

  Future<void> saveAchievements(String uid, List<AchievementEntity> achievements) async {
    final batch = _firestore.batch();
    final collection = _firestore.collection('users').doc(uid).collection('achievements');
    for (final achievement in achievements) {
      batch.set(collection.doc(achievement.id), achievement.toMap());
    }
    await batch.commit();
  }
}
