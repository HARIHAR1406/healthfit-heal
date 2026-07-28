import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/bmi_entity.dart';
import '../../domain/entities/blood_sugar_entity.dart';
import '../../domain/repositories/health_repository.dart';
import 'health_state.dart';

/// Manages the Health Module state — loads all sub-module data.
class HealthNotifier extends StateNotifier<HealthState> {
  HealthNotifier({required HealthRepository repository})
      : _repository = repository,
        super(const HealthInitial());

  final HealthRepository _repository;

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> load() async {
    if (state is HealthLoaded) return;
    state = const HealthLoading();
    await _fetch(write: false);
  }

  // ── Refresh ───────────────────────────────────────────────────────────────

  Future<void> refresh() async {
    final current = state.data;
    state = current != null
        ? HealthRefreshing(data: current)
        : const HealthLoading();
    await _fetch(write: false);
  }

  // ── Add Readings ──────────────────────────────────────────────────────────

  Future<void> addBpReading({
    required int systolic,
    required int diastolic,
    int? pulse,
    String? notes,
  }) async {
    final current = state.data;
    if (current == null) return;
    state = HealthSaving(data: current);
    try {
      final updated = await _repository.addBpReading(
        systolic: systolic,
        diastolic: diastolic,
        pulse: pulse,
        notes: notes,
      );
      state = HealthLoaded(data: updated);
      log.info('HealthNotifier: BP reading added');
    } catch (e, st) {
      log.error('HealthNotifier: addBpReading failed', error: e, stackTrace: st);
      state = HealthLoaded(data: current);
    }
  }

  Future<void> addSugarReading({
    required double value,
    required BloodSugarType type,
    String? notes,
  }) async {
    final current = state.data;
    if (current == null) return;
    state = HealthSaving(data: current);
    try {
      final updated = await _repository.addSugarReading(
        value: value,
        type: type,
        notes: notes,
      );
      state = HealthLoaded(data: updated);
      log.info('HealthNotifier: Sugar reading added');
    } catch (e, st) {
      log.error('HealthNotifier: addSugarReading failed',
          error: e, stackTrace: st);
      state = HealthLoaded(data: current);
    }
  }

  Future<void> addSpo2Reading({required int percentage}) async {
    final current = state.data;
    if (current == null) return;
    state = HealthSaving(data: current);
    try {
      final updated = await _repository.addSpo2Reading(
        percentage: percentage,
      );
      state = HealthLoaded(data: updated);
      log.info('HealthNotifier: SpO2 reading added');
    } catch (e, st) {
      log.error('HealthNotifier: addSpo2Reading failed',
          error: e, stackTrace: st);
      state = HealthLoaded(data: current);
    }
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<void> _fetch({required bool write}) async {
    try {
      final data = await _repository.getDashboard();
      state = HealthLoaded(data: data);
    } on AppException catch (e) {
      log.error('HealthNotifier: load failed', error: e);
      state = HealthError(message: e.message);
    } catch (e, st) {
      log.error('HealthNotifier: unexpected error', error: e, stackTrace: st);
      state = const HealthError(
        message: 'Failed to load health data. Pull to refresh.',
      );
    }
  }
}

// ── BMI Calculator Notifier ───────────────────────────────────────────────────

/// Manages the local BMI calculator form state.
/// No repository call — BMI is computed client-side.
class BmiCalculatorNotifier extends StateNotifier<BmiCalculatorState> {
  BmiCalculatorNotifier() : super(const BmiCalculatorState());

  void toggleUnit() {
    final next = state.unit == BmiUnitSystem.metric
        ? BmiUnitSystem.imperial
        : BmiUnitSystem.metric;
    state = state.copyWith(unit: next, calculatedBmi: state.calculatedBmi);
  }

  void updateHeightCm(double value) =>
      state = state.copyWith(heightCm: value);
  void updateWeightKg(double value) =>
      state = state.copyWith(weightKg: value);
  void updateHeightFt(double value) =>
      state = state.copyWith(heightFt: value);
  void updateHeightIn(double value) =>
      state = state.copyWith(heightIn: value);
  void updateWeightLb(double value) =>
      state = state.copyWith(weightLb: value);

  void calculate() {
    double bmi;
    if (state.unit == BmiUnitSystem.metric) {
      bmi = BmiEntity.calculateMetric(
        heightCm: state.heightCm,
        weightKg: state.weightKg,
      );
    } else {
      final totalInches = (state.heightFt * 12) + state.heightIn;
      bmi = BmiEntity.calculateImperial(
        heightInches: totalInches,
        weightLb: state.weightLb,
      );
    }
    state = state.copyWith(calculatedBmi: bmi);
  }

  void reset() => state = const BmiCalculatorState();
}
