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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetMuscles': targetMuscles,
      'sets': sets,
      'reps': reps,
      'restSeconds': restSeconds,
      'durationSeconds': durationSeconds,
      'instructions': instructions,
      'imageAsset': imageAsset,
    };
  }

  factory ExerciseEntity.fromMap(Map<String, dynamic> map) {
    return ExerciseEntity(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      targetMuscles: List<String>.from(map['targetMuscles'] as List? ?? []),
      sets: (map['sets'] as num?)?.toInt() ?? 0,
      reps: (map['reps'] as num?)?.toInt() ?? 0,
      restSeconds: (map['restSeconds'] as num?)?.toInt() ?? 0,
      durationSeconds: (map['durationSeconds'] as num?)?.toInt(),
      instructions: map['instructions'] as String?,
      imageAsset: map['imageAsset'] as String?,
    );
  }
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

  WorkoutEntity copyWith({
    String? id,
    String? title,
    WorkoutCategory? category,
    WorkoutDifficulty? difficulty,
    int? durationMinutes,
    int? caloriesEstimate,
    List<ExerciseEntity>? exercises,
    List<String>? targetMuscles,
    List<WorkoutEquipment>? equipment,
    String? description,
    int? imageGradientIndex,
    bool? isFavorite,
    double? rating,
    int? totalRatings,
  }) {
    return WorkoutEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      caloriesEstimate: caloriesEstimate ?? this.caloriesEstimate,
      exercises: exercises ?? this.exercises,
      targetMuscles: targetMuscles ?? this.targetMuscles,
      equipment: equipment ?? this.equipment,
      description: description ?? this.description,
      imageGradientIndex: imageGradientIndex ?? this.imageGradientIndex,
      isFavorite: isFavorite ?? this.isFavorite,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category.name,
      'difficulty': difficulty.name,
      'durationMinutes': durationMinutes,
      'caloriesEstimate': caloriesEstimate,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'targetMuscles': targetMuscles,
      'equipment': equipment.map((e) => e.name).toList(),
      'description': description,
      'imageGradientIndex': imageGradientIndex,
      'isFavorite': isFavorite,
      'rating': rating,
      'totalRatings': totalRatings,
    };
  }

  factory WorkoutEntity.fromMap(Map<String, dynamic> map) {
    return WorkoutEntity(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      category: WorkoutCategory.values.firstWhere(
        (e) => e.name == (map['category'] as String?),
        orElse: () => WorkoutCategory.strength,
      ),
      difficulty: WorkoutDifficulty.values.firstWhere(
        (e) => e.name == (map['difficulty'] as String?),
        orElse: () => WorkoutDifficulty.beginner,
      ),
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 0,
      caloriesEstimate: (map['caloriesEstimate'] as num?)?.toInt() ?? 0,
      exercises: List<ExerciseEntity>.from(
        (map['exercises'] as List? ?? []).map((x) => ExerciseEntity.fromMap(x as Map<String, dynamic>)),
      ),
      targetMuscles: List<String>.from(map['targetMuscles'] as List? ?? []),
      equipment: List<WorkoutEquipment>.from(
        (map['equipment'] as List? ?? []).map((x) => WorkoutEquipment.values.firstWhere(
              (e) => e.name == (x as String?),
              orElse: () => WorkoutEquipment.none,
            )),
      ),
      description: map['description'] as String?,
      imageGradientIndex: (map['imageGradientIndex'] as num?)?.toInt() ?? 0,
      isFavorite: map['isFavorite'] as bool? ?? false,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: (map['totalRatings'] as num?)?.toInt() ?? 0,
    );
  }
}

