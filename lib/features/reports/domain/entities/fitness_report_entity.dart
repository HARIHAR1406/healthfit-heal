import 'package:flutter/material.dart';

import 'health_report_entity.dart' show DataPoint;

// ══════════════════════════════════════════════════════════════════════════════
// FITNESS REPORT ENTITY
// ══════════════════════════════════════════════════════════════════════════════

/// Category breakdown for a single workout session.
@immutable
class WorkoutCategoryBreakdown {
  const WorkoutCategoryBreakdown({
    required this.category,
    required this.sessions,
    required this.color,
  });
  final String category;
  final int sessions;
  final Color color;
}

/// Day streak summary.
@immutable
class StreakData {
  const StreakData({
    required this.current,
    required this.longest,
    required this.activeDays,
    required this.totalDays,
  });
  final int current;
  final int longest;
  final int activeDays;
  final int totalDays;

  double get completionRate =>
      totalDays == 0 ? 0 : activeDays / totalDays;
}

/// Aggregated fitness analytics for a given date range.
@immutable
class FitnessReportEntity {
  const FitnessReportEntity({
    required this.totalWorkouts,
    required this.workoutsDelta,
    required this.totalCaloriesBurned,
    required this.caloriesBurnedDelta,
    required this.totalActiveMinutes,
    required this.activeMinutesDelta,
    required this.totalDistanceKm,
    required this.distanceDelta,
    required this.avgWorkoutDurationMins,
    required this.durationDelta,
    required this.workoutFrequencySeries,
    required this.caloriesBurnedSeries,
    required this.activeMinutesSeries,
    required this.distanceSeries,
    required this.durationSeries,
    required this.categoryBreakdown,
    required this.streak,
    required this.goalCompletionRate,
    required this.goalCompletionDelta,
    required this.weeklyComparison,
  });

  // ── KPIs ──────────────────────────────────────────────────────────────────
  final int totalWorkouts;
  final int workoutsDelta;
  final double totalCaloriesBurned;
  final double caloriesBurnedDelta;
  final int totalActiveMinutes;
  final int activeMinutesDelta;
  final double totalDistanceKm;
  final double distanceDelta;
  final double avgWorkoutDurationMins;
  final double durationDelta;

  // ── Time Series ────────────────────────────────────────────────────────────
  /// Daily workout count (0 or 1+).
  final List<DataPoint> workoutFrequencySeries;
  final List<DataPoint> caloriesBurnedSeries;
  final List<DataPoint> activeMinutesSeries;
  final List<DataPoint> distanceSeries;
  final List<DataPoint> durationSeries;

  // ── Breakdowns ─────────────────────────────────────────────────────────────
  final List<WorkoutCategoryBreakdown> categoryBreakdown;
  final StreakData streak;

  // ── Goals ─────────────────────────────────────────────────────────────────
  /// 0.0–1.0
  final double goalCompletionRate;
  final double goalCompletionDelta;

  /// [weeklyTarget, weeklyActual] pairs for the last N weeks.
  final List<(double, double)> weeklyComparison;
}

// ══════════════════════════════════════════════════════════════════════════════
// WORKOUT CATEGORY ENUM
// ══════════════════════════════════════════════════════════════════════════════

enum WorkoutCategory {
  strength('Strength', Color(0xFF6C63FF)),
  cardio('Cardio', Color(0xFFFF6B6B)),
  yoga('Yoga', Color(0xFF00C896)),
  hiit('HIIT', Color(0xFFFF9800)),
  flexibility('Flexibility', Color(0xFF00B4D8)),
  sports('Sports', Color(0xFFFFBF00)),
  other('Other', Color(0xFF9C88FF));

  const WorkoutCategory(this.label, this.color);
  final String label;
  final Color color;
}

