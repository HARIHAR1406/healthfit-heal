import '../../domain/entities/health_dashboard_entity.dart';

/// Sealed state hierarchy for the Health Module.
sealed class HealthState {
  const HealthState();
}

/// Before any data load.
final class HealthInitial extends HealthState {
  const HealthInitial();
}

/// First-load skeleton is showing.
final class HealthLoading extends HealthState {
  const HealthLoading();
}

/// All health data loaded successfully.
final class HealthLoaded extends HealthState {
  const HealthLoaded({required this.data});
  final HealthDashboardEntity data;
}

/// Pull-to-refresh — stale data still shown.
final class HealthRefreshing extends HealthState {
  const HealthRefreshing({required this.data});
  final HealthDashboardEntity data;
}

/// A write operation (add reading) is in progress.
final class HealthSaving extends HealthState {
  const HealthSaving({required this.data});
  final HealthDashboardEntity data;
}

/// Load or operation failed.
final class HealthError extends HealthState {
  const HealthError({required this.message});
  final String message;
}

// ── Extension helpers ─────────────────────────────────────────────────────────

extension HealthStateX on HealthState {
  bool get isLoading => this is HealthLoading || this is HealthRefreshing;
  bool get isSaving => this is HealthSaving;

  bool get hasData =>
      this is HealthLoaded ||
      this is HealthRefreshing ||
      this is HealthSaving;

  HealthDashboardEntity? get data => switch (this) {
        HealthLoaded(:final data) => data,
        HealthRefreshing(:final data) => data,
        HealthSaving(:final data) => data,
        _ => null,
      };

  String? get errorMessage =>
      this is HealthError ? (this as HealthError).message : null;
}

// ── BMI Calculator state (local, no repository) ────────────────────────────────

/// Enum for metric vs imperial.
enum BmiUnitSystem { metric, imperial }

/// Local form state for the BMI Calculator.
class BmiCalculatorState {
  const BmiCalculatorState({
    this.unit = BmiUnitSystem.metric,
    this.heightCm = 170.0,
    this.weightKg = 70.0,
    this.heightFt = 5.0,
    this.heightIn = 7.0,
    this.weightLb = 154.0,
    this.calculatedBmi,
  });

  final BmiUnitSystem unit;

  // Metric inputs
  final double heightCm;
  final double weightKg;

  // Imperial inputs
  final double heightFt;
  final double heightIn;
  final double weightLb;

  /// null until the user triggers a calculation.
  final double? calculatedBmi;

  BmiCalculatorState copyWith({
    BmiUnitSystem? unit,
    double? heightCm,
    double? weightKg,
    double? heightFt,
    double? heightIn,
    double? weightLb,
    double? calculatedBmi,
  }) {
    return BmiCalculatorState(
      unit: unit ?? this.unit,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      heightFt: heightFt ?? this.heightFt,
      heightIn: heightIn ?? this.heightIn,
      weightLb: weightLb ?? this.weightLb,
      calculatedBmi: calculatedBmi ?? this.calculatedBmi,
    );
  }
}
