import 'bmi_entity.dart';
import 'blood_pressure_entity.dart';
import 'blood_sugar_entity.dart';
import 'heart_rate_entity.dart';
import 'health_record_entity.dart';
import 'spo2_entity.dart';

/// Aggregated health dashboard entity containing all sub-module data.
class HealthDashboardEntity {
  const HealthDashboardEntity({
    required this.healthScore,
    required this.healthStatus,
    required this.bmi,
    required this.heartRate,
    required this.bloodPressure,
    required this.bloodSugar,
    required this.spo2,
    required this.recentRecords,
    required this.historyItems,
    required this.lastUpdated,
  });

  /// Aggregate wellness score out of 100.
  final int healthScore;

  /// Human-readable status label, e.g. "Good".
  final String healthStatus;

  final BmiEntity bmi;
  final HeartRateEntity heartRate;
  final BloodPressureEntity bloodPressure;
  final BloodSugarEntity bloodSugar;
  final Spo2Entity spo2;

  /// Latest 5 medical records for the Medical Overview section.
  final List<HealthRecordEntity> recentRecords;

  /// All health history timeline items.
  final List<HealthHistoryItem> historyItems;

  final DateTime lastUpdated;

  // ── Computed ──────────────────────────────────────────────────────────────

  double get healthScoreFraction => healthScore / 100.0;

  /// Whether any metric is in a critical or warning state.
  bool get hasAlerts =>
      heartRate.status.index >= 2 ||
      bloodPressure.latestReading.status.isCritical ||
      spo2.status != Spo2Status.normal;
}
