import 'dart:math';

import '../../domain/entities/health_report_entity.dart';

// ══════════════════════════════════════════════════════════════════════════════
// HEALTH MOCK DATA
// ══════════════════════════════════════════════════════════════════════════════

/// Generates 90 days of realistic health vitals mock data.
///
/// Values oscillate around medically plausible baselines using a combination
/// of sine waves and clamped Gaussian noise for realism.
class HealthMockData {
  HealthMockData._();

  static final _rng = Random(42); // fixed seed for reproducibility

  // ── Generation helpers ────────────────────────────────────────────────────

  static double _noise(double sigma) =>
      (_rng.nextDouble() + _rng.nextDouble() + _rng.nextDouble() - 1.5) *
      sigma;

  static List<DataPoint> _series(
    int days,
    double baseline,
    double amplitude,
    double sigma, {
    double min = 0,
    double max = double.infinity,
  }) {
    final today = DateTime.now();
    return List.generate(days, (i) {
      final date =
          today.subtract(Duration(days: days - 1 - i));
      final wave = sin(i * 2 * pi / 7) * amplitude; // weekly cycle
      final value = (baseline + wave + _noise(sigma)).clamp(min, max);
      return DataPoint(date: date, value: double.parse(value.toStringAsFixed(1)));
    });
  }

  // ── Public dataset ─────────────────────────────────────────────────────────

  /// 90 days of resting heart rate (bpm).
  static List<DataPoint> heartRateSeries(int days) =>
      _series(days, 72, 5, 4, min: 48, max: 110);

  /// 90 days of systolic blood pressure (mmHg).
  static List<DataPoint> systolicSeries(int days) =>
      _series(days, 118, 6, 3, min: 90, max: 160);

  /// 90 days of diastolic blood pressure (mmHg).
  static List<DataPoint> diastolicSeries(int days) =>
      _series(days, 76, 4, 2, min: 60, max: 100);

  /// Paired BP series.
  static List<DataPoint2> bpSeries(int days) {
    final sys = systolicSeries(days);
    final dia = diastolicSeries(days);
    return List.generate(days, (i) => DataPoint2(
          date: sys[i].date,
          value1: sys[i].value,
          value2: dia[i].value,
        ));
  }

  /// 90 days of fasting blood sugar (mg/dL).
  static List<DataPoint> bloodSugarSeries(int days) =>
      _series(days, 95, 8, 5, min: 70, max: 180);

  /// 90 days of SpO₂ (%).
  static List<DataPoint> spo2Series(int days) =>
      _series(days, 97.5, 1, 0.5, min: 92, max: 100);

  /// 90 days of BMI values.
  static List<DataPoint> bmiSeries(int days) =>
      _series(days, 24.2, 0.3, 0.1, min: 16, max: 40);

  /// 90 days of body weight (kg).
  static List<DataPoint> weightSeries(int days) =>
      _series(days, 72.0, 0.8, 0.3, min: 45, max: 130);

  // ── Aggregation helpers ────────────────────────────────────────────────────

  static double avg(List<DataPoint> series) {
    if (series.isEmpty) return 0;
    return series.fold(0.0, (s, p) => s + p.value) / series.length;
  }

  static double minVal(List<DataPoint> series) =>
      series.fold(double.infinity, (m, p) => p.value < m ? p.value : m);

  static double maxVal(List<DataPoint> series) =>
      series.fold(double.negativeInfinity, (m, p) => p.value > m ? p.value : m);

  // ── Radar scores ──────────────────────────────────────────────────────────

  /// Produce 0–1 radar scores for the 6 health axes.
  static Map<String, double> radarScores({
    required double avgHr,
    required double avgSys,
    required double avgSugar,
    required double avgSpo2,
    required double bmi,
  }) {
    double hrScore = 1 - ((avgHr - 65).abs() / 35).clamp(0.0, 1.0);
    double bpScore = 1 - ((avgSys - 115).abs() / 45).clamp(0.0, 1.0);
    double sugarScore = 1 - ((avgSugar - 90).abs() / 60).clamp(0.0, 1.0);
    double spo2Score = ((avgSpo2 - 92) / 8).clamp(0.0, 1.0);
    double bmiScore =
        1 - ((bmi - 22).abs() / 10).clamp(0.0, 1.0);
    double sleepScore = 0.75 + _noise(0.1); // placeholder

    return {
      'Cardio': double.parse(hrScore.clamp(0.3, 1.0).toStringAsFixed(2)),
      'Blood Pressure': double.parse(bpScore.clamp(0.3, 1.0).toStringAsFixed(2)),
      'Blood Sugar': double.parse(sugarScore.clamp(0.3, 1.0).toStringAsFixed(2)),
      'SpO₂': double.parse(spo2Score.clamp(0.4, 1.0).toStringAsFixed(2)),
      'BMI': double.parse(bmiScore.clamp(0.3, 1.0).toStringAsFixed(2)),
      'Sleep': double.parse(sleepScore.clamp(0.3, 1.0).toStringAsFixed(2)),
    };
  }

  // ── Health score ──────────────────────────────────────────────────────────

  /// Compute 0–100 composite health score from radar axes.
  static double healthScore(Map<String, double> radar) {
    if (radar.isEmpty) return 0;
    final avg = radar.values.fold(0.0, (s, v) => s + v) / radar.length;
    return (avg * 100).clamp(0.0, 100.0);
  }
}

