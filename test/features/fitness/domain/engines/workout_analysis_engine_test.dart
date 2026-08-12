import 'package:flutter_test/flutter_test.dart';

import 'package:healthfit_heal/features/fitness/domain/engines/workout_analysis_engine.dart';
import 'package:healthfit_heal/features/fitness/domain/entities/adaptive/workout_adaptation.dart';
import 'package:healthfit_heal/features/fitness/domain/entities/adaptive/workout_progression.dart';
import 'package:healthfit_heal/features/fitness/domain/entities/workout_entity.dart';
import 'package:healthfit_heal/features/fitness/domain/entities/fitness_stats_entity.dart';
import 'package:healthfit_heal/features/fitness/domain/entities/workout_session_entity.dart';

void main() {
  late WorkoutAnalysisEngine engine;

  setUp(() {
    engine = WorkoutAnalysisEngine();
  });

  group('WorkoutAnalysisEngine', () {
    test('calculateQuality returns 100 for perfect completion', () {
      final workout = WorkoutEntity(
        id: 'w1',
        title: 'W1',
        category: WorkoutCategory.strength,
        difficulty: WorkoutDifficulty.beginner,
        durationMinutes: 30,
        caloriesEstimate: 300,
        exercises: [
          ExerciseEntity(
            id: 'e1',
            name: 'Pushups',
            sets: 3,
            reps: 10,
            restSeconds: 60,
            targetMuscles: ['Chest'],
            instructions: 'Do pushups',
          ),
        ],
        targetMuscles: [],
        equipment: [],
        description: '',
        imageGradientIndex: 0,
      );

      final session = WorkoutSessionEntity(
        workout: workout,
        currentExerciseIndex: 0,
        currentSet: 1,
        elapsedSeconds: 30 * 60, // Exact expected time
        status: SessionStatus.finished,
        completedExerciseIds: ['e1'],
      );

      final quality = engine.calculateQuality(session);
      
      expect(quality.score, 100);
      expect(quality.completionPercentage, 1.0);
    });

    test('calculateQuality penalizes for incomplete exercises', () {
      final workout = WorkoutEntity(
        id: 'w1',
        title: 'W1',
        category: WorkoutCategory.strength,
        difficulty: WorkoutDifficulty.beginner,
        durationMinutes: 30,
        caloriesEstimate: 300,
        exercises: [
          ExerciseEntity(
            id: 'e1',
            name: 'Pushups',
            sets: 3,
            reps: 10,
            restSeconds: 60,
            targetMuscles: ['Chest'],
            instructions: 'Do pushups',
          ),
          ExerciseEntity(
            id: 'e2',
            name: 'Squats',
            sets: 3,
            reps: 10,
            restSeconds: 60,
            targetMuscles: ['Legs'],
            instructions: 'Do squats',
          ),
        ],
        targetMuscles: [],
        equipment: [],
        description: '',
        imageGradientIndex: 0,
      );

      final session = WorkoutSessionEntity(
        workout: workout,
        currentExerciseIndex: 0,
        currentSet: 1,
        elapsedSeconds: 15 * 60, 
        status: SessionStatus.finished,
        completedExerciseIds: ['e1'], // 1 out of 2 completed
      );

      final quality = engine.calculateQuality(session);
      
      expect(quality.completionPercentage, 0.5);
      expect(quality.score, 50);
    });

    test('calculateProgression detects consistency', () {
      final history = [
        WorkoutHistoryEntry(
          id: '1',
          workoutId: 'w1',
          workoutTitle: 'W1',
          category: 'Strength',
          completedAt: DateTime.now().subtract(const Duration(days: 1)),
          durationMinutes: 30,
          caloriesBurned: 300,
          exercisesCompleted: 3,
        ),
        WorkoutHistoryEntry(
          id: '2',
          workoutId: 'w1',
          workoutTitle: 'W1',
          category: 'Strength',
          completedAt: DateTime.now().subtract(const Duration(days: 3)),
          durationMinutes: 30,
          caloriesBurned: 300,
          exercisesCompleted: 3,
        ),
        WorkoutHistoryEntry(
          id: '3',
          workoutId: 'w1',
          workoutTitle: 'W1',
          category: 'Strength',
          completedAt: DateTime.now().subtract(const Duration(days: 5)),
          durationMinutes: 30,
          caloriesBurned: 300,
          exercisesCompleted: 3,
        ),
      ];

      final progression = engine.calculateProgression(history);
      
      expect(progression.state, ProgressionState.improving);
      expect(progression.metrics['Consistency'], 'High');
    });

    test('calculateProgression detects needs attention if inconsistent', () {
      final history = [
        WorkoutHistoryEntry(
          id: '1',
          workoutId: 'w1',
          workoutTitle: 'W1',
          category: 'Strength',
          completedAt: DateTime.now().subtract(const Duration(days: 1)),
          durationMinutes: 30,
          caloriesBurned: 300,
          exercisesCompleted: 3,
        ),
        WorkoutHistoryEntry(
          id: '2',
          workoutId: 'w1',
          workoutTitle: 'W1',
          category: 'Strength',
          completedAt: DateTime.now().subtract(const Duration(days: 10)),
          durationMinutes: 30,
          caloriesBurned: 300,
          exercisesCompleted: 3,
        ),
        WorkoutHistoryEntry(
          id: '3',
          workoutId: 'w1',
          workoutTitle: 'W1',
          category: 'Strength',
          completedAt: DateTime.now().subtract(const Duration(days: 20)), // Very spread out
          durationMinutes: 30,
          caloriesBurned: 300,
          exercisesCompleted: 3,
        ),
      ];

      final progression = engine.calculateProgression(history);
      
      expect(progression.state, ProgressionState.needsAttention);
      expect(progression.metrics['Consistency'], 'Low');
    });
  });
}
