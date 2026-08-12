import 'health_report_entity.dart' show DataPoint;

// ══════════════════════════════════════════════════════════════════════════════
// TREND DIRECTION
// ══════════════════════════════════════════════════════════════════════════════

/// The direction of a metric's trend over a time window.
enum TrendDirection {
  improving('Improving', true),
  stable('Stable', null),
  declining('Declining', false),
  fluctuating('Fluctuating', null);

  const TrendDirection(this.label, this.isPositive);
  final String label;

  /// null = neutral; true = good; false = bad
  final bool? isPositive;
}

// ══════════════════════════════════════════════════════════════════════════════
// TREND METRIC TYPE
// ══════════════════════════════════════════════════════════════════════════════

/// Which health/fitness metric a trend record belongs to.
enum TrendMetric {
  heartRate('Heart Rate', 'bpm'),
  systolicBP('Systolic BP', 'mmHg'),
  diastolicBP('Diastolic BP', 'mmHg'),
  bloodSugar('Blood Sugar', 'mg/dL'),
  spo2('SpO₂', '%'),
  bmi('BMI', 'kg/m²'),
  weight('Weight', 'kg'),
  water('Water Intake', 'mL'),
  calories('Calories', 'kcal'),
  sleep('Sleep', 'hrs'),
  steps('Steps', 'steps'),
  workouts('Workouts', 'sessions'),
  activeMinutes('Active Minutes', 'min'),
  medicationAdherence('Medication', '%'),
  nutritionScore('Nutrition Score', 'pts');

  const TrendMetric(this.label, this.unit);
  final String label;
  final String unit;
}

// ══════════════════════════════════════════════════════════════════════════════
// TREND DATA ENTITY
// ══════════════════════════════════════════════════════════════════════════════

/// Trend analysis for a single metric over a time window.
class TrendDataEntity {
  const TrendDataEntity({
    required this.metric,
    required this.series,
    required this.direction,
    required this.currentAvg,
    required this.previousAvg,
    required this.changePercent,
    required this.changeAbsolute,
    required this.minValue,
    required this.maxValue,
    required this.standardDeviation,
    required this.trendStrength,
    required this.weekOverWeekChanges,
    this.description,
    this.riskLevel,
  });

  final TrendMetric metric;

  /// Daily data points for the period
  final List<DataPoint> series;

  final TrendDirection direction;

  /// Average for current window
  final double currentAvg;

  /// Average for previous equal-length window
  final double previousAvg;

  /// Percentage change current vs previous
  final double changePercent;

  /// Absolute change current vs previous (in metric units)
  final double changeAbsolute;

  final double minValue;
  final double maxValue;

  /// Population standard deviation of [series]
  final double standardDeviation;

  /// 0.0–1.0 — how strong the trend is (R²-equivalent)
  final double trendStrength;

  /// Week-over-week change list for sparkline display
  final List<double> weekOverWeekChanges;

  /// Human-readable trend description, e.g. "Declining by 4% per week"
  final String? description;

  /// 'low' | 'medium' | 'high' | null
  final String? riskLevel;

  bool get isImproving => direction == TrendDirection.improving;
  bool get isDeclining => direction == TrendDirection.declining;
  bool get isSignificant => trendStrength > 0.5;

  double get volatility =>
      currentAvg == 0 ? 0 : standardDeviation / currentAvg;
}

// ══════════════════════════════════════════════════════════════════════════════
// TRENDS REPORT (aggregation)
// ══════════════════════════════════════════════════════════════════════════════

/// Complete trend analysis across all metrics for a date range.
class TrendsReport {
  const TrendsReport({
    required this.trends,
    required this.improvingCount,
    required this.decliningCount,
    required this.stableCount,
    required this.periodLabel,
  });

  final List<TrendDataEntity> trends;
  final int improvingCount;
  final int decliningCount;
  final int stableCount;
  final String periodLabel;

  List<TrendDataEntity> get improving =>
      trends.where((t) => t.isImproving).toList();

  List<TrendDataEntity> get declining =>
      trends.where((t) => t.isDeclining).toList();

  List<TrendDataEntity> get highRisk =>
      trends.where((t) => t.riskLevel == 'high').toList();

  TrendDataEntity? forMetric(TrendMetric m) {
    try {
      return trends.firstWhere((t) => t.metric == m);
    } catch (_) {
      return null;
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PERSONAL RECORD
// ══════════════════════════════════════════════════════════════════════════════

/// A single personal record entry (e.g., highest step count, longest streak).
class PersonalRecord {
  const PersonalRecord({
    required this.label,
    required this.value,
    required this.unit,
    required this.achievedAt,
    required this.emoji,
  });

  final String label;
  final double value;
  final String unit;
  final DateTime achievedAt;
  final String emoji;
}

