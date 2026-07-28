import '../entities/blood_pressure_entity.dart';
import '../entities/blood_sugar_entity.dart';
import '../entities/health_dashboard_entity.dart';
import '../entities/spo2_entity.dart';

/// Abstract contract for the Health feature data source.
abstract interface class HealthRepository {
  /// Loads the full health dashboard aggregate.
  Future<HealthDashboardEntity> getDashboard();

  /// Refreshes all health data.
  Future<HealthDashboardEntity> refresh();

  /// Adds a new blood pressure reading and returns updated entity.
  Future<HealthDashboardEntity> addBpReading({
    required int systolic,
    required int diastolic,
    int? pulse,
    String? notes,
  });

  /// Adds a new blood sugar reading and returns updated entity.
  Future<HealthDashboardEntity> addSugarReading({
    required double value,
    required BloodSugarType type,
    String? notes,
  });

  /// Adds a new SpO₂ reading and returns updated entity.
  Future<HealthDashboardEntity> addSpo2Reading({
    required int percentage,
  });
}
