import '../entities/workout_session_entity.dart';
import '../entities/fitness_stats_entity.dart';
import '../entities/adaptive/workout_quality.dart';
import '../entities/adaptive/workout_progression.dart';
import '../entities/adaptive/workout_adaptation.dart';

/// Evaluates completed sessions to output quality, progression, and adaptations.
class WorkoutAnalysisEngine {
  /// Calculates the quality of a completed session.
  WorkoutQuality calculateQuality(WorkoutSessionEntity session) {
    if (session.status != SessionStatus.finished &&
        session.completedExerciseIds.isEmpty) {
      return const WorkoutQuality(
        score: 0,
        completionPercentage: 0.0,
        factors: ['Session was not completed or started.'],
      );
    }

    final totalExercises = session.workout.exercises.length;
    final completed = session.completedExerciseIds.length;
    final completionPercentage = (completed / totalExercises).clamp(0.0, 1.0);

    int score = (completionPercentage * 100).round();
    final factors = <String>[];

    if (completionPercentage == 1.0) {
      factors.add('Excellent! You completed all planned exercises.');
    } else if (completionPercentage >= 0.5) {
      factors.add('Good effort. You completed most of the workout.');
    } else {
      factors.add('You stopped early. Make sure to recover well.');
    }

    // Evaluate duration vs expected (simple heuristic)
    final expectedSeconds = session.workout.durationMinutes * 60;
    if (session.elapsedSeconds > expectedSeconds * 1.5) {
      score -= 10;
      factors.add('Session took significantly longer than expected (check rest times).');
    }

    return WorkoutQuality(
      score: score.clamp(0, 100),
      completionPercentage: completionPercentage,
      factors: factors,
    );
  }

  /// Calculates progression state based on recent history.
  WorkoutProgression calculateProgression(List<WorkoutHistoryEntry> history) {
    if (history.length < 3) {
      return WorkoutProgression.insufficientData();
    }

    // Sort descending by completion date
    final sorted = List.of(history)
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    // Simple heuristic: compare last 3 workouts' volume or consistency
    final w1 = sorted[0];
    final w2 = sorted[1];
    final w3 = sorted[2];

    ProgressionState state = ProgressionState.stable;
    final metrics = <String, String>{};
    String reasoning = 'Your performance is stable and consistent.';

    // Check consistency (all within last 7-10 days)
    final daysSinceW3 = w1.completedAt.difference(w3.completedAt).inDays;
    if (daysSinceW3 <= 7) {
      metrics['Consistency'] = 'High';
      state = ProgressionState.improving;
      reasoning = 'Excellent consistency over your last 3 workouts.';
    } else if (daysSinceW3 > 14) {
      metrics['Consistency'] = 'Low';
      state = ProgressionState.needsAttention;
      reasoning = 'Your workout frequency has dropped recently.';
    } else {
      metrics['Consistency'] = 'Moderate';
    }

    return WorkoutProgression(
      state: state,
      metrics: metrics,
      reasoning: reasoning,
    );
  }

  /// Suggests how the next session should be adapted based on this session's quality.
  WorkoutAdaptation adaptNextSession(WorkoutQuality quality, WorkoutSessionEntity session) {
    if (quality.completionPercentage == 1.0 && quality.score > 90) {
      return const WorkoutAdaptation(
        adjustmentType: AdjustmentType.increaseDifficulty,
        reasoning: 'You completed this session easily. We can increase the challenge next time.',
      );
    } else if (quality.completionPercentage < 0.5) {
      return const WorkoutAdaptation(
        adjustmentType: AdjustmentType.reduceDifficulty,
        reasoning: 'Since you stopped early, we will suggest a lighter session next time.',
      );
    }

    return const WorkoutAdaptation(
      adjustmentType: AdjustmentType.maintainDifficulty,
      reasoning: 'Solid session. We will maintain this level for consistency.',
    );
  }
}
