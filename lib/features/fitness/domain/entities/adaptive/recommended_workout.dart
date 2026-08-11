import '../workout_entity.dart';

/// The output of the Adaptive Workout Generator.
class RecommendedWorkout {
  const RecommendedWorkout({
    required this.workout,
    required this.matchScore,
    required this.estimatedEffort,
    required this.primaryReasoning,
  });

  /// The generated workout entity (or a tailored copy of an existing one).
  final WorkoutEntity workout;

  /// How closely this recommendation matches the user's goals (0-100).
  final int matchScore;

  /// Estimated effort level (e.g., 'High', 'Moderate', 'Recovery').
  final String estimatedEffort;

  /// A short sentence explaining why this was recommended.
  /// Example: "Focuses on lower body to balance your recent upper body sessions."
  final String primaryReasoning;
}
