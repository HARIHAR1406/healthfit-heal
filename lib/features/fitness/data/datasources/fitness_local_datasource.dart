import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/hive_service.dart';
import '../../domain/entities/achievement_entity.dart';
import '../../domain/entities/fitness_stats_entity.dart';
import '../../domain/entities/workout_entity.dart';

class FitnessLocalDatasource {
  Box<String> get _box => HiveService.instance.fitnessBox;

  // ── Workouts ──────────────────────────────────────────────────────────────

  Future<void> saveWorkouts(List<WorkoutEntity> workouts) async {
    final list = workouts.map((e) => e.toMap()).toList();
    await _box.put('workouts', jsonEncode(list));
  }

  Future<List<WorkoutEntity>?> getWorkouts() async {
    final str = _box.get('workouts');
    if (str == null) return null;
    try {
      final List<dynamic> list = jsonDecode(str) as List<dynamic>;
      return list.map((e) => WorkoutEntity.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  // ── History ────────────────────────────────────────────────────────────────

  Future<void> saveHistory(List<WorkoutHistoryEntry> history) async {
    final list = history.map((e) => e.toMap()).toList();
    await _box.put('history', jsonEncode(list));
  }

  Future<List<WorkoutHistoryEntry>?> getHistory() async {
    final str = _box.get('history');
    if (str == null) return null;
    try {
      final List<dynamic> list = jsonDecode(str) as List<dynamic>;
      return list.map((e) => WorkoutHistoryEntry.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> logSession(WorkoutHistoryEntry entry) async {
    final current = await getHistory() ?? [];
    current.insert(0, entry);
    await saveHistory(current);
  }

  // ── Stats ──────────────────────────────────────────────────────────────────

  Future<void> saveStats(FitnessStatsEntity stats) async {
    await _box.put('stats', jsonEncode(stats.toMap()));
  }

  Future<FitnessStatsEntity?> getStats() async {
    final str = _box.get('stats');
    if (str == null) return null;
    try {
      final map = jsonDecode(str) as Map<String, dynamic>;
      return FitnessStatsEntity.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTodayActivity(DailyActivityEntity activity) async {
    await _box.put('todayActivity', jsonEncode(activity.toMap()));
  }

  Future<DailyActivityEntity?> getTodayActivity() async {
    final str = _box.get('todayActivity');
    if (str == null) return null;
    try {
      final map = jsonDecode(str) as Map<String, dynamic>;
      return DailyActivityEntity.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  // ── Achievements ───────────────────────────────────────────────────────────

  Future<void> saveAchievements(List<AchievementEntity> achievements) async {
    final list = achievements.map((e) => e.toMap()).toList();
    await _box.put('achievements', jsonEncode(list));
  }

  Future<List<AchievementEntity>?> getAchievements() async {
    final str = _box.get('achievements');
    if (str == null) return null;
    try {
      final List<dynamic> list = jsonDecode(str) as List<dynamic>;
      return list.map((e) => AchievementEntity.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }
}
