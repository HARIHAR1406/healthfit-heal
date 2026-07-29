import '../entities/report_filter.dart';
import '../entities/health_report_entity.dart';
import '../entities/fitness_report_entity.dart';
import '../entities/nutrition_report_entity.dart';
import '../entities/ai_report_entity.dart';

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
}
