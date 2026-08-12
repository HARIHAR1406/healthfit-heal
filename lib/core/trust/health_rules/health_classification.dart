/// Classification levels for health metric values.
///
/// Modelled on common clinical severity scales. These are GENERAL wellness
/// classifications and do NOT constitute medical diagnosis.
///
/// ── Important legal / UX note ─────────────────────────────────────────────────
/// The app must ALWAYS display [HealthLevel.critical] values with a
/// professional consultation notice. Never suggest the app is a substitute
/// for medical advice.
enum HealthLevel {
  /// Value is within normal healthy range.
  normal,

  /// Value is outside optimal range but not immediately concerning.
  needsAttention,

  /// Value indicates elevated health risk. Professional review recommended.
  highRisk,

  /// Value indicates critical condition. Immediate professional care advised.
  critical,
}

extension HealthLevelX on HealthLevel {
  /// Short display label.
  String get label => switch (this) {
        HealthLevel.normal => 'Normal',
        HealthLevel.needsAttention => 'Needs Attention',
        HealthLevel.highRisk => 'High Risk',
        HealthLevel.critical => 'Critical',
      };

  /// Whether this level requires a safety notice in the UI.
  bool get requiresSafetyNotice =>
      this == HealthLevel.highRisk || this == HealthLevel.critical;

  /// Whether this level requires professional consultation advice.
  bool get requiresProfessionalConsultation => this == HealthLevel.critical;
}

// ── Classification ─────────────────────────────────────────────────────────────

/// The output of [HealthRuleEngine.classify].
///
/// Contains the classification level, the specific rule that triggered it,
/// and UI-ready messaging.
class HealthClassification {
  const HealthClassification({
    required this.level,
    required this.metricType,
    required this.value,
    required this.unit,
    required this.message,
    required this.actionGuidance,
    this.ruleId,
    this.reference,
    this.requiresProfessionalConsultation = false,
  });

  /// The health level assigned by the rule engine.
  final HealthLevel level;

  /// Which metric was classified (e.g. 'heartRate', 'bloodPressureSystolic').
  final String metricType;

  /// The raw value that was classified.
  final double value;

  /// Unit for display (e.g. 'bpm', 'mmHg', 'mg/dL').
  final String unit;

  /// Human-readable status message for the UI.
  final String message;

  /// Actionable guidance for the user (always shown, even for normal).
  final String actionGuidance;

  /// ID of the rule that produced this classification (for logging/audit).
  final String? ruleId;

  /// Clinical reference used (e.g. 'AHA 2017', 'ADA 2023').
  final String? reference;

  /// Whether to display a professional consultation notice.
  final bool requiresProfessionalConsultation;

  bool get isNormal => level == HealthLevel.normal;
  bool get isCritical => level == HealthLevel.critical;

  /// Standard disclaimer to display with all classifications.
  static const String kClassificationDisclaimer =
      'This classification is based on general clinical guidelines. '
      'Individual health varies. Consult a qualified healthcare provider '
      'for personalised guidance.';

  @override
  String toString() =>
      'HealthClassification('
      'metric=$metricType, '
      'value=$value $unit, '
      'level=${level.name})';
}

