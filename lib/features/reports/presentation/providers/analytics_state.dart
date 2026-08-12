import '../../domain/entities/achievement_statistics_entity.dart';
import '../../domain/entities/comparison_data_entity.dart';
import '../../domain/entities/health_insight_entity.dart';
import '../../domain/entities/trend_data_entity.dart';

// ══════════════════════════════════════════════════════════════════════════════
// INSIGHTS STATE
// ══════════════════════════════════════════════════════════════════════════════

sealed class InsightsState {
  const InsightsState();
}

final class InsightsInitial extends InsightsState {
  const InsightsInitial();
}

final class InsightsLoading extends InsightsState {
  const InsightsLoading();
}

final class InsightsLoaded extends InsightsState {
  const InsightsLoaded({
    required this.report,
    this.categoryFilter,
    this.typeFilter,
    this.showUnreadOnly = false,
  });

  final InsightsReport report;
  final InsightCategory? categoryFilter;
  final InsightType? typeFilter;
  final bool showUnreadOnly;

  List<HealthInsightEntity> get filtered {
    var list = report.insights;
    if (showUnreadOnly) list = list.where((i) => !i.isRead).toList();
    if (categoryFilter != null) {
      list = list.where((i) => i.category == categoryFilter).toList();
    }
    if (typeFilter != null) {
      list = list.where((i) => i.type == typeFilter).toList();
    }
    return list;
  }

  InsightsLoaded copyWith({
    InsightsReport? report,
    Object? categoryFilter = _sentinel,
    Object? typeFilter = _sentinel,
    bool? showUnreadOnly,
  }) =>
      InsightsLoaded(
        report: report ?? this.report,
        categoryFilter: categoryFilter == _sentinel
            ? this.categoryFilter
            : categoryFilter as InsightCategory?,
        typeFilter: typeFilter == _sentinel
            ? this.typeFilter
            : typeFilter as InsightType?,
        showUnreadOnly: showUnreadOnly ?? this.showUnreadOnly,
      );
}

final class InsightsError extends InsightsState {
  const InsightsError(this.message);
  final String message;
}

// sentinel for nullable copyWith
const _sentinel = Object();

// ══════════════════════════════════════════════════════════════════════════════
// TRENDS STATE
// ══════════════════════════════════════════════════════════════════════════════

sealed class TrendsState {
  const TrendsState();
}

final class TrendsInitial extends TrendsState {
  const TrendsInitial();
}

final class TrendsLoading extends TrendsState {
  const TrendsLoading();
}

final class TrendsLoaded extends TrendsState {
  const TrendsLoaded({
    required this.report,
    this.metricFilter,
    this.showOnlyRisk = false,
  });

  final TrendsReport report;
  final TrendMetric? metricFilter;
  final bool showOnlyRisk;

  List<TrendDataEntity> get filtered {
    var list = report.trends;
    if (showOnlyRisk) list = list.where((t) => t.riskLevel != null).toList();
    if (metricFilter != null) {
      list = list.where((t) => t.metric == metricFilter).toList();
    }
    return list;
  }

  TrendsLoaded copyWith({
    TrendsReport? report,
    Object? metricFilter = _sentinel,
    bool? showOnlyRisk,
  }) =>
      TrendsLoaded(
        report: report ?? this.report,
        metricFilter: metricFilter == _sentinel
            ? this.metricFilter
            : metricFilter as TrendMetric?,
        showOnlyRisk: showOnlyRisk ?? this.showOnlyRisk,
      );
}

final class TrendsError extends TrendsState {
  const TrendsError(this.message);
  final String message;
}

// ══════════════════════════════════════════════════════════════════════════════
// COMPARISON STATE
// ══════════════════════════════════════════════════════════════════════════════

sealed class ComparisonState {
  const ComparisonState();
}

final class ComparisonInitial extends ComparisonState {
  const ComparisonInitial();
}

final class ComparisonLoading extends ComparisonState {
  const ComparisonLoading();
}

final class ComparisonLoaded extends ComparisonState {
  const ComparisonLoaded({
    required this.data,
    required this.selectedPeriod,
  });

  final ComparisonDataEntity data;
  final ComparisonPeriod selectedPeriod;
}

final class ComparisonError extends ComparisonState {
  const ComparisonError(this.message);
  final String message;
}

// ══════════════════════════════════════════════════════════════════════════════
// ACHIEVEMENTS STATE
// ══════════════════════════════════════════════════════════════════════════════

sealed class AchievementsState {
  const AchievementsState();
}

final class AchievementsInitial extends AchievementsState {
  const AchievementsInitial();
}

final class AchievementsLoading extends AchievementsState {
  const AchievementsLoading();
}

final class AchievementsLoaded extends AchievementsState {
  const AchievementsLoaded({
    required this.statistics,
    required this.personalRecords,
    this.tierFilter,
    this.categoryFilter,
  });

  final AchievementStatisticsEntity statistics;
  final List<PersonalRecord> personalRecords;
  final AchievementTier? tierFilter;
  final String? categoryFilter;

  List<AchievementEntry> get filteredAchievements {
    var list = statistics.achievements;
    if (tierFilter != null) {
      list = list.where((a) => a.tier == tierFilter).toList();
    }
    if (categoryFilter != null) {
      list = list.where((a) => a.category == categoryFilter).toList();
    }
    return list;
  }

  AchievementsLoaded copyWith({
    AchievementStatisticsEntity? statistics,
    List<PersonalRecord>? personalRecords,
    Object? tierFilter = _sentinel,
    Object? categoryFilter = _sentinel,
  }) =>
      AchievementsLoaded(
        statistics: statistics ?? this.statistics,
        personalRecords: personalRecords ?? this.personalRecords,
        tierFilter: tierFilter == _sentinel
            ? this.tierFilter
            : tierFilter as AchievementTier?,
        categoryFilter: categoryFilter == _sentinel
            ? this.categoryFilter
            : categoryFilter as String?,
      );
}

final class AchievementsError extends AchievementsState {
  const AchievementsError(this.message);
  final String message;
}

