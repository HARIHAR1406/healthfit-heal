/// Post-workout session quality score.
class WorkoutQuality {
  const WorkoutQuality({
    required this.score,
    required this.completionPercentage,
    required this.factors,
  });

  /// Quality score from 0-100 based on completion and rest adherence.
  final int score;

  /// Percentage of the planned workout that was actually completed (0.0 to 1.0).
  final double completionPercentage;

  /// Explanations for the score.
  /// Example: ["Excellent exercise completion", "Rested longer than planned"]
  final List<String> factors;
}
