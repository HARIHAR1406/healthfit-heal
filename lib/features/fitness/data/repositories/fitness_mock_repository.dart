import '../../domain/entities/achievement_entity.dart';
import '../../domain/entities/fitness_stats_entity.dart';
import '../../domain/entities/workout_entity.dart';
import '../../domain/repositories/fitness_repository.dart';

/// In-memory mock repository with realistic fixture data.
///
/// Swap for [FitnessRepositoryImpl] when backend is ready.
class FitnessMockRepository implements FitnessRepository {
  final List<WorkoutEntity> _workouts = _buildWorkouts();
  final List<WorkoutHistoryEntry> _history = _buildHistory();

  // ── Workout Library ────────────────────────────────────────────────────────

  @override
  Future<List<WorkoutEntity>> getWorkouts() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.unmodifiable(_workouts);
  }

  @override
  Future<List<WorkoutEntity>> getWorkoutsByCategory(
      WorkoutCategory category) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _workouts.where((w) => w.category == category).toList();
  }

  @override
  Future<WorkoutEntity?> getWorkoutById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _workouts.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<WorkoutEntity> toggleFavourite(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final idx = _workouts.indexWhere((w) => w.id == id);
    if (idx == -1) throw ArgumentError('Workout $id not found');
    final updated = WorkoutEntity(
      id: _workouts[idx].id,
      title: _workouts[idx].title,
      category: _workouts[idx].category,
      difficulty: _workouts[idx].difficulty,
      durationMinutes: _workouts[idx].durationMinutes,
      caloriesEstimate: _workouts[idx].caloriesEstimate,
      exercises: _workouts[idx].exercises,
      targetMuscles: _workouts[idx].targetMuscles,
      equipment: _workouts[idx].equipment,
      description: _workouts[idx].description,
      imageGradientIndex: _workouts[idx].imageGradientIndex,
      isFavorite: !_workouts[idx].isFavorite,
      rating: _workouts[idx].rating,
      totalRatings: _workouts[idx].totalRatings,
    );
    _workouts[idx] = updated;
    return updated;
  }

  // ── History ────────────────────────────────────────────────────────────────

  @override
  Future<List<WorkoutHistoryEntry>> getHistory() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.unmodifiable(_history);
  }

  @override
  Future<void> logSession(WorkoutHistoryEntry entry) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _history.insert(0, entry);
  }

  // ── Statistics ─────────────────────────────────────────────────────────────

  @override
  Future<FitnessStatsEntity> getStats() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const FitnessStatsEntity(
      totalWorkouts: 47,
      totalMinutes: 2840,
      totalCalories: 18650,
      currentStreak: 5,
      longestStreak: 14,
      weeklyWorkouts: 4,
      weeklyCalories: 1520,
      weeklyMinutes: 185,
      weeklyDistance: 12.4,
      weeklyCaloriesData: [210, 0, 340, 280, 0, 420, 270],
      weeklyMinutesData: [28, 0, 42, 35, 0, 52, 28],
      weeklyFrequencyData: [1, 0, 1, 1, 0, 1, 1],
      monthlyCaloriesData: [
        180, 0, 320, 250, 190, 0, 410, 280, 0, 220,
        300, 180, 0, 350, 0, 420, 260, 190, 0, 310,
        240, 0, 380, 290, 0, 200, 340, 0, 270, 410,
      ],
    );
  }

  @override
  Future<DailyActivityEntity> getTodayActivity() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return DailyActivityEntity(
      date: DateTime.now(),
      caloriesBurned: 420,
      caloriesGoal: 600,
      activeMinutes: 38,
      activeMinutesGoal: 60,
      distanceKm: 3.2,
      distanceGoalKm: 5.0,
      stepsTaken: 6840,
      stepsGoal: 10000,
      workoutsCompleted: 1,
    );
  }

  // ── Achievements ───────────────────────────────────────────────────────────

  @override
  Future<List<AchievementEntity>> getAchievements() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final now = DateTime.now();
    return [
      AchievementEntity(
        id: 'ach_01',
        type: AchievementType.firstWorkout,
        unlockedAt: now.subtract(const Duration(days: 30)),
        isUnlocked: true,
        progressCurrent: 1,
        progressTarget: 1,
      ),
      AchievementEntity(
        id: 'ach_02',
        type: AchievementType.streak7,
        unlockedAt: now.subtract(const Duration(days: 10)),
        isUnlocked: true,
        progressCurrent: 7,
        progressTarget: 7,
      ),
      AchievementEntity(
        id: 'ach_03',
        type: AchievementType.streak30,
        unlockedAt: null,
        isUnlocked: false,
        progressCurrent: 5,
        progressTarget: 30,
      ),
      AchievementEntity(
        id: 'ach_04',
        type: AchievementType.calories1000,
        unlockedAt: now.subtract(const Duration(days: 20)),
        isUnlocked: true,
        progressCurrent: 1000,
        progressTarget: 1000,
      ),
      AchievementEntity(
        id: 'ach_05',
        type: AchievementType.workouts10,
        unlockedAt: now.subtract(const Duration(days: 15)),
        isUnlocked: true,
        progressCurrent: 10,
        progressTarget: 10,
      ),
      AchievementEntity(
        id: 'ach_06',
        type: AchievementType.workouts100,
        unlockedAt: null,
        isUnlocked: false,
        progressCurrent: 47,
        progressTarget: 100,
      ),
      AchievementEntity(
        id: 'ach_07',
        type: AchievementType.marathon,
        unlockedAt: null,
        isUnlocked: false,
        progressCurrent: 18,
        progressTarget: 42,
      ),
      AchievementEntity(
        id: 'ach_08',
        type: AchievementType.personalBest,
        unlockedAt: now.subtract(const Duration(days: 5)),
        isUnlocked: true,
        progressCurrent: 1,
        progressTarget: 1,
      ),
      AchievementEntity(
        id: 'ach_09',
        type: AchievementType.earlyBird,
        unlockedAt: now.subtract(const Duration(days: 8)),
        isUnlocked: true,
        progressCurrent: 1,
        progressTarget: 1,
      ),
      AchievementEntity(
        id: 'ach_10',
        type: AchievementType.weekendWarrior,
        unlockedAt: null,
        isUnlocked: false,
        progressCurrent: 2,
        progressTarget: 4,
      ),
    ];
  }
}

// ── Workout fixture data ───────────────────────────────────────────────────────

List<WorkoutEntity> _buildWorkouts() {
  return [
    // ── Strength
    WorkoutEntity(
      id: 'w_strength_01',
      title: 'Full Body Strength',
      category: WorkoutCategory.strength,
      difficulty: WorkoutDifficulty.intermediate,
      durationMinutes: 45,
      caloriesEstimate: 320,
      description:
          'A comprehensive strength training session targeting all major muscle groups. Perfect for building lean muscle and boosting metabolism.',
      targetMuscles: ['Chest', 'Back', 'Legs', 'Shoulders', 'Core'],
      equipment: [WorkoutEquipment.dumbbells, WorkoutEquipment.mat],
      imageGradientIndex: 0,
      rating: 4.7,
      totalRatings: 234,
      exercises: [
        const ExerciseEntity(
          id: 'e_01',
          name: 'Push-Ups',
          targetMuscles: ['Chest', 'Triceps', 'Shoulders'],
          sets: 3,
          reps: 15,
          restSeconds: 60,
          instructions: 'Keep your body in a straight line from head to heels. Lower until chest nearly touches the floor.',
        ),
        const ExerciseEntity(
          id: 'e_02',
          name: 'Dumbbell Squats',
          targetMuscles: ['Quads', 'Glutes', 'Hamstrings'],
          sets: 3,
          reps: 12,
          restSeconds: 90,
          instructions: 'Hold dumbbells at sides. Keep chest up, knees tracking over toes as you squat to parallel.',
        ),
        const ExerciseEntity(
          id: 'e_03',
          name: 'Bent-Over Rows',
          targetMuscles: ['Back', 'Biceps'],
          sets: 3,
          reps: 12,
          restSeconds: 75,
          instructions: 'Hinge at hips, keep back flat. Pull dumbbells to lower chest, squeezing shoulder blades.',
        ),
        const ExerciseEntity(
          id: 'e_04',
          name: 'Overhead Press',
          targetMuscles: ['Shoulders', 'Triceps'],
          sets: 3,
          reps: 10,
          restSeconds: 90,
          instructions: 'Press dumbbells from shoulder height to fully extended overhead. Avoid arching lower back.',
        ),
        const ExerciseEntity(
          id: 'e_05',
          name: 'Plank',
          targetMuscles: ['Core', 'Shoulders'],
          sets: 3,
          reps: 0,
          restSeconds: 60,
          durationSeconds: 45,
          instructions: 'Hold a push-up position with forearms on the floor. Keep hips level, breathe steadily.',
        ),
      ],
    ),

    // ── Cardio
    WorkoutEntity(
      id: 'w_cardio_01',
      title: 'Cardio Blast',
      category: WorkoutCategory.cardio,
      difficulty: WorkoutDifficulty.intermediate,
      durationMinutes: 30,
      caloriesEstimate: 380,
      description:
          'High-energy cardio workout to elevate your heart rate and burn maximum calories in minimal time.',
      targetMuscles: ['Full Body', 'Cardiovascular System'],
      equipment: [WorkoutEquipment.none],
      imageGradientIndex: 1,
      rating: 4.5,
      totalRatings: 187,
      exercises: [
        const ExerciseEntity(
          id: 'e_c01',
          name: 'Jumping Jacks',
          targetMuscles: ['Full Body'],
          sets: 3,
          reps: 30,
          restSeconds: 30,
          instructions: 'Jump feet apart while raising arms overhead, then return to start.',
        ),
        const ExerciseEntity(
          id: 'e_c02',
          name: 'High Knees',
          targetMuscles: ['Core', 'Hip Flexors', 'Legs'],
          sets: 3,
          reps: 0,
          restSeconds: 30,
          durationSeconds: 30,
          instructions: 'Run in place driving knees up to waist height as fast as possible.',
        ),
        const ExerciseEntity(
          id: 'e_c03',
          name: 'Burpees',
          targetMuscles: ['Full Body'],
          sets: 3,
          reps: 10,
          restSeconds: 60,
          instructions: 'From standing, drop to push-up position, perform push-up, jump feet forward, leap up.',
        ),
        const ExerciseEntity(
          id: 'e_c04',
          name: 'Mountain Climbers',
          targetMuscles: ['Core', 'Shoulders'],
          sets: 3,
          reps: 0,
          restSeconds: 30,
          durationSeconds: 30,
          instructions: 'In push-up position, rapidly alternate driving each knee toward chest.',
        ),
      ],
    ),

    // ── HIIT
    WorkoutEntity(
      id: 'w_hiit_01',
      title: 'HIIT Power Circuit',
      category: WorkoutCategory.hiit,
      difficulty: WorkoutDifficulty.advanced,
      durationMinutes: 25,
      caloriesEstimate: 420,
      description:
          'Intense intervals of explosive movements followed by short recovery periods. Maximizes EPOC for post-workout calorie burn.',
      targetMuscles: ['Full Body'],
      equipment: [WorkoutEquipment.mat],
      imageGradientIndex: 2,
      rating: 4.9,
      totalRatings: 312,
      exercises: [
        const ExerciseEntity(
          id: 'e_h01',
          name: 'Jump Squats',
          targetMuscles: ['Quads', 'Glutes'],
          sets: 4,
          reps: 15,
          restSeconds: 20,
          instructions: 'Squat down then explode upward, landing softly back in squat position.',
        ),
        const ExerciseEntity(
          id: 'e_h02',
          name: 'Explosive Push-Ups',
          targetMuscles: ['Chest', 'Triceps'],
          sets: 4,
          reps: 10,
          restSeconds: 20,
          instructions: 'Push up with enough force to lift hands off ground briefly.',
        ),
        const ExerciseEntity(
          id: 'e_h03',
          name: 'Tuck Jumps',
          targetMuscles: ['Legs', 'Core'],
          sets: 4,
          reps: 12,
          restSeconds: 30,
          instructions: 'Jump and pull knees toward chest at peak height.',
        ),
        const ExerciseEntity(
          id: 'e_h04',
          name: 'Sprint in Place',
          targetMuscles: ['Full Body'],
          sets: 4,
          reps: 0,
          restSeconds: 20,
          durationSeconds: 20,
          instructions: 'Sprint at maximum effort in place for 20 seconds.',
        ),
      ],
    ),

    // ── Yoga
    WorkoutEntity(
      id: 'w_yoga_01',
      title: 'Morning Flow Yoga',
      category: WorkoutCategory.yoga,
      difficulty: WorkoutDifficulty.beginner,
      durationMinutes: 30,
      caloriesEstimate: 120,
      description:
          'A gentle flowing yoga sequence designed to awaken the body, improve flexibility, and set a positive intention for the day.',
      targetMuscles: ['Full Body', 'Spine', 'Hips'],
      equipment: [WorkoutEquipment.mat],
      imageGradientIndex: 3,
      rating: 4.8,
      totalRatings: 421,
      exercises: [
        const ExerciseEntity(
          id: 'e_y01',
          name: 'Cat-Cow Stretch',
          targetMuscles: ['Spine', 'Core'],
          sets: 1,
          reps: 0,
          restSeconds: 10,
          durationSeconds: 60,
          instructions: 'On all fours, alternate arching and rounding your spine with each breath.',
        ),
        const ExerciseEntity(
          id: 'e_y02',
          name: 'Downward Dog',
          targetMuscles: ['Hamstrings', 'Calves', 'Shoulders'],
          sets: 1,
          reps: 0,
          restSeconds: 10,
          durationSeconds: 45,
          instructions: 'Form an inverted V-shape, pressing heels toward the floor and hips up and back.',
        ),
        const ExerciseEntity(
          id: 'e_y03',
          name: 'Warrior I',
          targetMuscles: ['Quads', 'Hip Flexors', 'Shoulders'],
          sets: 2,
          reps: 0,
          restSeconds: 15,
          durationSeconds: 45,
          instructions: 'Lunge forward, back foot at 45°, arms raised overhead, hips square to front.',
        ),
        const ExerciseEntity(
          id: 'e_y04',
          name: "Child's Pose",
          targetMuscles: ['Back', 'Hips'],
          sets: 1,
          reps: 0,
          restSeconds: 0,
          durationSeconds: 60,
          instructions: 'Sit back onto heels, extend arms forward on mat, relax forehead to ground.',
        ),
      ],
    ),

    // ── Running
    WorkoutEntity(
      id: 'w_run_01',
      title: '5K Beginner Run',
      category: WorkoutCategory.running,
      difficulty: WorkoutDifficulty.beginner,
      durationMinutes: 35,
      caloriesEstimate: 290,
      description:
          'A structured run/walk program ideal for beginners training for their first 5K.',
      targetMuscles: ['Legs', 'Cardiovascular System'],
      equipment: [WorkoutEquipment.none],
      imageGradientIndex: 4,
      rating: 4.6,
      totalRatings: 198,
      exercises: [
        const ExerciseEntity(
          id: 'e_r01',
          name: 'Warm-Up Walk',
          targetMuscles: ['Legs'],
          sets: 1,
          reps: 0,
          restSeconds: 0,
          durationSeconds: 300,
          instructions: 'Walk at a comfortable pace to warm up muscles.',
        ),
        const ExerciseEntity(
          id: 'e_r02',
          name: 'Easy Jog',
          targetMuscles: ['Legs', 'Cardiovascular'],
          sets: 1,
          reps: 0,
          restSeconds: 0,
          durationSeconds: 1200,
          instructions: 'Jog at a comfortable conversational pace for 20 minutes.',
        ),
        const ExerciseEntity(
          id: 'e_r03',
          name: 'Cool-Down Walk',
          targetMuscles: ['Legs'],
          sets: 1,
          reps: 0,
          restSeconds: 0,
          durationSeconds: 300,
          instructions: 'Walk slowly to bring heart rate back to normal.',
        ),
      ],
    ),

    // ── Stretching
    WorkoutEntity(
      id: 'w_stretch_01',
      title: 'Full Body Stretch',
      category: WorkoutCategory.stretching,
      difficulty: WorkoutDifficulty.beginner,
      durationMinutes: 20,
      caloriesEstimate: 60,
      description:
          'A head-to-toe stretching routine to improve flexibility, reduce muscle tension, and enhance recovery.',
      targetMuscles: ['Full Body'],
      equipment: [WorkoutEquipment.mat],
      imageGradientIndex: 5,
      rating: 4.7,
      totalRatings: 156,
      exercises: [
        const ExerciseEntity(
          id: 'e_s01',
          name: 'Neck Rolls',
          targetMuscles: ['Neck'],
          sets: 1,
          reps: 0,
          restSeconds: 10,
          durationSeconds: 30,
          instructions: 'Gently roll head in full circles, 5 each direction.',
        ),
        const ExerciseEntity(
          id: 'e_s02',
          name: 'Chest Opener',
          targetMuscles: ['Chest', 'Shoulders'],
          sets: 1,
          reps: 0,
          restSeconds: 10,
          durationSeconds: 30,
          instructions: 'Clasp hands behind back, squeeze shoulder blades, lift chest.',
        ),
        const ExerciseEntity(
          id: 'e_s03',
          name: 'Hip Flexor Stretch',
          targetMuscles: ['Hip Flexors', 'Quads'],
          sets: 2,
          reps: 0,
          restSeconds: 10,
          durationSeconds: 30,
          instructions: 'Kneel on one knee, shift hips forward gently, hold 30s each side.',
        ),
        const ExerciseEntity(
          id: 'e_s04',
          name: 'Hamstring Stretch',
          targetMuscles: ['Hamstrings'],
          sets: 2,
          reps: 0,
          restSeconds: 10,
          durationSeconds: 30,
          instructions: 'Sit with one leg extended, reach toward toes, hold 30s each side.',
        ),
      ],
    ),

    // ── Home Workout
    WorkoutEntity(
      id: 'w_home_01',
      title: 'No-Equipment Home Blast',
      category: WorkoutCategory.homeWorkout,
      difficulty: WorkoutDifficulty.intermediate,
      durationMinutes: 30,
      caloriesEstimate: 280,
      description:
          'A complete workout requiring zero equipment — perfect for home, hotel rooms, or whenever a gym is not available.',
      targetMuscles: ['Full Body'],
      equipment: [WorkoutEquipment.none],
      imageGradientIndex: 0,
      rating: 4.6,
      totalRatings: 289,
      exercises: [
        const ExerciseEntity(
          id: 'e_hw01',
          name: 'Wall Sit',
          targetMuscles: ['Quads', 'Glutes'],
          sets: 3,
          reps: 0,
          restSeconds: 60,
          durationSeconds: 45,
          instructions: 'Back against wall, thighs parallel to floor. Hold for 45 seconds.',
        ),
        const ExerciseEntity(
          id: 'e_hw02',
          name: 'Diamond Push-Ups',
          targetMuscles: ['Triceps', 'Chest'],
          sets: 3,
          reps: 12,
          restSeconds: 60,
          instructions: 'Hands close together forming a diamond shape under chest.',
        ),
        const ExerciseEntity(
          id: 'e_hw03',
          name: 'Glute Bridges',
          targetMuscles: ['Glutes', 'Hamstrings'],
          sets: 3,
          reps: 15,
          restSeconds: 45,
          instructions: 'Lie on back, feet flat, drive hips up squeezing glutes at top.',
        ),
      ],
    ),

    // ── Cycling
    WorkoutEntity(
      id: 'w_cycle_01',
      title: 'Indoor Cycling Sprint',
      category: WorkoutCategory.cycling,
      difficulty: WorkoutDifficulty.intermediate,
      durationMinutes: 40,
      caloriesEstimate: 450,
      description:
          'High-intensity interval cycling designed to build aerobic capacity and lower body power.',
      targetMuscles: ['Quads', 'Hamstrings', 'Calves', 'Glutes'],
      equipment: [WorkoutEquipment.bike],
      imageGradientIndex: 1,
      rating: 4.4,
      totalRatings: 123,
      exercises: [
        const ExerciseEntity(
          id: 'e_cy01',
          name: 'Warm-Up Pedal',
          targetMuscles: ['Legs'],
          sets: 1,
          reps: 0,
          restSeconds: 0,
          durationSeconds: 300,
          instructions: 'Pedal at easy resistance, comfortable pace.',
        ),
        const ExerciseEntity(
          id: 'e_cy02',
          name: 'Sprint Intervals',
          targetMuscles: ['Quads', 'Calves'],
          sets: 6,
          reps: 0,
          restSeconds: 60,
          durationSeconds: 30,
          instructions: 'Sprint at maximum effort for 30s, then easy pedal 60s.',
        ),
        const ExerciseEntity(
          id: 'e_cy03',
          name: 'Cool-Down Pedal',
          targetMuscles: ['Legs'],
          sets: 1,
          reps: 0,
          restSeconds: 0,
          durationSeconds: 300,
          instructions: 'Easy pedaling at minimal resistance to recover.',
        ),
      ],
    ),

    // ── Walking
    WorkoutEntity(
      id: 'w_walk_01',
      title: 'Power Walk',
      category: WorkoutCategory.walking,
      difficulty: WorkoutDifficulty.beginner,
      durationMinutes: 45,
      caloriesEstimate: 200,
      description:
          'A brisk, purposeful walk to improve cardiovascular health and burn calories at a sustainable pace.',
      targetMuscles: ['Legs', 'Cardiovascular System'],
      equipment: [WorkoutEquipment.none],
      imageGradientIndex: 2,
      rating: 4.3,
      totalRatings: 342,
      exercises: [
        const ExerciseEntity(
          id: 'e_w01',
          name: 'Moderate Walk',
          targetMuscles: ['Legs'],
          sets: 1,
          reps: 0,
          restSeconds: 0,
          durationSeconds: 2700,
          instructions: 'Walk at a brisk, steady pace maintaining good posture.',
        ),
      ],
    ),
  ];
}

// ── History fixture data ───────────────────────────────────────────────────────

List<WorkoutHistoryEntry> _buildHistory() {
  final now = DateTime.now();
  return [
    WorkoutHistoryEntry(
      id: 'hist_01',
      workoutId: 'w_strength_01',
      workoutTitle: 'Full Body Strength',
      category: 'Strength',
      completedAt: now,
      durationMinutes: 47,
      caloriesBurned: 335,
      exercisesCompleted: 5,
      rating: 5,
    ),
    WorkoutHistoryEntry(
      id: 'hist_02',
      workoutId: 'w_hiit_01',
      workoutTitle: 'HIIT Power Circuit',
      category: 'HIIT',
      completedAt: now.subtract(const Duration(days: 1)),
      durationMinutes: 26,
      caloriesBurned: 428,
      exercisesCompleted: 4,
      rating: 5,
    ),
    WorkoutHistoryEntry(
      id: 'hist_03',
      workoutId: 'w_yoga_01',
      workoutTitle: 'Morning Flow Yoga',
      category: 'Yoga',
      completedAt: now.subtract(const Duration(days: 2)),
      durationMinutes: 32,
      caloriesBurned: 122,
      exercisesCompleted: 4,
      rating: 4,
    ),
    WorkoutHistoryEntry(
      id: 'hist_04',
      workoutId: 'w_cardio_01',
      workoutTitle: 'Cardio Blast',
      category: 'Cardio',
      completedAt: now.subtract(const Duration(days: 3)),
      durationMinutes: 31,
      caloriesBurned: 390,
      exercisesCompleted: 4,
      rating: 4,
    ),
    WorkoutHistoryEntry(
      id: 'hist_05',
      workoutId: 'w_run_01',
      workoutTitle: '5K Beginner Run',
      category: 'Running',
      completedAt: now.subtract(const Duration(days: 5)),
      durationMinutes: 36,
      caloriesBurned: 295,
      exercisesCompleted: 3,
      rating: 5,
    ),
    WorkoutHistoryEntry(
      id: 'hist_06',
      workoutId: 'w_stretch_01',
      workoutTitle: 'Full Body Stretch',
      category: 'Stretching',
      completedAt: now.subtract(const Duration(days: 6)),
      durationMinutes: 21,
      caloriesBurned: 65,
      exercisesCompleted: 4,
      rating: 4,
    ),
    WorkoutHistoryEntry(
      id: 'hist_07',
      workoutId: 'w_strength_01',
      workoutTitle: 'Full Body Strength',
      category: 'Strength',
      completedAt: now.subtract(const Duration(days: 7)),
      durationMinutes: 48,
      caloriesBurned: 330,
      exercisesCompleted: 5,
      rating: 5,
    ),
    WorkoutHistoryEntry(
      id: 'hist_08',
      workoutId: 'w_home_01',
      workoutTitle: 'No-Equipment Home Blast',
      category: 'Home Workout',
      completedAt: now.subtract(const Duration(days: 9)),
      durationMinutes: 32,
      caloriesBurned: 290,
      exercisesCompleted: 3,
      rating: 4,
    ),
  ];
}

