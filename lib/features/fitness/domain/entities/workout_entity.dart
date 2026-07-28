/// Workout category types.
enum WorkoutCategory {
  strength,
  cardio,
  yoga,
  stretching,
  walking,
  running,
  cycling,
  hiit,
  homeWorkout,
}

extension WorkoutCategoryX on WorkoutCategory {
  String get label => switch (this) {
        WorkoutCategory.strength => 'Strength',
        WorkoutCategory.cardio => 'Cardio',
        WorkoutCategory.yoga => 'Yoga',
        WorkoutCategory.stretching => 'Stretching',
        WorkoutCategory.walking => 'Walking',
        WorkoutCategory.running => 'Running',
        WorkoutCategory.cycling => 'Cycling',
        WorkoutCategory.hiit => 'HIIT',
        WorkoutCategory.homeWorkout => 'Home Workout',
      };
}

/// Difficulty levels for workouts.
enum WorkoutDifficulty { beginner, intermediate, advanced }

extension WorkoutDifficultyX on WorkoutDifficulty {
  String get label => switch (this) {
        WorkoutDifficulty.beginner => 'Beginner',
        WorkoutDifficulty.intermediate => 'Intermediate',
        WorkoutDifficulty.advanced => 'Advanced',
      };
}

/// Equipment needed for a workout.
enum WorkoutEquipment { none, dumbbells, barbell, resistanceBand, mat, machine, bike, treadmill }

extension WorkoutEquipmentX on WorkoutEquipment {
  String get label => switch (this) {
        WorkoutEquipment.none => 'No Equipment',
        WorkoutEquipment.dumbbells => 'Dumbbells',
        WorkoutEquipment.barbell => 'Barbell',
        WorkoutEquipment.resistanceBand => 'Resistance Band',
        WorkoutEquipment.mat => 'Mat',
        WorkoutEquipment.machine => 'Machine',
        WorkoutEquipment.bike => 'Bike',
        WorkoutEquipment.treadmill => 'Treadmill',
      };
}

/// A single exercise within a workout.
class ExerciseEntity {
  const ExerciseEntity({
    required this.id,
    required this.name,
    required this.targetMuscles,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    this.durationSeconds,
    this.instructions,
    this.imageAsset,
  });

  final String id;
  final String name;
  final List<String> targetMuscles;

  /// Number of sets (0 if time-based).
  final int sets;

  /// Reps per set (0 if time-based).
  final int reps;

  /// Rest between sets in seconds.
  final int restSeconds;

  /// Duration in seconds for time-based exercises (e.g., planks).
  final int? durationSeconds;

  final String? instructions;
  final String? imageAsset;

  bool get isTimeBased => durationSeconds != null;
}

/// A workout program entity.
class WorkoutEntity {
  const WorkoutEntity({
    required this.id,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.durationMinutes,
    required this.caloriesEstimate,
    required this.exercises,
    required this.targetMuscles,
    required this.equipment,
    this.description,
    this.imageGradientIndex = 0,
    this.isFavorite = false,
    this.rating = 0.0,
    this.totalRatings = 0,
  });

  final String id;
  final String title;
  final WorkoutCategory category;
  final WorkoutDifficulty difficulty;
  final int durationMinutes;
  final int caloriesEstimate;
  final List<ExerciseEntity> exercises;
  final List<String> targetMuscles;
  final List<WorkoutEquipment> equipment;
  final String? description;

  /// Selects gradient from a set of predefined gradients.
  final int imageGradientIndex;
  final bool isFavorite;
  final double rating;
  final int totalRatings;
}
