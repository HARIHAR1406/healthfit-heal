import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/dashboard_mock_repository.dart';
import '../../domain/entities/activity_item_entity.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../domain/entities/health_metric_entity.dart';
import '../../domain/entities/progress_item_entity.dart';
import '../../domain/entities/quick_action_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';
import 'dashboard_notifier.dart';
import 'dashboard_state.dart';

// ── Repository ────────────────────────────────────────────────────────────────

/// Provides the dashboard repository implementation.
///
/// Swap [DashboardMockRepository] with [DashboardRepositoryImpl] when the
/// backend API is ready.
final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardMockRepository(),
  name: 'dashboardRepositoryProvider',
);

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Primary dashboard state provider.
///
/// Watch this in [HomePage] to drive the entire dashboard.
final dashboardNotifierProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>(
  (ref) => DashboardNotifier(
    repository: ref.watch(dashboardRepositoryProvider),
  ),
  name: 'dashboardNotifierProvider',
);

// ── Convenience Selectors ─────────────────────────────────────────────────────

/// Returns the loaded [DashboardEntity] or null.
final dashboardDataProvider = Provider<DashboardEntity?>(
  (ref) => ref.watch(dashboardNotifierProvider).data,
  name: 'dashboardDataProvider',
);

/// Health metric cards list.
final dashboardMetricsProvider = Provider<List<HealthMetricEntity>>(
  (ref) => ref.watch(dashboardDataProvider)?.metrics ?? [],
  name: 'dashboardMetricsProvider',
);

/// Quick actions list.
final dashboardQuickActionsProvider = Provider<List<QuickActionEntity>>(
  (ref) => ref.watch(dashboardDataProvider)?.quickActions ?? [],
  name: 'dashboardQuickActionsProvider',
);

/// Today's progress rings list.
final dashboardProgressProvider = Provider<List<ProgressItemEntity>>(
  (ref) => ref.watch(dashboardDataProvider)?.todayProgress ?? [],
  name: 'dashboardProgressProvider',
);

/// Recent activity feed.
final dashboardActivitiesProvider = Provider<List<ActivityItemEntity>>(
  (ref) => ref.watch(dashboardDataProvider)?.recentActivities ?? [],
  name: 'dashboardActivitiesProvider',
);

/// Notification badge count.
final notificationCountProvider = Provider<int>(
  (ref) => ref.watch(dashboardDataProvider)?.notificationCount ?? 0,
  name: 'notificationCountProvider',
);

/// Wellness score (0–100).
final wellnessScoreProvider = Provider<int>(
  (ref) => ref.watch(dashboardDataProvider)?.wellnessScore ?? 0,
  name: 'wellnessScoreProvider',
);
