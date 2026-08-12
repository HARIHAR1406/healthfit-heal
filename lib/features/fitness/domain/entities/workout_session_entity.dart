import '../entities/workout_entity.dart';

/// Represents the live state of an active workout session.
class WorkoutSessionEntity {
  const WorkoutSessionEntity({
    required this.workout,
    required this.currentExerciseIndex,
    required this.currentSet,
    required this.elapsedSeconds,
    required this.status,
    required this.completedExerciseIds,
    this.restCountdownSeconds,
  });

  final WorkoutEntity workout;
  final int currentExerciseIndex;
  final int currentSet;
  final int elapsedSeconds;
  final SessionStatus status;
  final List<String> completedExerciseIds;

  /// Non-null during rest countdown between sets.
  final int? restCountdownSeconds;

  // ── Derived ───────────────────────────────────────────────────────────────

  bool get isFinished => status == SessionStatus.finished;
  bool get isPaused => status == SessionStatus.paused;
  bool get isResting => restCountdownSeconds != null;

  ExerciseEntity get currentExercise =>
      workout.exercises[currentExerciseIndex];

  bool get hasNext =>
      currentExerciseIndex < workout.exercises.length - 1;

  bool get hasPrevious => currentExerciseIndex > 0;

  int get totalExercises => workout.exercises.length;

  double get overallProgress =>
      (completedExerciseIds.length / totalExercises).clamp(0.0, 1.0);

  /// Estimated calories burned so far (linear approximation).
  int get caloriesBurnedSoFar {
    final fraction = elapsedSeconds / (workout.durationMinutes * 60);
    return (workout.caloriesEstimate * fraction).round().clamp(
          0,
          workout.caloriesEstimate,
        );
  }

  String get elapsedFormatted {
    final m = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  WorkoutSessionEntity copyWith({
    int? currentExerciseIndex,
    int? currentSet,
    int? elapsedSeconds,
    SessionStatus? status,
    List<String>? completedExerciseIds,
    int? restCountdownSeconds,
    bool clearRest = false,
  }) {
    return WorkoutSessionEntity(
      workout: workout,
      currentExerciseIndex:
          currentExerciseIndex ?? this.currentExerciseIndex,
      currentSet: currentSet ?? this.currentSet,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      status: status ?? this.status,
      completedExerciseIds:
          completedExerciseIds ?? this.completedExerciseIds,
      restCountdownSeconds:
          clearRest ? null : (restCountdownSeconds ?? this.restCountdownSeconds),
    );
  }
}

enum SessionStatus { idle, active, paused, finished }

