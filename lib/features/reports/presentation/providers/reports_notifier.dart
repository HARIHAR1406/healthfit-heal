import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/export_request_entity.dart';
import '../../domain/entities/report_filter.dart';
import '../../domain/repositories/reports_repository.dart';
import 'reports_state.dart';

final _log = Logger();

// ══════════════════════════════════════════════════════════════════════════════
// DASHBOARD NOTIFIER
// ══════════════════════════════════════════════════════════════════════════════

class DashboardNotifier extends StateNotifier<DashboardReportState> {
  DashboardNotifier(this._repo) : super(const DashboardReportInitial());

  final ReportsRepository _repo;

  Future<void> load(ActiveFilter filter) async {
    state = const DashboardReportLoading();
    try {
      final health = await _repo.getHealthReport(filter);
      final fitness = await _repo.getFitnessReport(filter);
      final nutrition = await _repo.getNutritionReport(filter);
      final overall = (health.healthScore * 0.4 +
              fitness.goalCompletionRate.clamp(0.0, 1.0) * 100 * 0.3 +
              nutrition.nutritionScore * 0.3)
          .clamp(0.0, 100.0);

      state = DashboardReportLoaded(
        overallScore: overall,
        healthScore: health.healthScore,
        fitnessScore: fitness.goalCompletionRate * 100,
        nutritionScore: nutrition.nutritionScore,
        totalReadings: health.totalReadings,
        totalWorkouts: fitness.totalWorkouts,
        daysLogged: nutrition.daysLogged,
      );
    } catch (e, st) {
      _log.e('DashboardNotifier.load error', error: e, stackTrace: st);
      state = DashboardReportError(e.toString());
    }
  }

  void reset() => state = const DashboardReportInitial();
}

// ══════════════════════════════════════════════════════════════════════════════
// HEALTH REPORT NOTIFIER
// ══════════════════════════════════════════════════════════════════════════════

class HealthReportNotifier extends StateNotifier<HealthReportState> {
  HealthReportNotifier(this._repo) : super(const HealthReportInitial());

  final ReportsRepository _repo;

  Future<void> load(ActiveFilter filter) async {
    state = const HealthReportLoading();
    try {
      final report = await _repo.getHealthReport(filter);
      state = HealthReportLoaded(report);
    } catch (e, st) {
      _log.e('HealthReportNotifier.load error', error: e, stackTrace: st);
      state = HealthReportError(e.toString());
    }
  }

  void reset() => state = const HealthReportInitial();
}

// ══════════════════════════════════════════════════════════════════════════════
// FITNESS REPORT NOTIFIER
// ══════════════════════════════════════════════════════════════════════════════

class FitnessReportNotifier extends StateNotifier<FitnessReportState> {
  FitnessReportNotifier(this._repo) : super(const FitnessReportInitial());

  final ReportsRepository _repo;

  Future<void> load(ActiveFilter filter) async {
    state = const FitnessReportLoading();
    try {
      final report = await _repo.getFitnessReport(filter);
      state = FitnessReportLoaded(report);
    } catch (e, st) {
      _log.e('FitnessReportNotifier.load error', error: e, stackTrace: st);
      state = FitnessReportError(e.toString());
    }
  }

  void reset() => state = const FitnessReportInitial();
}

// ══════════════════════════════════════════════════════════════════════════════
// NUTRITION REPORT NOTIFIER
// ══════════════════════════════════════════════════════════════════════════════

class NutritionReportNotifier extends StateNotifier<NutritionReportState> {
  NutritionReportNotifier(this._repo) : super(const NutritionReportInitial());

  final ReportsRepository _repo;

  Future<void> load(ActiveFilter filter) async {
    state = const NutritionReportLoading();
    try {
      final report = await _repo.getNutritionReport(filter);
      state = NutritionReportLoaded(report);
    } catch (e, st) {
      _log.e('NutritionReportNotifier.load error', error: e, stackTrace: st);
      state = NutritionReportError(e.toString());
    }
  }

  void reset() => state = const NutritionReportInitial();
}

// ══════════════════════════════════════════════════════════════════════════════
// AI REPORT NOTIFIER
// ══════════════════════════════════════════════════════════════════════════════

class AIReportNotifier extends StateNotifier<AIReportState> {
  AIReportNotifier(this._repo) : super(const AIReportInitial());

  final ReportsRepository _repo;

  Future<void> load(ActiveFilter filter) async {
    state = const AIReportLoading();
    try {
      final report = await _repo.getAIReport(filter);
      state = AIReportLoaded(report);
    } catch (e, st) {
      _log.e('AIReportNotifier.load error', error: e, stackTrace: st);
      state = AIReportError(e.toString());
    }
  }

  void reset() => state = const AIReportInitial();
}

// ══════════════════════════════════════════════════════════════════════════════
// EXPORT NOTIFIER
// ══════════════════════════════════════════════════════════════════════════════

class ExportNotifier extends StateNotifier<ExportState> {
  ExportNotifier() : super(const ExportIdle());

  /// Simulates an export request — no actual file I/O.
  Future<void> requestExport({
    required ExportFormat format,
    required ExportScope scope,
    required String dateRangeLabel,
  }) async {
    final request = ExportRequestEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      format: format,
      scope: scope,
      dateRangeLabel: dateRangeLabel,
      requestedAt: DateTime.now(),
      isLoading: true,
    );
    state = ExportInProgress(request: request);

    // Simulate processing delay
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    // In a real implementation, file generation happens here.
    // For now, we resolve with a fake success.
    state = ExportSuccess(
      request: request.copyWith(
        completedAt: DateTime.now(),
        filePath: '/exports/${scope.name}_${format.extension}_${request.id}.${format.extension}',
        isLoading: false,
      ),
    );
  }

  void reset() => state = const ExportIdle();
}

