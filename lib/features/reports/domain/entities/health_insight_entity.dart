import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════════
// INSIGHT CATEGORY
// ══════════════════════════════════════════════════════════════════════════════

/// Categories that an AI-generated health insight can belong to.
enum InsightCategory {
  cardiovascular('Cardiovascular', Icons.favorite_rounded, Color(0xFFFF6B6B)),
  fitness('Fitness', Icons.fitness_center_rounded, Color(0xFF00C896)),
  nutrition('Nutrition', Icons.restaurant_rounded, Color(0xFF6C63FF)),
  sleep('Sleep', Icons.bedtime_rounded, Color(0xFF00B4D8)),
  mental('Mental Health', Icons.psychology_rounded, Color(0xFFFF9800)),
  weight('Weight', Icons.monitor_weight_rounded, Color(0xFFFFBF00)),
  medication('Medication', Icons.medication_rounded, Color(0xFFFF5252)),
  general('General', Icons.insights_rounded, Color(0xFF9C88FF));

  const InsightCategory(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

// ══════════════════════════════════════════════════════════════════════════════
// INSIGHT PRIORITY
// ══════════════════════════════════════════════════════════════════════════════

enum InsightPriority {
  critical('Critical', Color(0xFFFF3D00)),
  high('High', Color(0xFFFF6B6B)),
  medium('Medium', Color(0xFFFFBF00)),
  low('Low', Color(0xFF00C896)),
  positive('Positive', Color(0xFF6C63FF));

  const InsightPriority(this.label, this.color);
  final String label;
  final Color color;
}

// ══════════════════════════════════════════════════════════════════════════════
// INSIGHT TYPE
// ══════════════════════════════════════════════════════════════════════════════

enum InsightType {
  daily('Daily Insight'),
  weekly('Weekly Insight'),
  monthly('Monthly Insight'),
  trend('Trend Detection'),
  riskAlert('Risk Alert'),
  recommendation('Recommendation'),
  achievement('Achievement');

  const InsightType(this.label);
  final String label;
}

// ══════════════════════════════════════════════════════════════════════════════
// HEALTH INSIGHT ENTITY
// ══════════════════════════════════════════════════════════════════════════════

/// A single AI-generated health insight or recommendation.
@immutable
class HealthInsightEntity {
  const HealthInsightEntity({
    required this.id,
    required this.type,
    required this.category,
    required this.priority,
    required this.title,
    required this.summary,
    required this.detail,
    required this.generatedAt,
    required this.isRead,
    this.actionLabel,
    this.actionRoute,
    this.relatedMetricValue,
    this.relatedMetricUnit,
    this.relatedMetricDelta,
    this.confidence,
    this.sources,
  });

  final String id;
  final InsightType type;
  final InsightCategory category;
  final InsightPriority priority;
  final String title;
  final String summary;
  final String detail;
  final DateTime generatedAt;
  final bool isRead;

  /// Optional CTA label e.g. "View Heart Rate"
  final String? actionLabel;
  final String? actionRoute;

  /// The primary metric value the insight is based on.
  final double? relatedMetricValue;
  final String? relatedMetricUnit;
  final double? relatedMetricDelta;

  /// AI confidence score 0.0–1.0
  final double? confidence;

  /// Data sources used to generate this insight
  final List<String>? sources;

  bool get isPositive =>
      priority == InsightPriority.positive ||
      type == InsightType.achievement;

  bool get isAlert =>
      priority == InsightPriority.critical ||
      priority == InsightPriority.high ||
      type == InsightType.riskAlert;

  HealthInsightEntity copyWith({bool? isRead}) => HealthInsightEntity(
        id: id,
        type: type,
        category: category,
        priority: priority,
        title: title,
        summary: summary,
        detail: detail,
        generatedAt: generatedAt,
        isRead: isRead ?? this.isRead,
        actionLabel: actionLabel,
        actionRoute: actionRoute,
        relatedMetricValue: relatedMetricValue,
        relatedMetricUnit: relatedMetricUnit,
        relatedMetricDelta: relatedMetricDelta,
        confidence: confidence,
        sources: sources,
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// INSIGHTS REPORT (aggregation)
// ══════════════════════════════════════════════════════════════════════════════

/// Aggregated collection of all AI insights for a period.
@immutable
class InsightsReport {
  const InsightsReport({
    required this.insights,
    required this.totalInsights,
    required this.unreadCount,
    required this.criticalCount,
    required this.positiveCount,
    required this.lastGeneratedAt,
  });

  final List<HealthInsightEntity> insights;
  final int totalInsights;
  final int unreadCount;
  final int criticalCount;
  final int positiveCount;
  final DateTime lastGeneratedAt;

  List<HealthInsightEntity> get dailyInsights =>
      insights.where((i) => i.type == InsightType.daily).toList();

  List<HealthInsightEntity> get weeklyInsights =>
      insights.where((i) => i.type == InsightType.weekly).toList();

  List<HealthInsightEntity> get monthlyInsights =>
      insights.where((i) => i.type == InsightType.monthly).toList();

  List<HealthInsightEntity> get riskAlerts =>
      insights.where((i) => i.isAlert).toList();

  List<HealthInsightEntity> get recommendations =>
      insights.where((i) => i.type == InsightType.recommendation).toList();

  List<HealthInsightEntity> get achievements =>
      insights.where((i) => i.type == InsightType.achievement).toList();

  /// Insights grouped by category.
  Map<InsightCategory, List<HealthInsightEntity>> get byCategory {
    final map = <InsightCategory, List<HealthInsightEntity>>{};
    for (final ins in insights) {
      map.putIfAbsent(ins.category, () => []).add(ins);
    }
    return map;
  }
}
