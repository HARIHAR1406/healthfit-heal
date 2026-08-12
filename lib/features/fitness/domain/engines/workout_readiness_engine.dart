import '../entities/adaptive/workout_context.dart';
import '../entities/adaptive/workout_readiness.dart';

/// Pure-Dart logic engine for determining workout readiness based on context.
class WorkoutReadinessEngine {
  /// Evaluates readiness based on history, stats, and goals.
  WorkoutReadiness evaluate(WorkoutContext context) {
    if (!context.hasSufficientHistory) {
      return WorkoutReadiness.insufficientData();
    }

    final history = context.recentHistory;
    final now = DateTime.now();

    // Sort descending by completion date
    final sorted = List.of(history)
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    final lastWorkout = sorted.first;
    final hoursSinceLastWorkout =
        now.difference(lastWorkout.completedAt).inHours;

    final reasoning = <String>[];
    ReadinessStatus status = ReadinessStatus.ready;
    int score = 100;

    // Check rest period
    if (hoursSinceLastWorkout < 12) {
      status = ReadinessStatus.recover;
      score = 30;
      reasoning.add('You worked out less than 12 hours ago.');
    } else if (hoursSinceLastWorkout < 24) {
      status = ReadinessStatus.moderate;
      score = 60;
      reasoning.add('You worked out yesterday. A moderate session is best.');
    } else {
      reasoning.add('You are fully rested (>${hoursSinceLastWorkout}h since last workout).');
    }

    // Check frequency
    final weeklyFrequency = context.fitnessStats.weeklyWorkouts;
    if (weeklyFrequency >= context.userGoals.weeklyWorkoutsTarget &&
        weeklyFrequency > 0) {
      // Already hit target
      if (status == ReadinessStatus.ready) {
        status = ReadinessStatus.moderate;
        score -= 20;
      }
      reasoning.add(
          'You have reached your weekly goal of ${context.userGoals.weeklyWorkoutsTarget} workouts.');
    }

    // Check last intensity (proxied by duration/calories here since we lack direct perceived exertion)
    if (lastWorkout.durationMinutes > 60 || lastWorkout.caloriesBurned > 500) {
      if (hoursSinceLastWorkout < 36) {
        status = ReadinessStatus.recover;
        score -= 30;
        reasoning.add(
            'Your last workout was highly intense (${lastWorkout.durationMinutes}m, ${lastWorkout.caloriesBurned} kcal).');
      }
    }

    // Clamp score
    score = score.clamp(0, 100);

    return WorkoutReadiness(
      status: status,
      score: score,
      reasoning: reasoning,
    );
  }
}

