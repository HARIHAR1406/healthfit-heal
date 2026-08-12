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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutId': workoutId,
      'workoutTitle': workoutTitle,
      'category': category,
      'completedAt': completedAt.toIso8601String(),
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
      'exercisesCompleted': exercisesCompleted,
      'notes': notes,
      'rating': rating,
    };
  }

  factory WorkoutHistoryEntry.fromMap(Map<String, dynamic> map) {
    return WorkoutHistoryEntry(
      id: map['id'] as String? ?? '',
      workoutId: map['workoutId'] as String? ?? '',
      workoutTitle: map['workoutTitle'] as String? ?? '',
      category: map['category'] as String? ?? '',
      completedAt: DateTime.parse(map['completedAt'] as String),
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 0,
      caloriesBurned: (map['caloriesBurned'] as num?)?.toInt() ?? 0,
      exercisesCompleted: (map['exercisesCompleted'] as num?)?.toInt() ?? 0,
      notes: map['notes'] as String?,
      rating: (map['rating'] as num?)?.toInt(),
    );
  }
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

  Map<String, dynamic> toMap() {
    return {
      'totalWorkouts': totalWorkouts,
      'totalMinutes': totalMinutes,
      'totalCalories': totalCalories,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'weeklyWorkouts': weeklyWorkouts,
      'weeklyCalories': weeklyCalories,
      'weeklyMinutes': weeklyMinutes,
      'weeklyDistance': weeklyDistance,
      'weeklyCaloriesData': weeklyCaloriesData,
      'weeklyMinutesData': weeklyMinutesData,
      'weeklyFrequencyData': weeklyFrequencyData,
      'monthlyCaloriesData': monthlyCaloriesData,
    };
  }

  factory FitnessStatsEntity.fromMap(Map<String, dynamic> map) {
    return FitnessStatsEntity(
      totalWorkouts: (map['totalWorkouts'] as num?)?.toInt() ?? 0,
      totalMinutes: (map['totalMinutes'] as num?)?.toInt() ?? 0,
      totalCalories: (map['totalCalories'] as num?)?.toInt() ?? 0,
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (map['longestStreak'] as num?)?.toInt() ?? 0,
      weeklyWorkouts: (map['weeklyWorkouts'] as num?)?.toInt() ?? 0,
      weeklyCalories: (map['weeklyCalories'] as num?)?.toInt() ?? 0,
      weeklyMinutes: (map['weeklyMinutes'] as num?)?.toInt() ?? 0,
      weeklyDistance: (map['weeklyDistance'] as num?)?.toDouble() ?? 0.0,
      weeklyCaloriesData: List<double>.from((map['weeklyCaloriesData'] as List? ?? []).map((x) => (x as num).toDouble())),
      weeklyMinutesData: List<double>.from((map['weeklyMinutesData'] as List? ?? []).map((x) => (x as num).toDouble())),
      weeklyFrequencyData: List<double>.from((map['weeklyFrequencyData'] as List? ?? []).map((x) => (x as num).toDouble())),
      monthlyCaloriesData: List<double>.from((map['monthlyCaloriesData'] as List? ?? []).map((x) => (x as num).toDouble())),
    );
  }
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

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'caloriesBurned': caloriesBurned,
      'caloriesGoal': caloriesGoal,
      'activeMinutes': activeMinutes,
      'activeMinutesGoal': activeMinutesGoal,
      'distanceKm': distanceKm,
      'distanceGoalKm': distanceGoalKm,
      'stepsTaken': stepsTaken,
      'stepsGoal': stepsGoal,
      'workoutsCompleted': workoutsCompleted,
    };
  }

  factory DailyActivityEntity.fromMap(Map<String, dynamic> map) {
    return DailyActivityEntity(
      date: DateTime.parse(map['date'] as String),
      caloriesBurned: (map['caloriesBurned'] as num?)?.toInt() ?? 0,
      caloriesGoal: (map['caloriesGoal'] as num?)?.toInt() ?? 2000,
      activeMinutes: (map['activeMinutes'] as num?)?.toInt() ?? 0,
      activeMinutesGoal: (map['activeMinutesGoal'] as num?)?.toInt() ?? 30,
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0.0,
      distanceGoalKm: (map['distanceGoalKm'] as num?)?.toDouble() ?? 5.0,
      stepsTaken: (map['stepsTaken'] as num?)?.toInt() ?? 0,
      stepsGoal: (map['stepsGoal'] as num?)?.toInt() ?? 10000,
      workoutsCompleted: (map['workoutsCompleted'] as num?)?.toInt() ?? 0,
    );
  }
}

