import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/comparison_data_entity.dart';
import '../../domain/entities/health_insight_entity.dart';
import '../../domain/entities/report_filter.dart';
import '../../domain/entities/trend_data_entity.dart';
import '../../domain/repositories/reports_repository.dart';
import 'analytics_state.dart';

final _log = Logger();

// ══════════════════════════════════════════════════════════════════════════════
// INSIGHTS NOTIFIER
// ══════════════════════════════════════════════════════════════════════════════

/// Manages AI-generated health insights with category and type filtering.
class InsightNotifier extends StateNotifier<InsightsState> {
  InsightNotifier(this._repo) : super(const InsightsInitial());

  final ReportsRepository _repo;

  Future<void> load(ActiveFilter filter) async {
    state = const InsightsLoading();
    try {
      final report = await _repo.getInsights(filter);
      state = InsightsLoaded(report: report);
    } catch (e, st) {
      _log.e('InsightNotifier.load error', error: e, stackTrace: st);
      state = InsightsError(e.toString());
    }
  }

  void setCategoryFilter(InsightCategory? category) {
    final loaded = state;
    if (loaded is InsightsLoaded) {
      state = loaded.copyWith(categoryFilter: category);
    }
  }

  void setTypeFilter(InsightType? type) {
    final loaded = state;
    if (loaded is InsightsLoaded) {
      state = loaded.copyWith(typeFilter: type);
    }
  }

  void toggleUnreadOnly() {
    final loaded = state;
    if (loaded is InsightsLoaded) {
      state = loaded.copyWith(showUnreadOnly: !loaded.showUnreadOnly);
    }
  }

  void markRead(String insightId) {
    final loaded = state;
    if (loaded is InsightsLoaded) {
      final updated = loaded.report.insights
          .map((i) => i.id == insightId ? i.copyWith(isRead: true) : i)
          .toList();
      final newReport = InsightsReport(
        insights: updated,
        totalInsights: loaded.report.totalInsights,
        unreadCount: updated.where((i) => !i.isRead).length,
        criticalCount: loaded.report.criticalCount,
        positiveCount: loaded.report.positiveCount,
        lastGeneratedAt: loaded.report.lastGeneratedAt,
      );
      state = loaded.copyWith(report: newReport);
    }
  }

  void markAllRead() {
    final loaded = state;
    if (loaded is InsightsLoaded) {
      final updated =
          loaded.report.insights.map((i) => i.copyWith(isRead: true)).toList();
      final newReport = InsightsReport(
        insights: updated,
        totalInsights: loaded.report.totalInsights,
        unreadCount: 0,
        criticalCount: loaded.report.criticalCount,
        positiveCount: loaded.report.positiveCount,
        lastGeneratedAt: loaded.report.lastGeneratedAt,
      );
      state = loaded.copyWith(report: newReport);
    }
  }

  void reset() => state = const InsightsInitial();
}

// ══════════════════════════════════════════════════════════════════════════════
// TRENDS NOTIFIER
// ══════════════════════════════════════════════════════════════════════════════

/// Manages trend analysis data with metric-level filtering.
class TrendNotifier extends StateNotifier<TrendsState> {
  TrendNotifier(this._repo) : super(const TrendsInitial());

  final ReportsRepository _repo;

  Future<void> load(ActiveFilter filter) async {
    state = const TrendsLoading();
    try {
      final report = await _repo.getTrends(filter);
      state = TrendsLoaded(report: report);
    } catch (e, st) {
      _log.e('TrendNotifier.load error', error: e, stackTrace: st);
      state = TrendsError(e.toString());
    }
  }

  void setMetricFilter(TrendMetric? metric) {
    final loaded = state;
    if (loaded is TrendsLoaded) {
      state = loaded.copyWith(metricFilter: metric);
    }
  }

  void toggleRiskOnly() {
    final loaded = state;
    if (loaded is TrendsLoaded) {
      state = loaded.copyWith(showOnlyRisk: !loaded.showOnlyRisk);
    }
  }

  void reset() => state = const TrendsInitial();
}

// ══════════════════════════════════════════════════════════════════════════════
// COMPARISON NOTIFIER
// ══════════════════════════════════════════════════════════════════════════════

/// Manages period-vs-period comparison data.
class ComparisonNotifier extends StateNotifier<ComparisonState> {
  ComparisonNotifier(this._repo)
      : super(const ComparisonInitial());

  final ReportsRepository _repo;
  ComparisonPeriod _currentPeriod = ComparisonPeriod.weekOverWeek;

  Future<void> load([ComparisonPeriod? period]) async {
    final target = period ?? _currentPeriod;
    _currentPeriod = target;
    state = const ComparisonLoading();
    try {
      final data = await _repo.getComparison(target);
      state = ComparisonLoaded(data: data, selectedPeriod: target);
    } catch (e, st) {
      _log.e('ComparisonNotifier.load error', error: e, stackTrace: st);
      state = ComparisonError(e.toString());
    }
  }

  Future<void> changePeriod(ComparisonPeriod period) => load(period);

  void reset() => state = const ComparisonInitial();
}

// ══════════════════════════════════════════════════════════════════════════════
// ACHIEVEMENTS NOTIFIER
// ══════════════════════════════════════════════════════════════════════════════

/// Manages achievement statistics, goal completion, and personal records.
class AchievementsNotifier extends StateNotifier<AchievementsState> {
  AchievementsNotifier(this._repo) : super(const AchievementsInitial());

  final ReportsRepository _repo;

  Future<void> load(ActiveFilter filter) async {
    state = const AchievementsLoading();
    try {
      final stats = await _repo.getAchievements(filter);
      final records = await _repo.getPersonalRecords();
      state = AchievementsLoaded(statistics: stats, personalRecords: records);
    } catch (e, st) {
      _log.e('AchievementsNotifier.load error', error: e, stackTrace: st);
      state = AchievementsError(e.toString());
    }
  }

  void setTierFilter(AchievementTier? tier) {
    final loaded = state;
    if (loaded is AchievementsLoaded) {
      state = loaded.copyWith(tierFilter: tier);
    }
  }

  void setCategoryFilter(String? category) {
    final loaded = state;
    if (loaded is AchievementsLoaded) {
      state = loaded.copyWith(categoryFilter: category);
    }
  }

  void clearFilters() {
    final loaded = state;
    if (loaded is AchievementsLoaded) {
      state = AchievementsLoaded(
        statistics: loaded.statistics,
        personalRecords: loaded.personalRecords,
      );
    }
  }

  void reset() => state = const AchievementsInitial();
}
