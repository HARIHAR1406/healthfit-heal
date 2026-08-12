import 'dart:math';

import '../../domain/entities/health_report_entity.dart' show DataPoint;
import '../../domain/entities/nutrition_report_entity.dart';

// ══════════════════════════════════════════════════════════════════════════════
// NUTRITION MOCK DATA
// ══════════════════════════════════════════════════════════════════════════════

/// Generates 90 days of realistic nutrition tracking mock data.
class NutritionMockData {
  NutritionMockData._();

  static final _rng = Random(44);

  static double _noise(double sigma) =>
      (_rng.nextDouble() + _rng.nextDouble() + _rng.nextDouble() - 1.5) *
      sigma;

  // ── Time series ───────────────────────────────────────────────────────────

  static List<DataPoint> calorieSeries(int days) {
    final today = DateTime.now();
    return List.generate(days, (i) {
      final date = today.subtract(Duration(days: days - 1 - i));
      final cal =
          (2050 + sin(i * pi / 7) * 150 + _noise(120)).clamp(1400.0, 2800.0);
      return DataPoint(date: date, value: double.parse(cal.toStringAsFixed(0)));
    });
  }

  static List<DataPoint> proteinSeries(int days) {
    final today = DateTime.now();
    return List.generate(days, (i) {
      final date = today.subtract(Duration(days: days - 1 - i));
      final g = (95 + _noise(15)).clamp(50.0, 180.0);
      return DataPoint(date: date, value: double.parse(g.toStringAsFixed(1)));
    });
  }

  static List<DataPoint> carbsSeries(int days) {
    final today = DateTime.now();
    return List.generate(days, (i) {
      final date = today.subtract(Duration(days: days - 1 - i));
      final g = (220 + sin(i * pi / 5) * 30 + _noise(25)).clamp(100.0, 350.0);
      return DataPoint(date: date, value: double.parse(g.toStringAsFixed(1)));
    });
  }

  static List<DataPoint> fatSeries(int days) {
    final today = DateTime.now();
    return List.generate(days, (i) {
      final date = today.subtract(Duration(days: days - 1 - i));
      final g = (65 + _noise(12)).clamp(30.0, 120.0);
      return DataPoint(date: date, value: double.parse(g.toStringAsFixed(1)));
    });
  }

  static List<DataPoint> waterSeries(int days) {
    final today = DateTime.now();
    return List.generate(days, (i) {
      final date = today.subtract(Duration(days: days - 1 - i));
      final ml = (1800 + sin(i * pi / 7) * 300 + _noise(200)).clamp(800.0, 3500.0);
      return DataPoint(date: date, value: double.parse(ml.toStringAsFixed(0)));
    });
  }

  // ── Meal consistency ──────────────────────────────────────────────────────

  static List<MealConsistencyRecord> mealConsistency(int days) {
    final today = DateTime.now();
    return List.generate(days, (i) {
      final date = today.subtract(Duration(days: days - 1 - i));
      return MealConsistencyRecord(
        date: date,
        breakfast: _rng.nextDouble() > 0.15,
        lunch: _rng.nextDouble() > 0.10,
        dinner: _rng.nextDouble() > 0.08,
        snacks: _rng.nextDouble() > 0.35,
      );
    });
  }

  // ── Macro average ─────────────────────────────────────────────────────────

  static MacroBreakdown macroAvg({
    required List<DataPoint> protein,
    required List<DataPoint> carbs,
    required List<DataPoint> fat,
  }) {
    double avg(List<DataPoint> s) =>
        s.isEmpty ? 0 : s.fold(0.0, (t, p) => t + p.value) / s.length;
    return MacroBreakdown(
      proteinG: avg(protein),
      carbsG: avg(carbs),
      fatG: avg(fat),
      fiberG: 25 + _noise(5), // placeholder fiber
    );
  }

  // ── Nutrition score ───────────────────────────────────────────────────────

  /// 0–100 score based on calorie adherence, water, and logging consistency.
  static double nutritionScore({
    required double avgCal,
    required double targetCal,
    required double avgWater,
    required double targetWater,
    required double consistencyPct,
  }) {
    final calScore =
        (1 - ((avgCal - targetCal).abs() / targetCal)).clamp(0.0, 1.0);
    final waterScore = (avgWater / targetWater).clamp(0.0, 1.0);
    return ((calScore * 0.4 + waterScore * 0.3 + consistencyPct * 0.3) * 100)
        .clamp(0.0, 100.0);
  }

  // ── Weekly macro comparison ────────────────────────────────────────────────

  static Map<String, List<(double, double)>> weeklyMacroComparison(
    List<DataPoint> protSeries,
    List<DataPoint> carbSeries,
    List<DataPoint> fatSeries,
    int weeks,
  ) {
    List<(double, double)> weeklySums(List<DataPoint> series, double target) {
      final result = <(double, double)>[];
      for (var w = weeks - 1; w >= 0; w--) {
        final start = series.length - (w + 1) * 7;
        final end = start + 7;
        if (start < 0) continue;
        final slice = series.sublist(
            start.clamp(0, series.length), end.clamp(0, series.length));
        final actual =
            slice.fold(0.0, (s, p) => s + p.value) / slice.length;
        result.add((target, actual));
      }
      return result;
    }

    return {
      'Protein': weeklySums(protSeries, 100),
      'Carbs': weeklySums(carbSeries, 225),
      'Fat': weeklySums(fatSeries, 65),
    };
  }
}

