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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amountMl': amountMl,
      'loggedAt': loggedAt.toIso8601String(),
    };
  }

  factory WaterIntakeEntry.fromMap(Map<String, dynamic> map) {
    return WaterIntakeEntry(
      id: map['id'] as String? ?? '',
      amountMl: (map['amountMl'] as num?)?.toInt() ?? 0,
      loggedAt: DateTime.parse(map['loggedAt'] as String),
    );
  }
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

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'entries': entries.map((e) => e.toMap()).toList(),
      'goalMl': goalMl,
    };
  }

  factory WaterTrackerEntity.fromMap(Map<String, dynamic> map) {
    return WaterTrackerEntity(
      date: DateTime.parse(map['date'] as String),
      entries: List<WaterIntakeEntry>.from((map['entries'] as List? ?? []).map((x) => WaterIntakeEntry.fromMap(x as Map<String, dynamic>))),
      goalMl: (map['goalMl'] as num?)?.toInt() ?? 2500,
    );
  }
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'weightKg': weightKg,
      'measuredAt': measuredAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory WeightEntry.fromMap(Map<String, dynamic> map) {
    return WeightEntry(
      id: map['id'] as String? ?? '',
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0.0,
      measuredAt: DateTime.parse(map['measuredAt'] as String),
      notes: map['notes'] as String?,
    );
  }
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

  Map<String, dynamic> toMap() {
    return {
      'entries': entries.map((e) => e.toMap()).toList(),
      'goalKg': goalKg,
      'heightCm': heightCm,
    };
  }

  factory WeightTrackerEntity.fromMap(Map<String, dynamic> map) {
    return WeightTrackerEntity(
      entries: List<WeightEntry>.from((map['entries'] as List? ?? []).map((x) => WeightEntry.fromMap(x as Map<String, dynamic>))),
      goalKg: (map['goalKg'] as num?)?.toDouble() ?? 70.0,
      heightCm: (map['heightCm'] as num?)?.toDouble() ?? 170.0,
    );
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

  final List<double> monthlyCalories;

  final double caloriesGoal;

  Map<String, dynamic> toMap() {
    return {
      'weeklyCalories': weeklyCalories,
      'weeklyProtein': weeklyProtein,
      'weeklyCarbs': weeklyCarbs,
      'weeklyFat': weeklyFat,
      'weeklyWaterMl': weeklyWaterMl,
      'weeklyScores': weeklyScores,
      'monthlyCalories': monthlyCalories,
      'caloriesGoal': caloriesGoal,
    };
  }

  factory NutritionAnalyticsEntity.fromMap(Map<String, dynamic> map) {
    return NutritionAnalyticsEntity(
      weeklyCalories: List<double>.from((map['weeklyCalories'] as List? ?? []).map((x) => (x as num).toDouble())),
      weeklyProtein: List<double>.from((map['weeklyProtein'] as List? ?? []).map((x) => (x as num).toDouble())),
      weeklyCarbs: List<double>.from((map['weeklyCarbs'] as List? ?? []).map((x) => (x as num).toDouble())),
      weeklyFat: List<double>.from((map['weeklyFat'] as List? ?? []).map((x) => (x as num).toDouble())),
      weeklyWaterMl: List<double>.from((map['weeklyWaterMl'] as List? ?? []).map((x) => (x as num).toDouble())),
      weeklyScores: List<int>.from((map['weeklyScores'] as List? ?? []).map((x) => (x as num).toInt())),
      monthlyCalories: List<double>.from((map['monthlyCalories'] as List? ?? []).map((x) => (x as num).toDouble())),
      caloriesGoal: (map['caloriesGoal'] as num?)?.toDouble() ?? 2000.0,
    );
  }
}

