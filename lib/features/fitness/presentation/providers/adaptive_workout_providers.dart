import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/engines/adaptive_workout_generator.dart';
import '../../domain/engines/exercise_recommendation_engine.dart';
import '../../domain/engines/workout_analysis_engine.dart';
import '../../domain/engines/workout_readiness_engine.dart';
import '../../domain/entities/adaptive/recommended_workout.dart';
import '../../domain/entities/adaptive/workout_context.dart';
import '../../domain/entities/adaptive/workout_readiness.dart';
import 'fitness_providers.dart';
import 'fitness_state.dart';

// ── Engines ─────────────────────────────────────────────────────────────────

final workoutReadinessEngineProvider = Provider<WorkoutReadinessEngine>(
  (ref) => WorkoutReadinessEngine(),
);

final exerciseRecommendationEngineProvider = Provider<ExerciseRecommendationEngine>(
  (ref) => ExerciseRecommendationEngine(),
);

final adaptiveWorkoutGeneratorProvider = Provider<AdaptiveWorkoutGenerator>(
  (ref) => AdaptiveWorkoutGenerator(ref.watch(exerciseRecommendationEngineProvider)),
);

final workoutAnalysisEngineProvider = Provider<WorkoutAnalysisEngine>(
  (ref) => WorkoutAnalysisEngine(),
);

// ── Context ─────────────────────────────────────────────────────────────────

final workoutContextProvider = Provider<WorkoutContext?>((ref) {
  final profile = ref.watch(currentProfileProvider);
  final fitnessData = ref.watch(fitnessLoadedDataProvider);
  final history = ref.watch(recentWorkoutHistoryProvider);

  if (profile == null || fitnessData == null) return null;

  return WorkoutContext(
    userGoals: profile.goals,
    activityLevel: profile.activityLevel,
    fitnessStats: fitnessData.stats,
    recentHistory: history,
    preferredEquipment: [], // Mock preference
  );
});

// ── Readiness & Recommendation ──────────────────────────────────────────────

final workoutReadinessProvider = Provider<WorkoutReadiness?>((ref) {
  final context = ref.watch(workoutContextProvider);
  if (context == null) return null;

  final engine = ref.watch(workoutReadinessEngineProvider);
  return engine.evaluate(context);
});

final recommendedWorkoutProvider = Provider<RecommendedWorkout?>((ref) {
  final context = ref.watch(workoutContextProvider);
  final readiness = ref.watch(workoutReadinessProvider);
  final library = ref.watch(allWorkoutsProvider);

  if (context == null || readiness == null || library.isEmpty) return null;

  final generator = ref.watch(adaptiveWorkoutGeneratorProvider);
  try {
    return generator.generate(
      context: context,
      readiness: readiness,
      library: library,
    );
  } catch (e) {
    // If library is empty or generation fails
    return null;
  }
});

// ── Post-Workout Analysis ───────────────────────────────────────────────────

final postWorkoutAnalysisProvider = Provider((ref) {
  final sessionState = ref.watch(workoutSessionProvider);
  final analysisEngine = ref.watch(workoutAnalysisEngineProvider);
  
  if (sessionState is! SessionFinished) return null;
  
  final session = sessionState.session;
  final history = ref.read(recentWorkoutHistoryProvider);
  
  final quality = analysisEngine.calculateQuality(session);
  final progression = analysisEngine.calculateProgression(history);
  final adaptation = analysisEngine.adaptNextSession(quality, session);
  
  return {
    'quality': quality,
    'progression': progression,
    'adaptation': adaptation,
  };
});

