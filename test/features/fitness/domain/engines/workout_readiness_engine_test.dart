import 'package:flutter_test/flutter_test.dart';

import 'package:healthfit_heal/features/fitness/domain/engines/workout_readiness_engine.dart';
import 'package:healthfit_heal/features/fitness/domain/entities/adaptive/workout_context.dart';
import 'package:healthfit_heal/features/fitness/domain/entities/adaptive/workout_readiness.dart';
import 'package:healthfit_heal/features/fitness/domain/entities/fitness_stats_entity.dart';
import 'package:healthfit_heal/features/fitness/domain/entities/workout_entity.dart';
import 'package:healthfit_heal/features/profile/domain/entities/profile_entity.dart';

void main() {
  late WorkoutReadinessEngine engine;

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

  setUp(() {
    engine = WorkoutReadinessEngine();
  });

  group('WorkoutReadinessEngine', () {
    test('returns insufficientData when history is < 3 workouts', () {
      final context = WorkoutContext(
        userGoals: defaultGoals,
        activityLevel: ActivityLevel.moderatelyActive,
        fitnessStats: defaultStats,
        recentHistory: [
          WorkoutHistoryEntry(
            id: '1',
            workoutId: 'w1',
            workoutTitle: 'W1',
            category: 'Strength',
            completedAt: DateTime.now().subtract(const Duration(days: 1)),
            durationMinutes: 30,
            caloriesBurned: 300,
            exercisesCompleted: 3,
          )
        ],
        preferredEquipment: [],
      );

      final result = engine.evaluate(context);
      
      expect(result.status, ReadinessStatus.insufficientData);
      expect(result.score, isNull);
    });

    test('returns recover if last workout was < 12 hours ago', () {
      final context = WorkoutContext(
        userGoals: defaultGoals,
        activityLevel: ActivityLevel.moderatelyActive,
        fitnessStats: defaultStats,
        recentHistory: List.generate(3, (i) => WorkoutHistoryEntry(
            id: '$i',
            workoutId: 'w1',
            workoutTitle: 'W1',
            category: 'Strength',
            completedAt: DateTime.now().subtract(Duration(hours: i == 0 ? 5 : 24 + i)), // 5 hours ago
            durationMinutes: 30,
            caloriesBurned: 300,
            exercisesCompleted: 3,
          )
        ),
        preferredEquipment: [],
      );

      final result = engine.evaluate(context);
      
      expect(result.status, ReadinessStatus.recover);
      expect(result.score, lessThan(50));
    });

    test('returns moderate if weekly goal already met', () {
      final goals = defaultGoals.copyWith(weeklyWorkoutsTarget: 3);
      final stats = FitnessStatsEntity(
        totalWorkouts: 10,
        totalMinutes: 300,
        totalCalories: 3000,
        currentStreak: 2,
        longestStreak: 5,
        weeklyWorkouts: 3, // Met target
        weeklyCalories: 600,
        weeklyMinutes: 60,
        weeklyDistance: 0,
        weeklyCaloriesData: [],
        weeklyMinutesData: [],
        weeklyFrequencyData: [],
        monthlyCaloriesData: [],
      );

      final context = WorkoutContext(
        userGoals: goals,
        activityLevel: ActivityLevel.moderatelyActive,
        fitnessStats: stats,
        recentHistory: List.generate(3, (i) => WorkoutHistoryEntry(
            id: '$i',
            workoutId: 'w1',
            workoutTitle: 'W1',
            category: 'Strength',
            completedAt: DateTime.now().subtract(Duration(hours: 48 + i * 24)), // > 48 hours ago, so normally 'ready'
            durationMinutes: 30,
            caloriesBurned: 300,
            exercisesCompleted: 3,
          )
        ),
        preferredEquipment: [],
      );

      final result = engine.evaluate(context);
      
      expect(result.status, ReadinessStatus.moderate);
      expect(result.reasoning.any((r) => r.contains('weekly goal')), isTrue);
    });

    test('returns ready when fully rested and goals not met', () {
       final context = WorkoutContext(
        userGoals: defaultGoals,
        activityLevel: ActivityLevel.moderatelyActive,
        fitnessStats: defaultStats, // 2 weekly workouts (target 3)
        recentHistory: List.generate(3, (i) => WorkoutHistoryEntry(
            id: '$i',
            workoutId: 'w1',
            workoutTitle: 'W1',
            category: 'Strength',
            completedAt: DateTime.now().subtract(Duration(hours: 48 + i * 24)), // 48 hours ago
            durationMinutes: 30,
            caloriesBurned: 300,
            exercisesCompleted: 3,
          )
        ),
        preferredEquipment: [],
      );

      final result = engine.evaluate(context);
      
      expect(result.status, ReadinessStatus.ready);
      expect(result.score, 100);
    });
  });
}
