import 'package:flutter/material.dart';

import 'health_report_entity.dart' show DataPoint;

// ══════════════════════════════════════════════════════════════════════════════
// TOPIC FREQUENCY
// ══════════════════════════════════════════════════════════════════════════════

/// Frequency of a particular topic in AI conversations.
@immutable
class TopicFrequency {
  const TopicFrequency({
    required this.topic,
    required this.count,
    required this.color,
  });
  final String topic;
  final int count;
  final Color color;
}

// ══════════════════════════════════════════════════════════════════════════════
// COACH USAGE
// ══════════════════════════════════════════════════════════════════════════════

/// Aggregated usage for a single AI coaching domain.
@immutable
class CoachUsage {
  const CoachUsage({
    required this.coachType,
    required this.sessions,
    required this.messages,
    required this.color,
    required this.emoji,
  });
  final String coachType;
  final int sessions;
  final int messages;
  final Color color;
  final String emoji;
}

// ══════════════════════════════════════════════════════════════════════════════
// WEEKLY AI INSIGHT
// ══════════════════════════════════════════════════════════════════════════════

/// A single weekly AI-generated insight.
@immutable
class WeeklyAIInsight {
  const WeeklyAIInsight({
    required this.weekStart,
    required this.title,
    required this.summary,
    required this.category,
    required this.color,
  });
  final DateTime weekStart;
  final String title;
  final String summary;
  final String category;
  final Color color;
}

// ══════════════════════════════════════════════════════════════════════════════
// AI REPORT ENTITY
// ══════════════════════════════════════════════════════════════════════════════

/// Aggregated AI assistant analytics for a given date range.
@immutable
class AIReportEntity {
  const AIReportEntity({
    required this.totalSessions,
    required this.sessionsDelta,
    required this.totalMessages,
    required this.messagesDelta,
    required this.avgSessionDurationMins,
    required this.durationDelta,
    required this.totalInsightsGenerated,
    required this.insightsDelta,
    required this.sessionsSeries,
    required this.messagesSeries,
    required this.responseLengthSeries,
    required this.topicFrequency,
    required this.coachUsage,
    required this.weeklyInsights,
    required this.avgResponseQualityScore,
    required this.recommendationsGenerated,
    required this.mostUsedCoach,
    required this.topTopic,
  });

  // ── KPIs ──────────────────────────────────────────────────────────────────
  final int totalSessions;
  final int sessionsDelta;
  final int totalMessages;
  final int messagesDelta;
  final double avgSessionDurationMins;
  final double durationDelta;
  final int totalInsightsGenerated;
  final int insightsDelta;

  // ── Time Series ────────────────────────────────────────────────────────────
  final List<DataPoint> sessionsSeries;
  final List<DataPoint> messagesSeries;

  /// Average response length in words, per day.
  final List<DataPoint> responseLengthSeries;

  // ── Breakdowns ─────────────────────────────────────────────────────────────
  final List<TopicFrequency> topicFrequency;
  final List<CoachUsage> coachUsage;
  final List<WeeklyAIInsight> weeklyInsights;

  // ── Quality ───────────────────────────────────────────────────────────────
  /// 0–100
  final double avgResponseQualityScore;
  final int recommendationsGenerated;

  // ── Summary ───────────────────────────────────────────────────────────────
  final String mostUsedCoach;
  final String topTopic;
}

