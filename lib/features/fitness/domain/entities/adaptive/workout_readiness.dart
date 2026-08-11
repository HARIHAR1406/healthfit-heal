/// The calculated readiness status for a user.
enum ReadinessStatus {
  /// User is fully recovered and ready for a challenging workout.
  ready,

  /// User is partially recovered; suggest a lighter or shorter workout.
  moderate,

  /// User has been overtraining or needs rest; suggest stretching or rest.
  recover,

  /// Not enough historical data to make a safe determination.
  insufficientData,
}

/// The result of the Readiness calculation engine.
class WorkoutReadiness {
  const WorkoutReadiness({
    required this.status,
    required this.score,
    required this.reasoning,
  });

  /// The overarching readiness status.
  final ReadinessStatus status;

  /// Readiness score from 0 to 100 (null if insufficient data).
  final int? score;

  /// Human-readable reasons for this score.
  /// Example: ["You completed a heavy leg session yesterday."]
  final List<String> reasoning;

  /// Safe default for new users.
  factory WorkoutReadiness.insufficientData() {
    return const WorkoutReadiness(
      status: ReadinessStatus.insufficientData,
      score: null,
      reasoning: ['Not enough workout history to calculate readiness.'],
    );
  }
}
