import 'health_report_entity.dart' show DataPoint;
import 'fitness_report_entity.dart' show WorkoutCategoryBreakdown;
import 'nutrition_report_entity.dart' show MacroBreakdown;

// ══════════════════════════════════════════════════════════════════════════════
// COMPARISON PERIOD
// ══════════════════════════════════════════════════════════════════════════════

/// Predefined comparison windows.
enum ComparisonPeriod {
  weekOverWeek('This Week vs Last Week', 7),
  monthOverMonth('This Month vs Last Month', 30),
  yearOverYear('This Year vs Last Year', 365),
  custom('Custom Range', -1);

  const ComparisonPeriod(this.label, this.days);
  final String label;
  final int days;
}

// ══════════════════════════════════════════════════════════════════════════════
// PERIOD STATS
// ══════════════════════════════════════════════════════════════════════════════

/// Statistics for one period in a comparison (current or previous).
class PeriodStats {
  const PeriodStats({
    required this.label,
    required this.startDate,
    required this.endDate,
    required this.healthScore,
    required this.fitnessScore,
    required this.nutritionScore,
    required this.overallScore,
    required this.avgHeartRate,
    required this.avgBloodSugar,
    required this.avgSpo2,
    required this.avgSystolic,
    required this.avgDiastolic,
    required this.totalWorkouts,
    required this.totalCaloriesBurned,
    required this.totalActiveMinutes,
    required this.totalDistanceKm,
    required this.avgDailyCalories,
    required this.avgWaterMl,
    required this.daysLogged,
    required this.heartRateSeries,
    required this.calorieSeries,
    required this.workoutSeries,
    required this.waterSeries,
    required this.macroAvg,
    required this.categoryBreakdown,
  });

  final String label;
  final DateTime startDate;
  final DateTime endDate;

  // ── Scores ────────────────────────────────────────────────────────────────
  final double healthScore;
  final double fitnessScore;
  final double nutritionScore;
  final double overallScore;

  // ── Health ────────────────────────────────────────────────────────────────
  final double avgHeartRate;
  final double avgBloodSugar;
  final double avgSpo2;
  final double avgSystolic;
  final double avgDiastolic;

  // ── Fitness ───────────────────────────────────────────────────────────────
  final int totalWorkouts;
  final double totalCaloriesBurned;
  final int totalActiveMinutes;
  final double totalDistanceKm;

  // ── Nutrition ─────────────────────────────────────────────────────────────
  final double avgDailyCalories;
  final double avgWaterMl;
  final int daysLogged;

  // ── Series for mini-charts ────────────────────────────────────────────────
  final List<DataPoint> heartRateSeries;
  final List<DataPoint> calorieSeries;
  final List<DataPoint> workoutSeries;
  final List<DataPoint> waterSeries;

  // ── Breakdowns ────────────────────────────────────────────────────────────
  final MacroBreakdown macroAvg;
  final List<WorkoutCategoryBreakdown> categoryBreakdown;
}

// ══════════════════════════════════════════════════════════════════════════════
// METRIC COMPARISON
// ══════════════════════════════════════════════════════════════════════════════

/// A single metric comparison between current and previous period.
class MetricComparison {
  const MetricComparison({
    required this.label,
    required this.unit,
    required this.currentValue,
    required this.previousValue,
    required this.changePercent,
    required this.isPositiveChange,
    required this.currentSeries,
    required this.previousSeries,
  });

  final String label;
  final String unit;
  final double currentValue;
  final double previousValue;
  final double changePercent;

  /// True if a higher value is better for this metric.
  final bool isPositiveChange;

  final List<DataPoint> currentSeries;
  final List<DataPoint> previousSeries;

  double get absoluteChange => currentValue - previousValue;
  bool get improved => changePercent > 0 ? isPositiveChange : !isPositiveChange;
}

// ══════════════════════════════════════════════════════════════════════════════
// COMPARISON DATA ENTITY
// ══════════════════════════════════════════════════════════════════════════════

/// Full comparison report between two time periods.
class ComparisonDataEntity {
  const ComparisonDataEntity({
    required this.period,
    required this.current,
    required this.previous,
    required this.metricComparisons,
    required this.winnerLabel,
    required this.improvementsCount,
    required this.regressionsCount,
  });

  final ComparisonPeriod period;
  final PeriodStats current;
  final PeriodStats previous;
  final List<MetricComparison> metricComparisons;

  /// Label for the "better" period (e.g., "This Week" or "Last Week")
  final String winnerLabel;
  final int improvementsCount;
  final int regressionsCount;

  double get overallDelta =>
      current.overallScore - previous.overallScore;

  bool get currentIsBetter => current.overallScore >= previous.overallScore;

  MetricComparison? forMetric(String label) {
    try {
      return metricComparisons.firstWhere((m) => m.label == label);
    } catch (_) {
      return null;
    }
  }
}

