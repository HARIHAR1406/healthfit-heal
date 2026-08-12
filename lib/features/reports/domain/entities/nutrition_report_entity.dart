import 'package:flutter/material.dart';

import 'health_report_entity.dart' show DataPoint;

// ══════════════════════════════════════════════════════════════════════════════
// MACRO BREAKDOWN
// ══════════════════════════════════════════════════════════════════════════════

/// Daily macro totals in grams.
@immutable
class MacroBreakdown {
  const MacroBreakdown({
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
  });

  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;

  double get totalCalories =>
      (proteinG * 4) + (carbsG * 4) + (fatG * 9);

  double get proteinPct => totalCalories == 0
      ? 0
      : (proteinG * 4) / totalCalories;
  double get carbsPct => totalCalories == 0
      ? 0
      : (carbsG * 4) / totalCalories;
  double get fatPct => totalCalories == 0
      ? 0
      : (fatG * 9) / totalCalories;
}

// ══════════════════════════════════════════════════════════════════════════════
// MEAL CONSISTENCY RECORD
// ══════════════════════════════════════════════════════════════════════════════

/// Per-meal-type logging consistency for a single day.
@immutable
class MealConsistencyRecord {
  const MealConsistencyRecord({
    required this.date,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snacks,
  });

  final DateTime date;
  final bool breakfast;
  final bool lunch;
  final bool dinner;
  final bool snacks;

  int get loggedCount =>
      [breakfast, lunch, dinner, snacks].where((v) => v).length;
}

// ══════════════════════════════════════════════════════════════════════════════
// NUTRITION REPORT ENTITY
// ══════════════════════════════════════════════════════════════════════════════

/// Aggregated nutrition analytics for a given date range.
@immutable
class NutritionReportEntity {
  const NutritionReportEntity({
    required this.nutritionScore,
    required this.nutritionScoreDelta,
    required this.avgDailyCalories,
    required this.caloriesDelta,
    required this.targetCalories,
    required this.avgProteinG,
    required this.avgCarbsG,
    required this.avgFatG,
    required this.avgFiberG,
    required this.avgWaterMl,
    required this.waterDelta,
    required this.waterTargetMl,
    required this.calorieSeries,
    required this.proteinSeries,
    required this.carbsSeries,
    required this.fatSeries,
    required this.waterSeries,
    required this.mealConsistency,
    required this.macroAvg,
    required this.daysLogged,
    required this.loggingConsistencyPct,
    required this.weeklyMacroComparison,
  });

  // ── KPIs ──────────────────────────────────────────────────────────────────
  /// 0–100 nutrition quality score
  final double nutritionScore;
  final double nutritionScoreDelta;
  final double avgDailyCalories;
  final double caloriesDelta;
  final double targetCalories;
  final double avgProteinG;
  final double avgCarbsG;
  final double avgFatG;
  final double avgFiberG;
  final double avgWaterMl;
  final double waterDelta;
  final double waterTargetMl;

  // ── Time Series ────────────────────────────────────────────────────────────
  final List<DataPoint> calorieSeries;
  final List<DataPoint> proteinSeries;
  final List<DataPoint> carbsSeries;
  final List<DataPoint> fatSeries;
  final List<DataPoint> waterSeries;

  // ── Meal Consistency ───────────────────────────────────────────────────────
  final List<MealConsistencyRecord> mealConsistency;

  // ── Macro Average ─────────────────────────────────────────────────────────
  final MacroBreakdown macroAvg;

  // ── Logging Stats ─────────────────────────────────────────────────────────
  final int daysLogged;

  /// 0.0–1.0
  final double loggingConsistencyPct;

  /// Per-macro weekly comparison [(target, actual), …]
  final Map<String, List<(double, double)>> weeklyMacroComparison;
}

// ══════════════════════════════════════════════════════════════════════════════
// MACRO COLOUR CONSTANTS
// ══════════════════════════════════════════════════════════════════════════════

const Color kProteinColor = Color(0xFF6C63FF);
const Color kCarbsColor = Color(0xFFFF9800);
const Color kFatColor = Color(0xFFFF6B6B);
const Color kFiberColor = Color(0xFF00C896);
const Color kWaterColor = Color(0xFF00B4D8);

