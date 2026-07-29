import '../../domain/entities/health_report_entity.dart';
import '../../domain/entities/fitness_report_entity.dart';
import '../../domain/entities/nutrition_report_entity.dart';
import '../../domain/entities/ai_report_entity.dart';
import '../../domain/entities/export_request_entity.dart';

// ══════════════════════════════════════════════════════════════════════════════
// HEALTH REPORT STATE
// ══════════════════════════════════════════════════════════════════════════════

sealed class HealthReportState {
  const HealthReportState();
}

final class HealthReportInitial extends HealthReportState {
  const HealthReportInitial();
}

final class HealthReportLoading extends HealthReportState {
  const HealthReportLoading();
}

final class HealthReportLoaded extends HealthReportState {
  const HealthReportLoaded(this.report);
  final HealthReportEntity report;
}

final class HealthReportError extends HealthReportState {
  const HealthReportError(this.message);
  final String message;
}

// ══════════════════════════════════════════════════════════════════════════════
// FITNESS REPORT STATE
// ══════════════════════════════════════════════════════════════════════════════

sealed class FitnessReportState {
  const FitnessReportState();
}

final class FitnessReportInitial extends FitnessReportState {
  const FitnessReportInitial();
}

final class FitnessReportLoading extends FitnessReportState {
  const FitnessReportLoading();
}

final class FitnessReportLoaded extends FitnessReportState {
  const FitnessReportLoaded(this.report);
  final FitnessReportEntity report;
}

final class FitnessReportError extends FitnessReportState {
  const FitnessReportError(this.message);
  final String message;
}

// ══════════════════════════════════════════════════════════════════════════════
// NUTRITION REPORT STATE
// ══════════════════════════════════════════════════════════════════════════════

sealed class NutritionReportState {
  const NutritionReportState();
}

final class NutritionReportInitial extends NutritionReportState {
  const NutritionReportInitial();
}

final class NutritionReportLoading extends NutritionReportState {
  const NutritionReportLoading();
}

final class NutritionReportLoaded extends NutritionReportState {
  const NutritionReportLoaded(this.report);
  final NutritionReportEntity report;
}

final class NutritionReportError extends NutritionReportState {
  const NutritionReportError(this.message);
  final String message;
}

// ══════════════════════════════════════════════════════════════════════════════
// AI REPORT STATE
// ══════════════════════════════════════════════════════════════════════════════

sealed class AIReportState {
  const AIReportState();
}

final class AIReportInitial extends AIReportState {
  const AIReportInitial();
}

final class AIReportLoading extends AIReportState {
  const AIReportLoading();
}

final class AIReportLoaded extends AIReportState {
  const AIReportLoaded(this.report);
  final AIReportEntity report;
}

final class AIReportError extends AIReportState {
  const AIReportError(this.message);
  final String message;
}

// ══════════════════════════════════════════════════════════════════════════════
// DASHBOARD STATE (composite)
// ══════════════════════════════════════════════════════════════════════════════

sealed class DashboardReportState {
  const DashboardReportState();
}

final class DashboardReportInitial extends DashboardReportState {
  const DashboardReportInitial();
}

final class DashboardReportLoading extends DashboardReportState {
  const DashboardReportLoading();
}

final class DashboardReportLoaded extends DashboardReportState {
  const DashboardReportLoaded({
    required this.overallScore,
    required this.healthScore,
    required this.fitnessScore,
    required this.nutritionScore,
    required this.totalReadings,
    required this.totalWorkouts,
    required this.daysLogged,
  });

  final double overallScore;
  final double healthScore;
  final double fitnessScore;
  final double nutritionScore;
  final int totalReadings;
  final int totalWorkouts;
  final int daysLogged;
}

final class DashboardReportError extends DashboardReportState {
  const DashboardReportError(this.message);
  final String message;
}

// ══════════════════════════════════════════════════════════════════════════════
// EXPORT STATE
// ══════════════════════════════════════════════════════════════════════════════

sealed class ExportState {
  const ExportState();
}

final class ExportIdle extends ExportState {
  const ExportIdle();
}

final class ExportInProgress extends ExportState {
  const ExportInProgress({required this.request});
  final ExportRequestEntity request;
}

final class ExportSuccess extends ExportState {
  const ExportSuccess({required this.request});
  final ExportRequestEntity request;
}

final class ExportFailure extends ExportState {
  const ExportFailure({required this.message});
  final String message;
}
