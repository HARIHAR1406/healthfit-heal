import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/mock_reports_repository.dart';
import '../../domain/entities/ai_report_entity.dart';
import '../../domain/entities/fitness_report_entity.dart';
import '../../domain/entities/health_report_entity.dart';
import '../../domain/entities/nutrition_report_entity.dart';
import '../../domain/entities/report_filter.dart';
import '../../domain/repositories/reports_repository.dart';
import 'reports_notifier.dart';
import 'reports_state.dart';

// ══════════════════════════════════════════════════════════════════════════════
// REPOSITORY PROVIDER
// ══════════════════════════════════════════════════════════════════════════════

/// Provides the [ReportsRepository] implementation.
/// Swap to [ApiReportsRepository] or [FirebaseReportsRepository] here.
final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return const MockReportsRepository();
});

// ══════════════════════════════════════════════════════════════════════════════
// FILTER PROVIDER
// ══════════════════════════════════════════════════════════════════════════════

/// Global analytics date filter — changing triggers all analytics to refresh.
final analyticsFilterProvider = StateProvider<ActiveFilter>((ref) {
  return const ActiveFilter(filter: DateFilter.thisWeek);
});

// ══════════════════════════════════════════════════════════════════════════════
// NOTIFIER PROVIDERS
// ══════════════════════════════════════════════════════════════════════════════

final dashboardReportProvider =
    StateNotifierProvider<DashboardNotifier, DashboardReportState>((ref) {
  return DashboardNotifier(ref.watch(reportsRepositoryProvider));
});

final healthReportProvider =
    StateNotifierProvider<HealthReportNotifier, HealthReportState>((ref) {
  return HealthReportNotifier(ref.watch(reportsRepositoryProvider));
});

final fitnessReportProvider =
    StateNotifierProvider<FitnessReportNotifier, FitnessReportState>((ref) {
  return FitnessReportNotifier(ref.watch(reportsRepositoryProvider));
});

final nutritionReportProvider =
    StateNotifierProvider<NutritionReportNotifier, NutritionReportState>((ref) {
  return NutritionReportNotifier(ref.watch(reportsRepositoryProvider));
});

final aiReportProvider =
    StateNotifierProvider<AIReportNotifier, AIReportState>((ref) {
  return AIReportNotifier(ref.watch(reportsRepositoryProvider));
});

final exportProvider =
    StateNotifierProvider<ExportNotifier, ExportState>((ref) {
  return ExportNotifier();
});

// ══════════════════════════════════════════════════════════════════════════════
// FILTER HELPER PROVIDERS
// ══════════════════════════════════════════════════════════════════════════════

/// Currently selected [DateFilter] enum value.
final activeDateFilterProvider = Provider<DateFilter>((ref) {
  return ref.watch(analyticsFilterProvider).filter;
});

/// Human-readable label for the current filter.
final filterLabelProvider = Provider<String>((ref) {
  return ref.watch(analyticsFilterProvider).label;
});

// ══════════════════════════════════════════════════════════════════════════════
// DERIVED DATA PROVIDERS (memoised selectors)
// ══════════════════════════════════════════════════════════════════════════════

/// Health score (0–100) from loaded health report, or null.
final healthScoreProvider = Provider<double?>((ref) {
  final state = ref.watch(healthReportProvider);
  return state is HealthReportLoaded ? state.report.healthScore : null;
});

/// Heart rate series from loaded health report, or empty list.
final heartRateSeriesProvider = Provider<List<DataPoint>>((ref) {
  final state = ref.watch(healthReportProvider);
  return state is HealthReportLoaded ? state.report.heartRateSeries : [];
});

/// BP series from loaded health report, or empty list.
final bpSeriesProvider = Provider<List<DataPoint2>>((ref) {
  final state = ref.watch(healthReportProvider);
  return state is HealthReportLoaded ? state.report.bpSeries : [];
});

/// Total calories burned from loaded fitness report, or null.
final totalCaloriesBurnedProvider = Provider<double?>((ref) {
  final state = ref.watch(fitnessReportProvider);
  return state is FitnessReportLoaded
      ? state.report.totalCaloriesBurned
      : null;
});

/// Workout category breakdown from loaded fitness report, or empty list.
final categoryBreakdownProvider =
    Provider<List<WorkoutCategoryBreakdown>>((ref) {
  final state = ref.watch(fitnessReportProvider);
  return state is FitnessReportLoaded ? state.report.categoryBreakdown : [];
});

/// Streak data from loaded fitness report, or null.
final streakDataProvider = Provider<StreakData?>((ref) {
  final state = ref.watch(fitnessReportProvider);
  return state is FitnessReportLoaded ? state.report.streak : null;
});

/// Macro average from loaded nutrition report, or null.
final macroAvgProvider = Provider<MacroBreakdown?>((ref) {
  final state = ref.watch(nutritionReportProvider);
  return state is NutritionReportLoaded ? state.report.macroAvg : null;
});

/// Topic frequency list from AI report, or empty.
final topicFrequencyProvider = Provider<List<TopicFrequency>>((ref) {
  final state = ref.watch(aiReportProvider);
  return state is AIReportLoaded ? state.report.topicFrequency : [];
});

/// Coach usage list from AI report, or empty.
final coachUsageProvider = Provider<List<CoachUsage>>((ref) {
  final state = ref.watch(aiReportProvider);
  return state is AIReportLoaded ? state.report.coachUsage : [];
});

/// Weekly AI insights from AI report, or empty.
final weeklyInsightsProvider = Provider<List<WeeklyAIInsight>>((ref) {
  final state = ref.watch(aiReportProvider);
  return state is AIReportLoaded ? state.report.weeklyInsights : [];
});

// ══════════════════════════════════════════════════════════════════════════════
// LOADING / ERROR HELPERS
// ══════════════════════════════════════════════════════════════════════════════

/// True if any analytics domain is currently loading.
final isAnyReportLoadingProvider = Provider<bool>((ref) {
  final dash = ref.watch(dashboardReportProvider);
  final health = ref.watch(healthReportProvider);
  final fitness = ref.watch(fitnessReportProvider);
  final nutrition = ref.watch(nutritionReportProvider);
  final ai = ref.watch(aiReportProvider);

  return dash is DashboardReportLoading ||
      health is HealthReportLoading ||
      fitness is FitnessReportLoading ||
      nutrition is NutritionReportLoading ||
      ai is AIReportLoading;
});

