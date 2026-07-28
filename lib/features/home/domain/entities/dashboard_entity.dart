import 'activity_item_entity.dart';
import 'health_metric_entity.dart';
import 'progress_item_entity.dart';
import 'quick_action_entity.dart';

/// Aggregated dashboard data for one user session.
class DashboardEntity {
  const DashboardEntity({
    required this.greeting,
    required this.motivationalQuote,
    required this.wellnessScore,
    required this.notificationCount,
    required this.metrics,
    required this.quickActions,
    required this.recentActivities,
    required this.todayProgress,
    required this.currentDate,
  });

  /// Contextual greeting, e.g. "Good Morning".
  final String greeting;

  /// Daily motivational quote.
  final String motivationalQuote;

  /// Aggregate wellness score out of 100.
  final int wellnessScore;

  /// Number of unread notifications for the badge.
  final int notificationCount;

  /// Health metric cards (BMI, Heart Rate, Steps, Water, Sleep).
  final List<HealthMetricEntity> metrics;

  /// Quick-action shortcuts grid (Health, Fitness, etc.).
  final List<QuickActionEntity> quickActions;

  /// Today's progress rings (Workout, Calories, Water, Sleep, Medication).
  final List<ProgressItemEntity> todayProgress;

  /// Recent activity timeline.
  final List<ActivityItemEntity> recentActivities;

  /// Pre-formatted current date string, e.g. "Monday, 28 July".
  final String currentDate;

  /// Wellness status label derived from [wellnessScore].
  String get wellnessLabel {
    if (wellnessScore >= 90) return 'Excellent';
    if (wellnessScore >= 75) return 'Good';
    if (wellnessScore >= 55) return 'Fair';
    return 'Needs attention';
  }

  /// Wellness fraction for progress widgets (0.0 – 1.0).
  double get wellnessFraction => wellnessScore / 100.0;
}
