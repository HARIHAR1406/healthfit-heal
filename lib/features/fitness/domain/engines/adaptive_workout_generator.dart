import '../entities/workout_entity.dart';
import '../entities/adaptive/workout_context.dart';
import '../entities/adaptive/workout_readiness.dart';
import '../entities/adaptive/recommended_workout.dart';
import 'exercise_recommendation_engine.dart';

/// Engine responsible for generating the tailored workout.
class AdaptiveWorkoutGenerator {
  const AdaptiveWorkoutGenerator(this._exerciseEngine);

  final ExerciseRecommendationEngine _exerciseEngine;

  /// Generates a recommended workout based on readiness and context.
  /// Uses existing library workouts as templates/sources to ensure no
  /// fictional data is created.
  RecommendedWorkout generate({
    required WorkoutContext context,
    required WorkoutReadiness readiness,
    required List<WorkoutEntity> library,
  }) {
    if (library.isEmpty) {
      throw ArgumentError('Workout library cannot be empty.');
    }

    // Default to the first workout as a safe fallback
    WorkoutEntity selectedTemplate = library.first;
    String effort = 'Moderate';
    String reasoning = 'Based on your general fitness goals.';
    int matchScore = 70;

    // Phase 1: Filter by Readiness
    List<WorkoutEntity> candidates = List.of(library);
    if (readiness.status == ReadinessStatus.recover) {
      candidates = library
          .where((w) =>
              w.category == WorkoutCategory.stretching ||
              w.category == WorkoutCategory.yoga ||
              w.category == WorkoutCategory.walking)
          .toList();
      effort = 'Recovery';
      reasoning = 'Your readiness indicates a need for active recovery.';
      matchScore = 90;
    } else if (readiness.status == ReadinessStatus.moderate) {
      candidates = library
          .where((w) =>
              w.difficulty == WorkoutDifficulty.beginner ||
              w.difficulty == WorkoutDifficulty.intermediate)
          .toList();
      effort = 'Moderate';
      reasoning = 'A moderate session is ideal for your current recovery level.';
      matchScore = 85;
    } else if (readiness.status == ReadinessStatus.ready) {
      effort = 'High';
      reasoning = 'You are fully recovered and ready to push your limits.';
      matchScore = 95;
    }

    if (candidates.isEmpty) {
      candidates = List.of(library); // Fallback if filter is too strict
    }

    // Phase 2: Match User Goals to Workout Category
    // Since we don't have a direct enum mapping from HealthGoals to WorkoutCategory,
    // we use a simple heuristic based on the library structure.
    selectedTemplate = candidates.first; // Default
    
    // Simple heuristic: Try to rotate categories based on history
    if (context.hasSufficientHistory) {
      final lastCategory = context.recentHistory.first.category;
      final alternativeCandidates =
          candidates.where((w) => w.category.label != lastCategory).toList();
      if (alternativeCandidates.isNotEmpty) {
        selectedTemplate = alternativeCandidates.first;
        reasoning += ' Switching up from your last $lastCategory session.';
      }
    }

    // Phase 3: Exercise Selection
    // Ensure we don't overwork the same muscles from yesterday
    final recentlyWorked = <String>[];
    if (context.recentHistory.isNotEmpty) {
      // In a real app we'd map history to muscle groups.
      // We will leave this simple for now.
    }

    // We don't reconstruct the entity entirely, we use the template's exercises
    // to strictly prevent inventing fictional exercises. We just filter them if needed.
    final availableExercises = selectedTemplate.exercises;
    final recommendedExercises = _exerciseEngine.selectForGoal(
      available: availableExercises,
      goalCategory: selectedTemplate.category,
      maxExercises: availableExercises.length, // use all for now
      recentlyWorkedMuscles: recentlyWorked,
    );

    // Create the tailored workout based strictly on the library template
    final tailoredWorkout = WorkoutEntity(
      id: '${selectedTemplate.id}_adapted',
      title: 'Adaptive: ${selectedTemplate.title}',
      category: selectedTemplate.category,
      difficulty: selectedTemplate.difficulty,
      durationMinutes: selectedTemplate.durationMinutes,
      caloriesEstimate: selectedTemplate.caloriesEstimate,
      exercises: recommendedExercises,
      targetMuscles: selectedTemplate.targetMuscles,
      equipment: selectedTemplate.equipment,
      description: 'An intelligently adapted version of ${selectedTemplate.title}.',
      imageGradientIndex: selectedTemplate.imageGradientIndex,
      isFavorite: false,
      rating: selectedTemplate.rating,
      totalRatings: selectedTemplate.totalRatings,
    );

    return RecommendedWorkout(
      workout: tailoredWorkout,
      matchScore: matchScore,
      estimatedEffort: effort,
      primaryReasoning: reasoning,
    );
  }
}

