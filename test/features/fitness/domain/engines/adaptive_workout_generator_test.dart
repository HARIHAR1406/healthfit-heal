import 'package:flutter_test/flutter_test.dart';

import 'package:healthfit_heal/features/fitness/domain/engines/adaptive_workout_generator.dart';
import 'package:healthfit_heal/features/fitness/domain/engines/exercise_recommendation_engine.dart';
import 'package:healthfit_heal/features/fitness/domain/entities/adaptive/workout_context.dart';
import 'package:healthfit_heal/features/fitness/domain/entities/adaptive/workout_readiness.dart';
import 'package:healthfit_heal/features/fitness/domain/entities/fitness_stats_entity.dart';
import 'package:healthfit_heal/features/fitness/domain/entities/workout_entity.dart';
import 'package:healthfit_heal/features/profile/domain/entities/profile_entity.dart';

void main() {
  late AdaptiveWorkoutGenerator generator;
  late ExerciseRecommendationEngine exerciseEngine;

  final defaultGoals = HealthGoals(
    dailyCaloriesTarget: 2000,
    dailyWaterMlTarget: 2000,
    dailyStepsTarget: 10000,
    weeklyWorkoutsTarget: 3,
    targetWeightKg: 70,
    sleepHoursTarget: 8,
  );

  final defaultStats = FitnessStatsEntity(
    totalWorkouts: 10,
    totalMinutes: 300,
    totalCalories: 3000,
    currentStreak: 2,
    longestStreak: 5,
    weeklyWorkouts: 2,
    weeklyCalories: 600,
    weeklyMinutes: 60,
    weeklyDistance: 0,
    weeklyCaloriesData: [],
    weeklyMinutesData: [],
    weeklyFrequencyData: [],
    monthlyCaloriesData: [],
  );

  final testLibrary = [
    WorkoutEntity(
      id: 'w1',
      title: 'Heavy Lifting',
      category: WorkoutCategory.strength,
      difficulty: WorkoutDifficulty.advanced,
      durationMinutes: 60,
      caloriesEstimate: 500,
      exercises: [],
      targetMuscles: [],
      equipment: [],
      description: '',
      imageGradientIndex: 0,
    ),
    WorkoutEntity(
      id: 'w2',
      title: 'Light Yoga',
      category: WorkoutCategory.yoga,
      difficulty: WorkoutDifficulty.beginner,
      durationMinutes: 30,
      caloriesEstimate: 150,
      exercises: [],
      targetMuscles: [],
      equipment: [],
      description: '',
      imageGradientIndex: 1,
    ),
    WorkoutEntity(
      id: 'w3',
      title: 'Moderate Cardio',
      category: WorkoutCategory.cardio,
      difficulty: WorkoutDifficulty.intermediate,
      durationMinutes: 45,
      caloriesEstimate: 350,
      exercises: [],
      targetMuscles: [],
      equipment: [],
      description: '',
      imageGradientIndex: 2,
    ),
  ];

  setUp(() {
    exerciseEngine = ExerciseRecommendationEngine();
    generator = AdaptiveWorkoutGenerator(exerciseEngine);
  });

  group('AdaptiveWorkoutGenerator', () {
    test('throws if library is empty', () {
      final context = WorkoutContext(
        userGoals: defaultGoals,
        activityLevel: ActivityLevel.moderatelyActive,
        fitnessStats: defaultStats,
        recentHistory: [],
        preferredEquipment: [],
      );
      final readiness = WorkoutReadiness(
        status: ReadinessStatus.ready,
        score: 100,
        reasoning: [],
      );

      expect(
        () => generator.generate(
          context: context,
          readiness: readiness,
          library: [],
        ),
        throwsArgumentError,
      );
    });

    test('recommends yoga/recovery when status is recover', () {
      final context = WorkoutContext(
        userGoals: defaultGoals,
        activityLevel: ActivityLevel.moderatelyActive,
        fitnessStats: defaultStats,
        recentHistory: [],
        preferredEquipment: [],
      );
      final readiness = WorkoutReadiness(
        status: ReadinessStatus.recover,
        score: 30,
        reasoning: [],
      );

      final rec = generator.generate(
        context: context,
        readiness: readiness,
        library: testLibrary,
      );

      expect(rec.workout.category, WorkoutCategory.yoga);
      expect(rec.estimatedEffort, 'Recovery');
    });

    test('recommends advanced/strength when status is ready', () {
      final context = WorkoutContext(
        userGoals: defaultGoals,
        activityLevel: ActivityLevel.moderatelyActive,
        fitnessStats: defaultStats,
        recentHistory: [], // no history, will just pick the first template normally
        preferredEquipment: [],
      );
      final readiness = WorkoutReadiness(
        status: ReadinessStatus.ready,
        score: 100,
        reasoning: [],
      );

      final rec = generator.generate(
        context: context,
        readiness: readiness,
        library: testLibrary, // w1 is strength
      );

      expect(rec.estimatedEffort, 'High');
      expect(rec.workout.title, contains('Adaptive: Heavy Lifting'));
    });
  });
}
