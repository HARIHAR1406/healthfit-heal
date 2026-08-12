import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/achievement_statistics_entity.dart';
import '../../domain/entities/comparison_data_entity.dart';
import '../../domain/entities/health_insight_entity.dart';
import '../../domain/entities/trend_data_entity.dart';
import 'analytics_notifier.dart';
import 'analytics_state.dart';
import 'reports_providers.dart';

// ══════════════════════════════════════════════════════════════════════════════
// NOTIFIER PROVIDERS
// ══════════════════════════════════════════════════════════════════════════════

/// AI-generated health insights notifier.
final insightNotifierProvider =
    StateNotifierProvider<InsightNotifier, InsightsState>((ref) {
  return InsightNotifier(ref.watch(reportsRepositoryProvider));
});

/// Trend analysis notifier.
final trendNotifierProvider =
    StateNotifierProvider<TrendNotifier, TrendsState>((ref) {
  return TrendNotifier(ref.watch(reportsRepositoryProvider));
});

/// Period comparison notifier (this week vs last week, etc.).
final comparisonNotifierProvider =
    StateNotifierProvider<ComparisonNotifier, ComparisonState>((ref) {
  return ComparisonNotifier(ref.watch(reportsRepositoryProvider));
});

/// Achievements and goal statistics notifier.
final achievementsNotifierProvider =
    StateNotifierProvider<AchievementsNotifier, AchievementsState>((ref) {
  return AchievementsNotifier(ref.watch(reportsRepositoryProvider));
});

// ══════════════════════════════════════════════════════════════════════════════
// SELECTED COMPARISON PERIOD PROVIDER
// ══════════════════════════════════════════════════════════════════════════════

/// The currently selected comparison period.
final selectedComparisonPeriodProvider =
    StateProvider<ComparisonPeriod>((ref) => ComparisonPeriod.weekOverWeek);

// ══════════════════════════════════════════════════════════════════════════════
// DERIVED SELECTORS — INSIGHTS
// ══════════════════════════════════════════════════════════════════════════════

/// Unread insight count badge.
final unreadInsightCountProvider = Provider<int>((ref) {
  final state = ref.watch(insightNotifierProvider);
  return state is InsightsLoaded ? state.report.unreadCount : 0;
});

/// Risk alert insights only.
final riskAlertInsightsProvider =
    Provider<List<HealthInsightEntity>>((ref) {
  final state = ref.watch(insightNotifierProvider);
  return state is InsightsLoaded ? state.report.riskAlerts : [];
});

/// Daily insights only.
final dailyInsightsProvider =
    Provider<List<HealthInsightEntity>>((ref) {
  final state = ref.watch(insightNotifierProvider);
  return state is InsightsLoaded ? state.report.dailyInsights : [];
});

/// Positive insights and achievements.
final positiveInsightsProvider =
    Provider<List<HealthInsightEntity>>((ref) {
  final state = ref.watch(insightNotifierProvider);
  return state is InsightsLoaded ? state.report.achievements : [];
});

/// Filtered insight list (respects active filters).
final filteredInsightsProvider =
    Provider<List<HealthInsightEntity>>((ref) {
  final state = ref.watch(insightNotifierProvider);
  return state is InsightsLoaded ? state.filtered : [];
});

// ══════════════════════════════════════════════════════════════════════════════
// DERIVED SELECTORS — TRENDS
// ══════════════════════════════════════════════════════════════════════════════

/// Number of improving trends.
final improvingTrendCountProvider = Provider<int>((ref) {
  final state = ref.watch(trendNotifierProvider);
  return state is TrendsLoaded ? state.report.improvingCount : 0;
});

/// Number of declining trends (with risk).
final decliningTrendCountProvider = Provider<int>((ref) {
  final state = ref.watch(trendNotifierProvider);
  return state is TrendsLoaded ? state.report.decliningCount : 0;
});

/// Filtered trend list.
final filteredTrendsProvider =
    Provider<List<TrendDataEntity>>((ref) {
  final state = ref.watch(trendNotifierProvider);
  return state is TrendsLoaded ? state.filtered : [];
});

// ══════════════════════════════════════════════════════════════════════════════
// DERIVED SELECTORS — COMPARISON
// ══════════════════════════════════════════════════════════════════════════════

/// Overall delta between current and previous period.
final overallComparisonDeltaProvider = Provider<double?>((ref) {
  final state = ref.watch(comparisonNotifierProvider);
  return state is ComparisonLoaded ? state.data.overallDelta : null;
});

/// Number of improved metrics in comparison.
final improvementsCountProvider = Provider<int>((ref) {
  final state = ref.watch(comparisonNotifierProvider);
  return state is ComparisonLoaded ? state.data.improvementsCount : 0;
});

// ══════════════════════════════════════════════════════════════════════════════
// DERIVED SELECTORS — ACHIEVEMENTS
// ══════════════════════════════════════════════════════════════════════════════

/// Current activity streak.
final activityStreakProvider = Provider<int>((ref) {
  final state = ref.watch(achievementsNotifierProvider);
  return state is AchievementsLoaded
      ? state.statistics.currentActivityStreak
      : 0;
});

/// Overall goal completion rate (0.0–1.0).
final overallGoalRateProvider = Provider<double>((ref) {
  final state = ref.watch(achievementsNotifierProvider);
  return state is AchievementsLoaded
      ? state.statistics.overallGoalCompletionRate
      : 0.0;
});

/// Filtered achievements list.
final filteredAchievementsProvider =
    Provider<List<AchievementEntry>>((ref) {
  final state = ref.watch(achievementsNotifierProvider);
  return state is AchievementsLoaded ? state.filteredAchievements : [];
});

/// Personal records list.
final personalRecordsProvider =
    Provider<List<PersonalRecord>>((ref) {
  final state = ref.watch(achievementsNotifierProvider);
  return state is AchievementsLoaded ? state.personalRecords : [];
});

