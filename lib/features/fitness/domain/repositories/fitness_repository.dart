import '../entities/achievement_entity.dart';
import '../entities/fitness_stats_entity.dart';
import '../entities/workout_entity.dart';

/// Abstract Fitness repository interface.
///
/// Swap [FitnessMockRepository] → [FitnessRepositoryImpl] (Dio-backed) when
/// the backend is ready. The presentation layer only depends on this interface.
abstract class FitnessRepository {
  // ── Workout Library ────────────────────────────────────────────────────────

  /// Returns the full workout library.
  Future<List<WorkoutEntity>> getWorkouts();

  /// Returns workouts filtered by [category].
  Future<List<WorkoutEntity>> getWorkoutsByCategory(WorkoutCategory category);

  /// Returns a single workout by [id].
  Future<WorkoutEntity?> getWorkoutById(String id);

  /// Toggles favourite status; returns updated workout.
  Future<WorkoutEntity> toggleFavourite(String id);

  // ── History ────────────────────────────────────────────────────────────────

  /// Returns the full session history, newest first.
  Future<List<WorkoutHistoryEntry>> getHistory();

  /// Logs a completed session.
  Future<void> logSession(WorkoutHistoryEntry entry);

  // ── Statistics ─────────────────────────────────────────────────────────────

  Future<FitnessStatsEntity> getStats();

  Future<DailyActivityEntity> getTodayActivity();

  // ── Achievements ───────────────────────────────────────────────────────────

  Future<List<AchievementEntity>> getAchievements();
}

