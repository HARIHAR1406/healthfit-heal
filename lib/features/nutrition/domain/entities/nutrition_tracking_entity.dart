/// A single water intake log entry.
class WaterIntakeEntry {
  const WaterIntakeEntry({
    required this.id,
    required this.amountMl,
    required this.loggedAt,
  });

  final String id;
  final int amountMl;
  final DateTime loggedAt;
}

/// Full water tracking state for a day.
class WaterTrackerEntity {
  const WaterTrackerEntity({
    required this.date,
    required this.entries,
    required this.goalMl,
  });

  final DateTime date;
  final List<WaterIntakeEntry> entries;
  final int goalMl;

  int get totalMl => entries.fold(0, (s, e) => s + e.amountMl);
  int get remainingMl => (goalMl - totalMl).clamp(0, goalMl);
  double get fraction => (totalMl / goalMl).clamp(0.0, 1.0);
  bool get goalMet => totalMl >= goalMl;
}

/// A single weight measurement.
class WeightEntry {
  const WeightEntry({
    required this.id,
    required this.weightKg,
    required this.measuredAt,
    this.notes,
  });

  final String id;
  final double weightKg;
  final DateTime measuredAt;
  final String? notes;
}

/// Weight tracking entity.
class WeightTrackerEntity {
  const WeightTrackerEntity({
    required this.entries,
    required this.goalKg,
    required this.heightCm,
  });

  final List<WeightEntry> entries;
  final double goalKg;
  final double heightCm;

  WeightEntry? get latest =>
      entries.isEmpty ? null : entries.first;

  double? get currentWeightKg => latest?.weightKg;

  double? get bmi {
    final w = currentWeightKg;
    if (w == null || heightCm <= 0) return null;
    final h = heightCm / 100;
    return w / (h * h);
  }

  String get bmiCategory {
    final b = bmi;
    if (b == null) return 'Unknown';
    if (b < 18.5) return 'Underweight';
    if (b < 25.0) return 'Normal';
    if (b < 30.0) return 'Overweight';
    return 'Obese';
  }

  double? get progressToGoal {
    if (entries.length < 2) return null;
    final start = entries.last.weightKg;
    final current = currentWeightKg!;
    final diff = start - goalKg;
    if (diff == 0) return 1.0;
    return ((start - current) / diff).clamp(0.0, 1.0);
  }
}

/// Weekly nutrition analytics.
class NutritionAnalyticsEntity {
  const NutritionAnalyticsEntity({
    required this.weeklyCalories,
    required this.weeklyProtein,
    required this.weeklyCarbs,
    required this.weeklyFat,
    required this.weeklyWaterMl,
    required this.weeklyScores,
    required this.monthlyCalories,
    required this.caloriesGoal,
  });

  /// 7 values Mon–Sun.
  final List<double> weeklyCalories;
  final List<double> weeklyProtein;
  final List<double> weeklyCarbs;
  final List<double> weeklyFat;
  final List<double> weeklyWaterMl;
  final List<int> weeklyScores;

  /// 30 values for month view.
  final List<double> monthlyCalories;

  final double caloriesGoal;
}
