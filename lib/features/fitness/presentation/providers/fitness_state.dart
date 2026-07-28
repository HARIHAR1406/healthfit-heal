import '../../domain/entities/achievement_entity.dart';
import '../../domain/entities/fitness_stats_entity.dart';
import '../../domain/entities/workout_entity.dart';
import '../../domain/entities/workout_session_entity.dart';

// ── Fitness Dashboard State ───────────────────────────────────────────────────

sealed class FitnessState {
  const FitnessState();
}

final class FitnessInitial extends FitnessState {
  const FitnessInitial();
}

final class FitnessLoading extends FitnessState {
  const FitnessLoading();
}

final class FitnessLoaded extends FitnessState {
  const FitnessLoaded({
    required this.stats,
    required this.todayActivity,
    required this.workouts,
    required this.history,
    required this.achievements,
  });

  final FitnessStatsEntity stats;
  final DailyActivityEntity todayActivity;
  final List<WorkoutEntity> workouts;
  final List<WorkoutHistoryEntry> history;
  final List<AchievementEntity> achievements;
}

final class FitnessRefreshing extends FitnessState {
  const FitnessRefreshing({required this.data});
  final FitnessLoaded data;
}

final class FitnessError extends FitnessState {
  const FitnessError({required this.message});
  final String message;
}

extension FitnessStateX on FitnessState {
  bool get hasData =>
      this is FitnessLoaded || this is FitnessRefreshing;

  FitnessLoaded? get data => switch (this) {
        FitnessLoaded d => d,
        FitnessRefreshing r => r.data,
        _ => null,
      };
}

// ── Workout Library State ────────────────────────────────────────────────────

sealed class WorkoutLibraryState {
  const WorkoutLibraryState();
}

final class WorkoutLibraryLoading extends WorkoutLibraryState {
  const WorkoutLibraryLoading();
}

final class WorkoutLibraryLoaded extends WorkoutLibraryState {
  const WorkoutLibraryLoaded({required this.workouts});
  final List<WorkoutEntity> workouts;
}

final class WorkoutLibraryError extends WorkoutLibraryState {
  const WorkoutLibraryError({required this.message});
  final String message;
}

// ── Active Session State ─────────────────────────────────────────────────────

sealed class SessionState {
  const SessionState();
}

final class SessionIdle extends SessionState {
  const SessionIdle();
}

final class SessionActive extends SessionState {
  const SessionActive({required this.session});
  final WorkoutSessionEntity session;
}

final class SessionFinished extends SessionState {
  const SessionFinished({required this.session});
  final WorkoutSessionEntity session;
}

extension SessionStateX on SessionState {
  WorkoutSessionEntity? get session => switch (this) {
        SessionActive s => s.session,
        SessionFinished s => s.session,
        _ => null,
      };
}

// ── History State ─────────────────────────────────────────────────────────────

sealed class HistoryState {
  const HistoryState();
}

final class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

final class HistoryLoaded extends HistoryState {
  const HistoryLoaded({required this.entries});
  final List<WorkoutHistoryEntry> entries;
}

final class HistoryError extends HistoryState {
  const HistoryError({required this.message});
  final String message;
}
