import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/entities/fitness_report_entity.dart';
import '../../domain/entities/health_report_entity.dart' show DataPoint;

// ══════════════════════════════════════════════════════════════════════════════
// FITNESS MOCK DATA
// ══════════════════════════════════════════════════════════════════════════════

/// Generates 90 days of realistic fitness activity mock data.
class FitnessMockData {
  FitnessMockData._();

  static final _rng = Random(43);

  static double _noise(double sigma) =>
      (_rng.nextDouble() + _rng.nextDouble() + _rng.nextDouble() - 1.5) *
      sigma;

  // ── Active day generator ──────────────────────────────────────────────────

  /// Returns true if a given day index should be an active workout day.
  /// Simulates 4–5 workouts/week with some rest days.
  static bool _isActiveDay(int dayIndex) {
    final dayOfWeek = dayIndex % 7;
    // Rest days: every Sunday (6) and random Wednesday (3 ~40% chance)
    if (dayOfWeek == 6) return false;
    if (dayOfWeek == 3) return _rng.nextDouble() > 0.4;
    return _rng.nextDouble() > 0.15;
  }

  // ── Time series ───────────────────────────────────────────────────────────

  static List<DataPoint> workoutFrequencySeries(int days) {
    final today = DateTime.now();
    return List.generate(days, (i) {
      final date = today.subtract(Duration(days: days - 1 - i));
      return DataPoint(date: date, value: _isActiveDay(i) ? 1 : 0);
    });
  }

  static List<DataPoint> caloriesBurnedSeries(int days) {
    final today = DateTime.now();
    return List.generate(days, (i) {
      final date = today.subtract(Duration(days: days - 1 - i));
      final active = _isActiveDay(i);
      final cal = active
          ? (350 + sin(i * pi / 14) * 80 + _noise(40)).clamp(150.0, 700.0)
          : (_noise(30) + 60).clamp(30.0, 120.0);
      return DataPoint(date: date, value: double.parse(cal.toStringAsFixed(0)));
    });
  }

  static List<DataPoint> activeMinutesSeries(int days) {
    final today = DateTime.now();
    return List.generate(days, (i) {
      final date = today.subtract(Duration(days: days - 1 - i));
      final active = _isActiveDay(i);
      final mins = active
          ? (45 + _noise(12)).clamp(20.0, 90.0)
          : (_noise(8) + 10).clamp(0.0, 25.0);
      return DataPoint(date: date, value: double.parse(mins.toStringAsFixed(0)));
    });
  }

  static List<DataPoint> distanceSeries(int days) {
    final today = DateTime.now();
    return List.generate(days, (i) {
      final date = today.subtract(Duration(days: days - 1 - i));
      final active = _isActiveDay(i);
      final km = active
          ? (5.2 + sin(i * pi / 10) * 2 + _noise(1.2)).clamp(2.0, 15.0)
          : 0.0;
      return DataPoint(date: date, value: double.parse(km.toStringAsFixed(2)));
    });
  }

  static List<DataPoint> durationSeries(int days) {
    final today = DateTime.now();
    return List.generate(days, (i) {
      final date = today.subtract(Duration(days: days - 1 - i));
      final active = _isActiveDay(i);
      final mins = active
          ? (50 + _noise(15)).clamp(20.0, 90.0)
          : 0.0;
      return DataPoint(date: date, value: double.parse(mins.toStringAsFixed(0)));
    });
  }

  // ── Category breakdown ────────────────────────────────────────────────────

  static List<WorkoutCategoryBreakdown> categoryBreakdown(int activeDays) {
    return [
      WorkoutCategoryBreakdown(
        category: 'Strength',
        sessions: (activeDays * 0.35).round(),
        color: WorkoutCategory.strength.color,
      ),
      WorkoutCategoryBreakdown(
        category: 'Cardio',
        sessions: (activeDays * 0.25).round(),
        color: WorkoutCategory.cardio.color,
      ),
      WorkoutCategoryBreakdown(
        category: 'HIIT',
        sessions: (activeDays * 0.20).round(),
        color: WorkoutCategory.hiit.color,
      ),
      WorkoutCategoryBreakdown(
        category: 'Yoga',
        sessions: (activeDays * 0.12).round(),
        color: WorkoutCategory.yoga.color,
      ),
      WorkoutCategoryBreakdown(
        category: 'Other',
        sessions: (activeDays * 0.08).round(),
        color: WorkoutCategory.other.color,
      ),
    ];
  }

  // ── Streak ────────────────────────────────────────────────────────────────

  static StreakData computeStreak(
      List<DataPoint> frequencySeries, int totalDays) {
    int current = 0;
    int longest = 0;
    int running = 0;
    int activeDays = 0;

    for (final p in frequencySeries.reversed) {
      if (p.value > 0) {
        running++;
        activeDays++;
        if (running > longest) longest = running;
        // current streak only counts from today backwards continuously
        if (current == running - 1) current = running;
      } else {
        running = 0;
      }
    }

    return StreakData(
      current: current,
      longest: longest,
      activeDays: activeDays,
      totalDays: totalDays,
    );
  }

  // ── Weekly comparison ─────────────────────────────────────────────────────

  /// Returns (target, actual) pairs for the last N complete weeks.
  static List<(double, double)> weeklyComparison(
      List<DataPoint> calSeries, int weeks) {
    final result = <(double, double)>[];
    const weekTarget = 2500.0; // weekly calorie burn target
    for (var w = weeks - 1; w >= 0; w--) {
      final start = calSeries.length - (w + 1) * 7;
      final end = start + 7;
      if (start < 0) continue;
      final slice = calSeries.sublist(start.clamp(0, calSeries.length),
          end.clamp(0, calSeries.length));
      final actual = slice.fold(0.0, (s, p) => s + p.value);
      result.add((weekTarget, actual));
    }
    return result;
  }
}
