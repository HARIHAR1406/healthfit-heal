/// Types of adjustments the engine can recommend for the next session.
enum AdjustmentType {
  increaseDifficulty,
  maintainDifficulty,
  reduceDifficulty,
  changeExercise,
  increaseRest,
  reduceRest,
  increaseRepetitions,
  reduceRepetitions,
}

extension AdjustmentTypeX on AdjustmentType {
  String get label => switch (this) {
        AdjustmentType.increaseDifficulty => 'Increase Difficulty',
        AdjustmentType.maintainDifficulty => 'Maintain Difficulty',
        AdjustmentType.reduceDifficulty => 'Reduce Difficulty',
        AdjustmentType.changeExercise => 'Change Exercise',
        AdjustmentType.increaseRest => 'Increase Rest',
        AdjustmentType.reduceRest => 'Reduce Rest',
        AdjustmentType.increaseRepetitions => 'Increase Reps',
        AdjustmentType.reduceRepetitions => 'Reduce Reps',
      };
}

/// A specific recommended adjustment for the next session based on the current one.
class WorkoutAdaptation {
  const WorkoutAdaptation({
    required this.adjustmentType,
    required this.reasoning,
  });

  final AdjustmentType adjustmentType;
  final String reasoning;
}

