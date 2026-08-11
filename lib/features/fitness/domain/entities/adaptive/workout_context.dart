import '../../../../../core/trust/domain/entities/meal_nutrition_result.dart';
import '../../../../profile/domain/entities/profile_entity.dart';
import '../fitness_stats_entity.dart';

/// Synthesized snapshot of the user's current fitness and recovery state.
class WorkoutContext {
  const WorkoutContext({
    required this.userGoals,
    required this.activityLevel,
    required this.fitnessStats,
    required this.recentHistory,
    required this.preferredEquipment,
    this.latestNutritionResult,
  });

  /// The user's long-term health goals.
  final HealthGoals userGoals;

  /// The user's baseline activity level.
  final ActivityLevel activityLevel;

  /// Aggregated fitness statistics (streaks, frequency).
  final FitnessStatsEntity fitnessStats;

  /// Recent workout history (usually last 7-14 days).
  final List<WorkoutHistoryEntry> recentHistory;

  /// User's available or preferred equipment.
  final List<String> preferredEquipment;

  /// Trusted nutrition data from Phase 12 (optional context).
  final MealNutritionResult? latestNutritionResult;

  /// Determines if the user has enough history to make informed adaptations.
  bool get hasSufficientHistory => recentHistory.length >= 3;
}
