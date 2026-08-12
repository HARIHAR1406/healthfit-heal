/// Health metric types supported by the dashboard.
enum HealthMetricType {
  bmi,
  heartRate,
  steps,
  water,
  sleep,
  calories,
  bloodPressure,
  oxygenSaturation,
}

/// Status level of a health metric reading.
enum HealthMetricStatus {
  /// Within optimal range.
  excellent,

  /// Within healthy / acceptable range.
  normal,

  /// Approaching limits — worth monitoring.
  warning,

  /// Outside acceptable range — action recommended.
  critical,
}

extension HealthMetricStatusX on HealthMetricStatus {
  bool get isHealthy =>
      this == HealthMetricStatus.excellent || this == HealthMetricStatus.normal;
}

/// Pure domain entity representing a single health metric reading.
///
/// No Flutter imports — fully testable without a widget environment.
class HealthMetricEntity {
  const HealthMetricEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.value,
    required this.unit,
    required this.status,
    required this.progressPercent,
    required this.route,
    this.subtitle,
    this.trend,
  });

  /// Unique identifier.
  final String id;

  /// Metric category.
  final HealthMetricType type;

  /// Display title, e.g. "Heart Rate".
  final String title;

  /// Formatted current value, e.g. "72".
  final String value;

  /// Unit label, e.g. "bpm".
  final String unit;

  /// Health status derived from clinical ranges.
  final HealthMetricStatus status;

  /// Progress towards the daily / target goal (0.0 – 1.0).
  final double progressPercent;

  /// GoRouter path to the detail screen for this metric.
  final String route;

  /// Optional sub-label, e.g. "Normal range".
  final String? subtitle;

  /// Optional trend indicator, e.g. "+3 from yesterday".
  final String? trend;
}

