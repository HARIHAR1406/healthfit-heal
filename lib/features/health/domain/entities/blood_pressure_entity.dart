/// Blood pressure classification (AHA 2017 guidelines).
enum BloodPressureStatus {
  normal,
  elevated,
  highStage1,
  highStage2,
  hypertensiveCrisis,
}

extension BloodPressureStatusX on BloodPressureStatus {
  String get label => switch (this) {
        BloodPressureStatus.normal => 'Normal',
        BloodPressureStatus.elevated => 'Elevated',
        BloodPressureStatus.highStage1 => 'High — Stage 1',
        BloodPressureStatus.highStage2 => 'High — Stage 2',
        BloodPressureStatus.hypertensiveCrisis => 'Crisis — Seek Care',
      };

  bool get isHealthy => this == BloodPressureStatus.normal;
  bool get isWarning =>
      this == BloodPressureStatus.elevated ||
      this == BloodPressureStatus.highStage1;
  bool get isCritical =>
      this == BloodPressureStatus.highStage2 ||
      this == BloodPressureStatus.hypertensiveCrisis;
}

/// A single blood pressure reading.
class BpReading {
  const BpReading({
    required this.id,
    required this.systolic,
    required this.diastolic,
    required this.timestamp,
    this.pulse,
    this.notes,
  });

  final String id;
  final int systolic;
  final int diastolic;
  final int? pulse;
  final DateTime timestamp;
  final String? notes;

  /// Derived status per AHA 2017.
  BloodPressureStatus get status =>
      BloodPressureEntity.statusForReading(systolic, diastolic);

  /// Formatted string, e.g. "120/80".
  String get formatted => '$systolic/$diastolic';
}

/// Pure domain entity for blood pressure data.
class BloodPressureEntity {
  const BloodPressureEntity({
    required this.id,
    required this.latestReading,
    required this.history,
  });

  final String id;
  final BpReading latestReading;

  /// History ordered newest → oldest.
  final List<BpReading> history;

  // ── Derived ───────────────────────────────────────────────────────────────

  /// Systolic values for the trend line chart (oldest → newest).
  List<double> get systolicTrend =>
      history.reversed.map((r) => r.systolic.toDouble()).toList();

  /// Diastolic values for the trend line chart (oldest → newest).
  List<double> get diastolicTrend =>
      history.reversed.map((r) => r.diastolic.toDouble()).toList();

  // ── Static ─────────────────────────────────────────────────────────────────

  /// Derives [BloodPressureStatus] from systolic / diastolic values.
  static BloodPressureStatus statusForReading(int sys, int dia) {
    if (sys > 180 || dia > 120) return BloodPressureStatus.hypertensiveCrisis;
    if (sys >= 140 || dia >= 90) return BloodPressureStatus.highStage2;
    if (sys >= 130 || dia >= 80) return BloodPressureStatus.highStage1;
    if (sys >= 120 && dia < 80) return BloodPressureStatus.elevated;
    return BloodPressureStatus.normal;
  }
}

