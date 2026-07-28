/// BMI categories per WHO classification.
enum BmiCategory {
  underweight,
  normalWeight,
  overweight,
  obese,
}

extension BmiCategoryX on BmiCategory {
  String get label => switch (this) {
        BmiCategory.underweight => 'Underweight',
        BmiCategory.normalWeight => 'Normal Weight',
        BmiCategory.overweight => 'Overweight',
        BmiCategory.obese => 'Obese',
      };

  String get advice => switch (this) {
        BmiCategory.underweight =>
          'Consider a calorie-rich diet and strength training.',
        BmiCategory.normalWeight => 'Great work! Maintain your healthy habits.',
        BmiCategory.overweight =>
          'Focus on balanced diet and regular exercise.',
        BmiCategory.obese =>
          'Consult a healthcare provider for a personalised plan.',
      };
}

/// Measurement unit system.
enum BmiUnit { metric, imperial }

/// A single historical BMI measurement.
class BmiHistoryEntry {
  const BmiHistoryEntry({
    required this.value,
    required this.heightCm,
    required this.weightKg,
    required this.measuredAt,
  });

  final double value;
  final double heightCm;
  final double weightKg;
  final DateTime measuredAt;

  BmiCategory get category => BmiEntity.categoryForValue(value);
}

/// Pure domain entity representing a BMI measurement.
class BmiEntity {
  const BmiEntity({
    required this.id,
    required this.value,
    required this.heightCm,
    required this.weightKg,
    required this.category,
    required this.measuredAt,
    required this.history,
  });

  final String id;
  final double value;
  final double heightCm;
  final double weightKg;
  final BmiCategory category;
  final DateTime measuredAt;
  final List<BmiHistoryEntry> history;

  // ── Derived ───────────────────────────────────────────────────────────────

  /// Formatted BMI string with 1 decimal place.
  String get formatted => value.toStringAsFixed(1);

  /// Height in metres.
  double get heightM => heightCm / 100;

  /// Minimum healthy weight (BMI 18.5) in kg.
  double get healthyMinKg => 18.5 * heightM * heightM;

  /// Maximum healthy weight (BMI 24.9) in kg.
  double get healthyMaxKg => 24.9 * heightM * heightM;

  /// Fraction on a 10–40 gauge scale, clamped 0–1.
  double get gaugeFraction => ((value - 10) / 30).clamp(0.0, 1.0);

  // ── Static helpers ─────────────────────────────────────────────────────────

  /// Returns the [BmiCategory] for a raw BMI value.
  static BmiCategory categoryForValue(double bmi) {
    if (bmi < 18.5) return BmiCategory.underweight;
    if (bmi < 25.0) return BmiCategory.normalWeight;
    if (bmi < 30.0) return BmiCategory.overweight;
    return BmiCategory.obese;
  }

  /// Calculates BMI from metric inputs.
  static double calculateMetric({
    required double heightCm,
    required double weightKg,
  }) {
    if (heightCm <= 0 || weightKg <= 0) return 0;
    final h = heightCm / 100;
    return weightKg / (h * h);
  }

  /// Calculates BMI from imperial inputs.
  static double calculateImperial({
    required double heightInches,
    required double weightLb,
  }) {
    if (heightInches <= 0 || weightLb <= 0) return 0;
    return 703 * weightLb / (heightInches * heightInches);
  }
}
