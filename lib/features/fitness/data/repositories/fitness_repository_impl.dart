import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/achievement_entity.dart';
import '../../domain/entities/fitness_stats_entity.dart';
import '../../domain/entities/workout_entity.dart';
import '../../domain/repositories/fitness_repository.dart';
import '../datasources/fitness_local_datasource.dart';
import '../datasources/fitness_remote_datasource.dart';
import 'fitness_mock_repository.dart';

class FitnessRepositoryImpl implements FitnessRepository {
  final FitnessLocalDatasource localDatasource;
  final FitnessRemoteDatasource remoteDatasource;

  // We use this just to initialize with fixture data if local storage is completely empty
  final FitnessMockRepository _fallbackMock = FitnessMockRepository();

  FitnessRepositoryImpl({
    required this.localDatasource,
    required this.remoteDatasource,
  });

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'local_user';

  // ── Workout Library ────────────────────────────────────────────────────────

  @override
  Future<List<WorkoutEntity>> getWorkouts() async {
    try {
      // 1. Check local
      var localWorkouts = await localDatasource.getWorkouts();
      if (localWorkouts != null && localWorkouts.isNotEmpty) {
        return localWorkouts;
      }
      
      // 2. Check remote (fallback to mock if remote is empty for demo purposes)
      var remoteWorkouts = await remoteDatasource.getWorkouts();
      if (remoteWorkouts.isEmpty) {
        log.info('Remote workouts empty. Seeding with mock data...');
        remoteWorkouts = await _fallbackMock.getWorkouts();
      }

      // 3. Save to local
      await localDatasource.saveWorkouts(remoteWorkouts);
      return remoteWorkouts;
    } catch (e) {
      log.error('Error fetching workouts: $e');
      return await _fallbackMock.getWorkouts();
    }
  }

  @override
  Future<List<WorkoutEntity>> getWorkoutsByCategory(WorkoutCategory category) async {
    final workouts = await getWorkouts();
    return workouts.where((w) => w.category == category).toList();
  }

  @override
  Future<WorkoutEntity?> getWorkoutById(String id) async {
    final workouts = await getWorkouts();
    try {
      return workouts.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<WorkoutEntity> toggleFavourite(String id) async {
    final workouts = await getWorkouts();
    final idx = workouts.indexWhere((w) => w.id == id);
    if (idx == -1) throw ArgumentError('Workout $id not found');
    
    final updated = workouts[idx].copyWith(
      isFavorite: !workouts[idx].isFavorite,
    );
    workouts[idx] = updated;
    await localDatasource.saveWorkouts(workouts);
    // Note: Favorites are user-specific, so if workouts are global in Firestore, 
    // we would actually store user favorites in a separate collection.
    // For now, local save is sufficient for offline-first behavior.
    return updated;
  }

  // ── History ────────────────────────────────────────────────────────────────

  @override
  Future<List<WorkoutHistoryEntry>> getHistory() async {
    try {
      var localHistory = await localDatasource.getHistory();
      if (localHistory != null && localHistory.isNotEmpty) {
        return localHistory;
      }

      var remoteHistory = await remoteDatasource.getHistory(_uid);
      if (remoteHistory.isEmpty) {
        remoteHistory = await _fallbackMock.getHistory();
      }

      await localDatasource.saveHistory(remoteHistory);
      return remoteHistory;
    } catch (e) {
      log.error('Error fetching history: $e');
      return await _fallbackMock.getHistory();
    }
  }

  @override
  Future<void> logSession(WorkoutHistoryEntry entry) async {
    try {
      await localDatasource.logSession(entry);
      await remoteDatasource.logSession(_uid, entry);
      
      // Update local stats based on the new session
      final stats = await getStats();
      final updatedStats = FitnessStatsEntity(
        totalWorkouts: stats.totalWorkouts + 1,
        totalMinutes: stats.totalMinutes + entry.durationMinutes,
        totalCalories: stats.totalCalories + entry.caloriesBurned,
        currentStreak: stats.currentStreak, // Simplification
        longestStreak: stats.longestStreak,
        weeklyWorkouts: stats.weeklyWorkouts + 1,
        weeklyCalories: stats.weeklyCalories + entry.caloriesBurned,
        weeklyMinutes: stats.weeklyMinutes + entry.durationMinutes,
        weeklyDistance: stats.weeklyDistance,
        weeklyCaloriesData: stats.weeklyCaloriesData,
        weeklyMinutesData: stats.weeklyMinutesData,
        weeklyFrequencyData: stats.weeklyFrequencyData,
        monthlyCaloriesData: stats.monthlyCaloriesData,
      );
      
      await localDatasource.saveStats(updatedStats);
      await remoteDatasource.saveStats(_uid, updatedStats);
    } catch (e) {
      log.error('Error logging session: $e');
    }
  }

  // ── Statistics ─────────────────────────────────────────────────────────────

  @override
  Future<FitnessStatsEntity> getStats() async {
    try {
      var localStats = await localDatasource.getStats();
      if (localStats != null) {
        return localStats;
      }

      var remoteStats = await remoteDatasource.getStats(_uid);
      if (remoteStats == null) {
        remoteStats = await _fallbackMock.getStats();
      }

      await localDatasource.saveStats(remoteStats);
      return remoteStats;
    } catch (e) {
      log.error('Error fetching stats: $e');
      return await _fallbackMock.getStats();
    }
  }

  @override
  Future<DailyActivityEntity> getTodayActivity() async {
    try {
      var localActivity = await localDatasource.getTodayActivity();
      if (localActivity != null && _isToday(localActivity.date)) {
        return localActivity;
      }

      var remoteActivity = await remoteDatasource.getTodayActivity(_uid);
      if (remoteActivity == null || !_isToday(remoteActivity.date)) {
        remoteActivity = await _fallbackMock.getTodayActivity();
      }

      await localDatasource.saveTodayActivity(remoteActivity);
      return remoteActivity;
    } catch (e) {
      log.error('Error fetching today activity: $e');
      return await _fallbackMock.getTodayActivity();
    }
  }
  
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  // ── Achievements ───────────────────────────────────────────────────────────

  @override
  Future<List<AchievementEntity>> getAchievements() async {
    try {
      var localAchievements = await localDatasource.getAchievements();
      if (localAchievements != null && localAchievements.isNotEmpty) {
        return localAchievements;
      }

      var remoteAchievements = await remoteDatasource.getAchievements(_uid);
      if (remoteAchievements.isEmpty) {
        remoteAchievements = await _fallbackMock.getAchievements();
      }

      await localDatasource.saveAchievements(remoteAchievements);
      return remoteAchievements;
    } catch (e) {
      log.error('Error fetching achievements: $e');
      return await _fallbackMock.getAchievements();
    }
  }
}
