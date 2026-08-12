import 'health_classification.dart';

/// A single range-based classification rule for a health metric.
///
/// Rules are ordered — the rule engine evaluates them from highest severity
/// (critical) to lowest (normal). The first matching rule wins.
///
/// ── Range semantics ───────────────────────────────────────────────────────────
/// [minValue] is INCLUSIVE (value >= minValue matches).
/// [maxValue] is EXCLUSIVE (value < maxValue matches).
/// Use [double.negativeInfinity] / [double.infinity] to represent open ranges.
///
/// ── Extensibility ────────────────────────────────────────────────────────────
/// To update guidelines, modify [RuleSetRegistry] — no engine code changes needed.
class HealthRule {
  const HealthRule({
    required this.id,
    required this.metricType,
    required this.minValue,
    required this.maxValue,
    required this.level,
    required this.message,
    required this.actionGuidance,
    required this.unit,
    this.reference,
    this.tags = const {},
  });

  /// Unique rule identifier (e.g. 'hr_critical_high').
  final String id;

  /// Metric this rule applies to (matches [HealthRuleEngine] metric keys).
  final String metricType;

  /// Minimum value (inclusive) for this rule to match.
  final double minValue;

  /// Maximum value (exclusive) for this rule to match.
  final double maxValue;

  /// The [HealthLevel] assigned when this rule matches.
  final HealthLevel level;

  /// Human-readable status message.
  final String message;

  /// Actionable guidance for the user.
  final String actionGuidance;

  /// Unit label for display.
  final String unit;

  /// Clinical reference (e.g. 'AHA 2017', 'WHO BMI', 'ADA 2023').
  final String? reference;

  /// Optional tags for filtering/categorisation (e.g. {'fasting', 'adult'}).
  final Set<String> tags;

  /// Returns true if [value] falls within [minValue]..[maxValue].
  bool matches(double value) => value >= minValue && value < maxValue;

  @override
  String toString() =>
      'HealthRule(id=$id, metric=$metricType, '
      'range=[$minValue, $maxValue), level=${level.name})';
}

