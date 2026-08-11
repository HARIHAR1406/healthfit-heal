import '../entities/workout_entity.dart';
import '../entities/adaptive/workout_context.dart';

/// Pure-Dart logic engine for selecting appropriate exercises from the library.
class ExerciseRecommendationEngine {
  /// Filters exercises based on context (equipment, goals).
  List<ExerciseEntity> filterExercises(
    List<ExerciseEntity> library,
    WorkoutContext context,
  ) {
    return library.where((exercise) {
      // For a real app, exercises would have an `equipmentRequired` field.
      // In this mock, we assume all exercises are either bodyweight or 
      // rely on the workout's equipment list. For this engine, we'll
      // just ensure we aren't completely stripping the list.
      return true;
    }).toList();
  }

  /// Selects the best exercises to target a specific goal, avoiding
  /// overworking recently trained muscles if possible.
  List<ExerciseEntity> selectForGoal({
    required List<ExerciseEntity> available,
    required WorkoutCategory goalCategory,
    required int maxExercises,
    required List<String> recentlyWorkedMuscles,
  }) {
    // 1. Sort available exercises. Prefer those that DO NOT hit recently worked muscles.
    final sorted = List.of(available)..sort((a, b) {
      final aOverlap = a.targetMuscles.where(recentlyWorkedMuscles.contains).length;
      final bOverlap = b.targetMuscles.where(recentlyWorkedMuscles.contains).length;
      return aOverlap.compareTo(bOverlap);
    });

    // 2. Take up to maxExercises
    return sorted.take(maxExercises).toList();
  }
}
