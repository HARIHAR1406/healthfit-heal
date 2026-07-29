import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/entities/ai_report_entity.dart';
import '../../domain/entities/health_report_entity.dart' show DataPoint;

// ══════════════════════════════════════════════════════════════════════════════
// AI MOCK DATA
// ══════════════════════════════════════════════════════════════════════════════

/// Generates 90 days of realistic AI assistant usage mock data.
class AIMockData {
  AIMockData._();

  static final _rng = Random(45);

  static double _noise(double sigma) =>
      (_rng.nextDouble() + _rng.nextDouble() + _rng.nextDouble() - 1.5) *
      sigma;

  // ── Time series ───────────────────────────────────────────────────────────

  static List<DataPoint> sessionsSeries(int days) {
    final today = DateTime.now();
    return List.generate(days, (i) {
      final date = today.subtract(Duration(days: days - 1 - i));
      final sessions = (_rng.nextDouble() > 0.25)
          ? (1 + _noise(0.8)).clamp(0, 4).round().toDouble()
          : 0.0;
      return DataPoint(date: date, value: sessions);
    });
  }

  static List<DataPoint> messagesSeries(int days) {
    final today = DateTime.now();
    return List.generate(days, (i) {
      final date = today.subtract(Duration(days: days - 1 - i));
      final msgs =
          (8 + sin(i * pi / 7) * 4 + _noise(3)).clamp(0.0, 25.0);
      return DataPoint(date: date, value: double.parse(msgs.toStringAsFixed(0)));
    });
  }

  static List<DataPoint> responseLengthSeries(int days) {
    final today = DateTime.now();
    return List.generate(days, (i) {
      final date = today.subtract(Duration(days: days - 1 - i));
      final words = (85 + _noise(20)).clamp(40.0, 160.0);
      return DataPoint(date: date, value: double.parse(words.toStringAsFixed(0)));
    });
  }

  // ── Topic frequency ───────────────────────────────────────────────────────

  static List<TopicFrequency> topicFrequency(int totalMessages) {
    final topics = [
      ('Workout Tips', 0.22, const Color(0xFF6C63FF)),
      ('Diet & Nutrition', 0.18, const Color(0xFFFF6B6B)),
      ('Mental Wellness', 0.15, const Color(0xFF00C896)),
      ('Sleep Quality', 0.13, const Color(0xFF00B4D8)),
      ('Weight Loss', 0.12, const Color(0xFFFFBF00)),
      ('Medical Questions', 0.10, const Color(0xFFFF6BB5)),
      ('Goal Setting', 0.10, const Color(0xFF9C88FF)),
    ];
    return topics.map((t) {
      final (name, pct, color) = t;
      return TopicFrequency(
        topic: name,
        count: (totalMessages * pct).round(),
        color: color,
      );
    }).toList();
  }

  // ── Coach usage ───────────────────────────────────────────────────────────

  static List<CoachUsage> coachUsage(int totalSessions) {
    final coaches = [
      ('Fitness', 0.30, const Color(0xFF00C896), '🏋️'),
      ('Nutrition', 0.25, const Color(0xFFFF9800), '🥗'),
      ('General', 0.20, const Color(0xFF6C63FF), '🤖'),
      ('Health', 0.15, const Color(0xFFFF6B6B), '❤️'),
      ('Lifestyle', 0.10, const Color(0xFF00B4D8), '🌿'),
    ];
    return coaches.map((c) {
      final (name, pct, color, emoji) = c;
      final sessions = (totalSessions * pct).round();
      return CoachUsage(
        coachType: name,
        sessions: sessions,
        messages: (sessions * (5 + _noise(2))).round(),
        color: color,
        emoji: emoji,
      );
    }).toList();
  }

  // ── Weekly insights ───────────────────────────────────────────────────────

  static List<WeeklyAIInsight> weeklyInsights(int weeks) {
    final insights = [
      (
        'Cardio Improvement Detected',
        'Your resting heart rate dropped 3 bpm this week — a strong sign of improving cardiovascular fitness.',
        'Fitness',
        const Color(0xFF00C896),
      ),
      (
        'Hydration Gap Found',
        'You logged below 2L water on 4 days this week. Consistent hydration supports metabolism and recovery.',
        'Nutrition',
        const Color(0xFF00B4D8),
      ),
      (
        'Protein Target Achieved',
        'You hit your protein goal on 6 out of 7 days. Excellent consistency for muscle maintenance.',
        'Nutrition',
        const Color(0xFF6C63FF),
      ),
      (
        'Rest Day Optimisation',
        'Adding a 10-min stretch on rest days reduces next-session soreness by ~20%. Try it tomorrow.',
        'Fitness',
        const Color(0xFFFF9800),
      ),
      (
        'Blood Sugar Stable',
        'Blood sugar readings stayed in range all week. Keep up your meal timing consistency.',
        'Health',
        const Color(0xFFFF6B6B),
      ),
      (
        'Sleep Consistency Win',
        'You maintained a consistent sleep window 5 nights this week, improving REM quality.',
        'Lifestyle',
        const Color(0xFF9C88FF),
      ),
    ];

    final today = DateTime.now();
    return List.generate(weeks.clamp(0, insights.length), (i) {
      final (title, summary, category, color) = insights[i];
      return WeeklyAIInsight(
        weekStart: today.subtract(Duration(days: (i + 1) * 7)),
        title: title,
        summary: summary,
        category: category,
        color: color,
      );
    });
  }
}
