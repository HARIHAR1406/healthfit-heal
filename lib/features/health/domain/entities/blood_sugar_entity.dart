/// Blood sugar reading type.
enum BloodSugarType { fasting, postMeal, random }

extension BloodSugarTypeX on BloodSugarType {
  String get label => switch (this) {
        BloodSugarType.fasting => 'Fasting',
        BloodSugarType.postMeal => 'Post-Meal',
        BloodSugarType.random => 'Random',
      };
}

/// Blood sugar status based on ADA clinical ranges.
enum BloodSugarStatus { normal, prediabetes, diabetes }

extension BloodSugarStatusX on BloodSugarStatus {
  String get label => switch (this) {
        BloodSugarStatus.normal => 'Normal',
        BloodSugarStatus.prediabetes => 'Pre-Diabetes',
        BloodSugarStatus.diabetes => 'Diabetes Range',
      };
}

/// A single blood sugar reading.
class SugarReading {
  const SugarReading({
    required this.id,
    required this.value,
    required this.type,
    required this.timestamp,
    this.notes,
  });

  final String id;

  /// Value in mg/dL.
  final double value;
  final BloodSugarType type;
  final DateTime timestamp;
  final String? notes;

  /// Derived ADA status.
  BloodSugarStatus get status =>
      BloodSugarEntity.statusForReading(value, type);

  String get formattedValue => '${value.toStringAsFixed(0)} mg/dL';
}

/// Pure domain entity for blood sugar data.
class BloodSugarEntity {
  const BloodSugarEntity({
    required this.id,
    required this.latestFasting,
    required this.latestPostMeal,
    required this.history,
  });

  final String id;

  /// Latest fasting reading (may be null if never recorded).
  final SugarReading? latestFasting;

  /// Latest post-meal reading (may be null if never recorded).
  final SugarReading? latestPostMeal;

  /// Full history newest → oldest.
  final List<SugarReading> history;

  // ── Derived ───────────────────────────────────────────────────────────────

  /// Trend values for chart (oldest → newest).
  List<double> get trendData =>
      history.reversed.map((r) => r.value).toList();

  // ── Static ─────────────────────────────────────────────────────────────────

  /// ADA 2023 ranges for fasting glucose in mg/dL.
  static BloodSugarStatus statusForReading(double value, BloodSugarType type) {
    return switch (type) {
      BloodSugarType.fasting => value < 100
          ? BloodSugarStatus.normal
          : value < 126
              ? BloodSugarStatus.prediabetes
              : BloodSugarStatus.diabetes,
      BloodSugarType.postMeal => value < 140
          ? BloodSugarStatus.normal
          : value < 200
              ? BloodSugarStatus.prediabetes
              : BloodSugarStatus.diabetes,
      BloodSugarType.random => value < 140
          ? BloodSugarStatus.normal
          : value < 200
              ? BloodSugarStatus.prediabetes
              : BloodSugarStatus.diabetes,
    };
  }
}
