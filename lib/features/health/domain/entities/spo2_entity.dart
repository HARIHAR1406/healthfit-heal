/// SpO₂ (peripheral oxygen saturation) status.
enum Spo2Status { normal, low, criticallyLow }

extension Spo2StatusX on Spo2Status {
  String get label => switch (this) {
        Spo2Status.normal => 'Normal',
        Spo2Status.low => 'Low — Monitor',
        Spo2Status.criticallyLow => 'Critical — Seek Care',
      };

  String get description => switch (this) {
        Spo2Status.normal =>
          'Your oxygen level is within the healthy range (95–100%).',
        Spo2Status.low =>
          'Oxygen level is below 95%. Rest and monitor closely.',
        Spo2Status.criticallyLow =>
          'Oxygen level is critically low. Seek immediate medical attention.',
      };
}

/// A single SpO₂ reading.
class Spo2Reading {
  const Spo2Reading({
    required this.id,
    required this.percentage,
    required this.timestamp,
  });

  final String id;

  /// SpO₂ percentage, typically 95–100.
  final int percentage;
  final DateTime timestamp;

  Spo2Status get status => Spo2Entity.statusForValue(percentage);
}

/// Pure domain entity for SpO₂ data.
class Spo2Entity {
  const Spo2Entity({
    required this.id,
    required this.currentPercentage,
    required this.history,
  });

  final String id;
  final int currentPercentage;

  /// History newest → oldest.
  final List<Spo2Reading> history;

  // ── Derived ───────────────────────────────────────────────────────────────

  Spo2Status get status => statusForValue(currentPercentage);

  /// Fraction for the circular progress ring (e.g. 97% → 0.97).
  double get fraction => currentPercentage / 100.0;

  // ── Static ─────────────────────────────────────────────────────────────────

  static Spo2Status statusForValue(int pct) {
    if (pct >= 95) return Spo2Status.normal;
    if (pct >= 90) return Spo2Status.low;
    return Spo2Status.criticallyLow;
  }
}

