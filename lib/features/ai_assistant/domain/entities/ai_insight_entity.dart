import 'package:flutter/material.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

/// Type classification of an AI insight.
enum InsightType {
  sleep,
  heartRate,
  water,
  workout,
  nutrition,
  weekly,
  alert,
  achievement,
}

extension InsightTypeX on InsightType {
  String get label => switch (this) {
        InsightType.sleep => 'Sleep',
        InsightType.heartRate => 'Heart Rate',
        InsightType.water => 'Hydration',
        InsightType.workout => 'Workout',
        InsightType.nutrition => 'Nutrition',
        InsightType.weekly => 'Weekly',
        InsightType.alert => 'Alert',
        InsightType.achievement => 'Achievement',
      };

  IconData get icon => switch (this) {
        InsightType.sleep => Icons.bedtime_rounded,
        InsightType.heartRate => Icons.favorite_rounded,
        InsightType.water => Icons.water_drop_rounded,
        InsightType.workout => Icons.fitness_center_rounded,
        InsightType.nutrition => Icons.restaurant_rounded,
        InsightType.weekly => Icons.insights_rounded,
        InsightType.alert => Icons.warning_amber_rounded,
        InsightType.achievement => Icons.emoji_events_rounded,
      };

  Color get color => switch (this) {
        InsightType.sleep => const Color(0xFF00B4D8),
        InsightType.heartRate => const Color(0xFFFF6B6B),
        InsightType.water => const Color(0xFF00C896),
        InsightType.workout => const Color(0xFF6C63FF),
        InsightType.nutrition => const Color(0xFFFFBF00),
        InsightType.weekly => const Color(0xFF4CAF50),
        InsightType.alert => const Color(0xFFFF9800),
        InsightType.achievement => const Color(0xFFFF6BB5),
      };
}

/// Priority level of an insight.
enum InsightPriority {
  low,
  medium,
  high,
  critical,
}

extension InsightPriorityX on InsightPriority {
  Color get badgeColor => switch (this) {
        InsightPriority.low => const Color(0xFF4CAF50),
        InsightPriority.medium => const Color(0xFFFFBF00),
        InsightPriority.high => const Color(0xFFFF9800),
        InsightPriority.critical => const Color(0xFFFF6B6B),
      };

  String get label => switch (this) {
        InsightPriority.low => 'Low',
        InsightPriority.medium => 'Medium',
        InsightPriority.high => 'High',
        InsightPriority.critical => 'Critical',
      };
}

/// Trend direction for a metric.
enum InsightTrend { up, down, stable }

extension InsightTrendX on InsightTrend {
  IconData get icon => switch (this) {
        InsightTrend.up => Icons.trending_up_rounded,
        InsightTrend.down => Icons.trending_down_rounded,
        InsightTrend.stable => Icons.trending_flat_rounded,
      };
}

// ── Entity ────────────────────────────────────────────────────────────────────

/// An AI-generated health/fitness insight card.
class AIInsightEntity {
  const AIInsightEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.priority,
    required this.timestamp,
    this.metric,
    this.metricValue,
    this.metricUnit,
    this.trend = InsightTrend.stable,
    this.actionLabel,
    this.actionRoute,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final InsightType type;
  final InsightPriority priority;
  final DateTime timestamp;

  /// Optional metric name (e.g., 'Heart Rate', 'Steps').
  final String? metric;
  final String? metricValue;
  final String? metricUnit;
  final InsightTrend trend;

  /// CTA label (e.g., 'View Heart Rate', 'Log Water').
  final String? actionLabel;

  /// GoRouter path to navigate to on action tap.
  final String? actionRoute;

  final bool isRead;

  AIInsightEntity copyWith({bool? isRead}) => AIInsightEntity(
        id: id,
        title: title,
        body: body,
        type: type,
        priority: priority,
        timestamp: timestamp,
        metric: metric,
        metricValue: metricValue,
        metricUnit: metricUnit,
        trend: trend,
        actionLabel: actionLabel,
        actionRoute: actionRoute,
        isRead: isRead ?? this.isRead,
      );
}
