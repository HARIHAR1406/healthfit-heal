import '../../utils/app_logger.dart';
import 'health_classification.dart';
import 'health_rule.dart';
import 'rule_set_registry.dart';

/// Applies data-driven health rules to classify metric values.
///
/// ── Algorithm ─────────────────────────────────────────────────────────────────
/// For a given metric type and value:
///   1. Retrieve the ordered rule list from [RuleSetRegistry].
///   2. Rules are pre-ordered most-severe → least-severe.
///   3. Return the first matching rule's [HealthClassification].
///   4. If no rule matches → return [HealthLevel.normal] with a generic message.
///
/// This engine is stateless and purely functional — all state is in [RuleSetRegistry].
///
/// ── Important ─────────────────────────────────────────────────────────────────
/// This engine classifies values for GENERAL wellness guidance only.
/// It does NOT diagnose medical conditions. Classification output MUST
/// always be accompanied by the standard disclaimer.
///
/// ── Extending ─────────────────────────────────────────────────────────────────
/// To add a new metric or update ranges: edit [RuleSetRegistry] ONLY.
/// No changes to this engine are required.
class HealthRuleEngine {
  const HealthRuleEngine();

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Classifies a numeric [value] for the given [metricType].
  ///
  /// [metricType] must be one of the keys defined in [RuleSetRegistry].
  ///
  /// Returns a [HealthClassification] with:
  ///   - The matching [HealthLevel]
  ///   - The human-readable message and action guidance from the matched rule
  ///   - The clinical reference source
  ///
  /// Never throws — returns a [HealthLevel.normal] classification with a
  /// "metric not registered" message if the metric type is unknown.
  HealthClassification classify({
    required String metricType,
    required double value,
  }) {
    final rules = RuleSetRegistry.rulesFor(metricType);

    if (rules.isEmpty) {
      log.warning(
        'HealthRuleEngine: unknown metric type "$metricType". '
        'Register rules in RuleSetRegistry.',
      );
      return _unknownMetricClassification(metricType, value);
    }

    // Evaluate rules most-severe → least-severe (first match wins)
    for (final rule in rules) {
      if (rule.matches(value)) {
        log.debug(
          'HealthRuleEngine: "$metricType" value=$value '
          'matched rule="${rule.id}" level=${rule.level.name}',
        );
        return HealthClassification(
          level: rule.level,
          metricType: metricType,
          value: value,
          unit: rule.unit,
          message: rule.message,
          actionGuidance: rule.actionGuidance,
          ruleId: rule.id,
          reference: rule.reference,
          requiresProfessionalConsultation:
              rule.level.requiresProfessionalConsultation,
        );
      }
    }

    // No rule matched — should not happen with well-formed rule sets.
    // Defensive fallback.
    log.warning(
      'HealthRuleEngine: no rule matched "$metricType" value=$value. '
      'Check RuleSetRegistry for gaps in coverage.',
    );
    return _noMatchClassification(metricType, value);
  }

  /// Classifies multiple metrics at once.
  ///
  /// Returns a map of metricType → [HealthClassification].
  Map<String, HealthClassification> classifyAll(
    Map<String, double> metrics,
  ) {
    return {
      for (final entry in metrics.entries)
        entry.key: classify(metricType: entry.key, value: entry.value),
    };
  }

  /// Returns the overall worst-case level across a set of classifications.
  ///
  /// Useful for producing a single headline status for a health dashboard.
  HealthLevel overallLevel(List<HealthClassification> classifications) {
    if (classifications.isEmpty) return HealthLevel.normal;

    // Order: critical > highRisk > needsAttention > normal
    const severity = {
      HealthLevel.critical: 3,
      HealthLevel.highRisk: 2,
      HealthLevel.needsAttention: 1,
      HealthLevel.normal: 0,
    };

    return classifications
        .map((c) => c.level)
        .reduce((a, b) => (severity[a]! >= severity[b]!) ? a : b);
  }

  // ── Private ────────────────────────────────────────────────────────────────

  HealthClassification _unknownMetricClassification(
    String metricType,
    double value,
  ) =>
      HealthClassification(
        level: HealthLevel.normal,
        metricType: metricType,
        value: value,
        unit: '',
        message: 'No classification available for "$metricType".',
        actionGuidance:
            'This metric is not yet registered in the health rule engine.',
        ruleId: null,
        reference: null,
        requiresProfessionalConsultation: false,
      );

  HealthClassification _noMatchClassification(
    String metricType,
    double value,
  ) =>
      HealthClassification(
        level: HealthLevel.normal,
        metricType: metricType,
        value: value,
        unit: '',
        message: 'Classification data is incomplete for this metric.',
        actionGuidance: 'Please consult your healthcare provider for guidance.',
        requiresProfessionalConsultation: false,
      );
}
