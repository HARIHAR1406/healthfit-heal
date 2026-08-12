import '../entities/report_filter.dart';
import '../entities/health_report_entity.dart';
import '../entities/fitness_report_entity.dart';
import '../entities/nutrition_report_entity.dart';
import '../entities/ai_report_entity.dart';
import '../entities/health_insight_entity.dart';
import '../entities/trend_data_entity.dart';
import '../entities/comparison_data_entity.dart';
import '../entities/achievement_statistics_entity.dart';

// ══════════════════════════════════════════════════════════════════════════════
// REPORTS REPOSITORY (ABSTRACT)
// ══════════════════════════════════════════════════════════════════════════════

/// Abstract interface for all reports & analytics data.
///
/// Concrete implementations:
/// - [MockReportsRepository] — local mock with 90 days of realistic data
/// - Future: FirebaseReportsRepository, ApiReportsRepository
abstract class ReportsRepository {
  // ── Health ─────────────────────────────────────────────────────────────────

  /// Fetches aggregated health analytics for the given [filter].
  Future<HealthReportEntity> getHealthReport(ActiveFilter filter);

  // ── Fitness ────────────────────────────────────────────────────────────────

  /// Fetches aggregated fitness analytics for the given [filter].
  Future<FitnessReportEntity> getFitnessReport(ActiveFilter filter);

  // ── Nutrition ──────────────────────────────────────────────────────────────

  /// Fetches aggregated nutrition analytics for the given [filter].
  Future<NutritionReportEntity> getNutritionReport(ActiveFilter filter);

  // ── AI ─────────────────────────────────────────────────────────────────────

  /// Fetches aggregated AI usage analytics for the given [filter].
  Future<AIReportEntity> getAIReport(ActiveFilter filter);

  // ── Overall Score ──────────────────────────────────────────────────────────

  /// Returns an 0–100 overall health score by compositing all modules.
  Future<double> getOverallHealthScore(ActiveFilter filter);

  // ── AI Health Insights ────────────────────────────────────────────────────

  /// Fetches AI-generated health insights for the given [filter].
  Future<InsightsReport> getInsights(ActiveFilter filter);

  // ── Trend Analysis ────────────────────────────────────────────────────────

  /// Fetches trend analysis across all metrics for the given [filter].
  Future<TrendsReport> getTrends(ActiveFilter filter);

  // ── Comparison ────────────────────────────────────────────────────────────

  /// Fetches a comparison between the current period and a prior equal period.
  Future<ComparisonDataEntity> getComparison(
    ComparisonPeriod period, {
    DateTime? customStart,
    DateTime? customEnd,
  });

  // ── Achievements ──────────────────────────────────────────────────────────

  /// Fetches full achievement and goal statistics.
  Future<AchievementStatisticsEntity> getAchievements(ActiveFilter filter);

  // ── Personal Records ──────────────────────────────────────────────────────

  /// Fetches all-time personal records.
  Future<List<PersonalRecord>> getPersonalRecords();
}


