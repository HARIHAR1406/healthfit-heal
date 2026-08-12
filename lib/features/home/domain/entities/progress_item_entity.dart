/// Pure domain entity representing a single Today's Progress ring.
class ProgressItemEntity {
  const ProgressItemEntity({
    required this.id,
    required this.title,
    required this.current,
    required this.goal,
    required this.unit,
    required this.metricType,
  });

  final String id;
  final String title;

  /// Current value (e.g. 7432 for steps).
  final double current;

  /// Daily / target goal value.
  final double goal;

  /// Display unit (e.g. "steps", "kcal", "ml", "h").
  final String unit;

  /// Links to [HealthMetricType] for visual mapping in the widget layer.
  final String metricType;

  /// Progress fraction clamped to [0, 1].
  double get fraction => (goal <= 0) ? 0 : (current / goal).clamp(0.0, 1.0);

  /// Percentage string for display.
  String get percentLabel => '${(fraction * 100).round()}%';

  /// True when daily goal is achieved.
  bool get isGoalReached => current >= goal;

  /// Formatted current value, trimming unnecessary decimals.
  String get currentLabel {
    if (current == current.roundToDouble()) {
      return current.toInt().toString();
    }
    return current.toStringAsFixed(1);
  }
}

