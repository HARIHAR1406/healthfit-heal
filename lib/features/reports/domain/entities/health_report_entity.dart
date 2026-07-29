import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════════
// DATA POINT
// ══════════════════════════════════════════════════════════════════════════════

/// Generic time-series data point.
@immutable
class DataPoint {
  const DataPoint({required this.date, required this.value});
  final DateTime date;
  final double value;
}

/// Two-value data point (e.g. systolic + diastolic BP).
@immutable
class DataPoint2 {
  const DataPoint2({
    required this.date,
    required this.value1,
    required this.value2,
  });
  final DateTime date;
  final double value1;
  final double value2;
}

// ══════════════════════════════════════════════════════════════════════════════
// HEALTH REPORT ENTITY
// ══════════════════════════════════════════════════════════════════════════════

/// Aggregated health analytics for a given date range.
@immutable
class HealthReportEntity {
  const HealthReportEntity({
    required this.healthScore,
    required this.healthScoreDelta,
    required this.heartRateSeries,
    required this.avgHeartRate,
    required this.minHeartRate,
    required this.maxHeartRate,
    required this.heartRateDelta,
    required this.bpSeries,
    required this.avgSystolic,
    required this.avgDiastolic,
    required this.bpDelta,
    required this.bloodSugarSeries,
    required this.avgBloodSugar,
    required this.bloodSugarDelta,
    required this.spo2Series,
    required this.avgSpo2,
    required this.spo2Delta,
    required this.bmiSeries,
    required this.currentBmi,
    required this.bmiDelta,
    required this.weightSeries,
    required this.currentWeight,
    required this.weightDelta,
    required this.radarScores,
    required this.totalReadings,
  });

  /// 0–100 composite score
  final double healthScore;

  /// Delta vs. previous period (+/-)
  final double healthScoreDelta;

  // ── Heart Rate ─────────────────────────────────────────────────────────────
  final List<DataPoint> heartRateSeries;
  final double avgHeartRate;
  final double minHeartRate;
  final double maxHeartRate;
  final double heartRateDelta;

  // ── Blood Pressure ─────────────────────────────────────────────────────────
  final List<DataPoint2> bpSeries;
  final double avgSystolic;
  final double avgDiastolic;
  final double bpDelta;

  // ── Blood Sugar ────────────────────────────────────────────────────────────
  final List<DataPoint> bloodSugarSeries;
  final double avgBloodSugar;
  final double bloodSugarDelta;

  // ── SpO₂ ──────────────────────────────────────────────────────────────────
  final List<DataPoint> spo2Series;
  final double avgSpo2;
  final double spo2Delta;

  // ── BMI ───────────────────────────────────────────────────────────────────
  final List<DataPoint> bmiSeries;
  final double currentBmi;
  final double bmiDelta;

  // ── Weight ────────────────────────────────────────────────────────────────
  final List<DataPoint> weightSeries;
  final double currentWeight; // in kg
  final double weightDelta;

  // ── Radar (6 axes: Cardio, BP, Sugar, SpO2, BMI, Sleep) ──────────────────
  /// Values 0–1 for each radar axis.
  final Map<String, double> radarScores;

  final int totalReadings;

  HealthReportEntity copyWith({
    double? healthScore,
    double? healthScoreDelta,
    List<DataPoint>? heartRateSeries,
    double? avgHeartRate,
    double? minHeartRate,
    double? maxHeartRate,
    double? heartRateDelta,
    List<DataPoint2>? bpSeries,
    double? avgSystolic,
    double? avgDiastolic,
    double? bpDelta,
    List<DataPoint>? bloodSugarSeries,
    double? avgBloodSugar,
    double? bloodSugarDelta,
    List<DataPoint>? spo2Series,
    double? avgSpo2,
    double? spo2Delta,
    List<DataPoint>? bmiSeries,
    double? currentBmi,
    double? bmiDelta,
    List<DataPoint>? weightSeries,
    double? currentWeight,
    double? weightDelta,
    Map<String, double>? radarScores,
    int? totalReadings,
  }) =>
      HealthReportEntity(
        healthScore: healthScore ?? this.healthScore,
        healthScoreDelta: healthScoreDelta ?? this.healthScoreDelta,
        heartRateSeries: heartRateSeries ?? this.heartRateSeries,
        avgHeartRate: avgHeartRate ?? this.avgHeartRate,
        minHeartRate: minHeartRate ?? this.minHeartRate,
        maxHeartRate: maxHeartRate ?? this.maxHeartRate,
        heartRateDelta: heartRateDelta ?? this.heartRateDelta,
        bpSeries: bpSeries ?? this.bpSeries,
        avgSystolic: avgSystolic ?? this.avgSystolic,
        avgDiastolic: avgDiastolic ?? this.avgDiastolic,
        bpDelta: bpDelta ?? this.bpDelta,
        bloodSugarSeries: bloodSugarSeries ?? this.bloodSugarSeries,
        avgBloodSugar: avgBloodSugar ?? this.avgBloodSugar,
        bloodSugarDelta: bloodSugarDelta ?? this.bloodSugarDelta,
        spo2Series: spo2Series ?? this.spo2Series,
        avgSpo2: avgSpo2 ?? this.avgSpo2,
        spo2Delta: spo2Delta ?? this.spo2Delta,
        bmiSeries: bmiSeries ?? this.bmiSeries,
        currentBmi: currentBmi ?? this.currentBmi,
        bmiDelta: bmiDelta ?? this.bmiDelta,
        weightSeries: weightSeries ?? this.weightSeries,
        currentWeight: currentWeight ?? this.currentWeight,
        weightDelta: weightDelta ?? this.weightDelta,
        radarScores: radarScores ?? this.radarScores,
        totalReadings: totalReadings ?? this.totalReadings,
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// BMI CATEGORY
// ══════════════════════════════════════════════════════════════════════════════

enum BmiCategory {
  underweight('Underweight', Color(0xFF00B4D8)),
  normal('Normal', Color(0xFF00C896)),
  overweight('Overweight', Color(0xFFFFBF00)),
  obese('Obese', Color(0xFFFF6B6B));

  const BmiCategory(this.label, this.color);
  final String label;
  final Color color;

  static BmiCategory fromBmi(double bmi) {
    if (bmi < 18.5) return BmiCategory.underweight;
    if (bmi < 25) return BmiCategory.normal;
    if (bmi < 30) return BmiCategory.overweight;
    return BmiCategory.obese;
  }
}
