/// A logged completed workout session.
class WorkoutHistoryEntry {
  const WorkoutHistoryEntry({
    required this.id,
    required this.workoutId,
    required this.workoutTitle,
    required this.category,
    required this.completedAt,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.exercisesCompleted,
    this.notes,
    this.rating,
  });

  final String id;
  final String workoutId;
  final String workoutTitle;
  final String category;
  final DateTime completedAt;
  final int durationMinutes;
  final int caloriesBurned;
  final int exercisesCompleted;
  final String? notes;
  final int? rating; // 1–5
}

/// Aggregated fitness statistics.
class FitnessStatsEntity {
  const FitnessStatsEntity({
    required this.totalWorkouts,
    required this.totalMinutes,
    required this.totalCalories,
    required this.currentStreak,
    required this.longestStreak,
    required this.weeklyWorkouts,
    required this.weeklyCalories,
    required this.weeklyMinutes,
    required this.weeklyDistance,
    required this.weeklyCaloriesData,
    required this.weeklyMinutesData,
    required this.weeklyFrequencyData,
    required this.monthlyCaloriesData,
  });

  final int totalWorkouts;
  final int totalMinutes;
  final int totalCalories;
  final int currentStreak;
  final int longestStreak;

  // Today's/weekly summaries
  final int weeklyWorkouts;
  final int weeklyCalories;
  final int weeklyMinutes;
  final double weeklyDistance; // km

  // Chart data (7 values, Mon–Sun)
  final List<double> weeklyCaloriesData;
  final List<double> weeklyMinutesData;
  final List<double> weeklyFrequencyData;

  // Monthly calories (30 values)
  final List<double> monthlyCaloriesData;
}

/// Daily activity summary for the dashboard.
class DailyActivityEntity {
  const DailyActivityEntity({
    required this.date,
    required this.caloriesBurned,
    required this.caloriesGoal,
    required this.activeMinutes,
    required this.activeMinutesGoal,
    required this.distanceKm,
    required this.distanceGoalKm,
    required this.stepsTaken,
    required this.stepsGoal,
    required this.workoutsCompleted,
  });

  final DateTime date;
  final int caloriesBurned;
  final int caloriesGoal;
  final int activeMinutes;
  final int activeMinutesGoal;
  final double distanceKm;
  final double distanceGoalKm;
  final int stepsTaken;
  final int stepsGoal;
  final int workoutsCompleted;

  double get calorieFraction =>
      (caloriesBurned / caloriesGoal).clamp(0.0, 1.0);
  double get activeMinutesFraction =>
      (activeMinutes / activeMinutesGoal).clamp(0.0, 1.0);
  double get distanceFraction =>
      (distanceKm / distanceGoalKm).clamp(0.0, 1.0);
  double get stepsFraction => (stepsTaken / stepsGoal).clamp(0.0, 1.0);
}
