import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../providers/dashboard_notifier.dart';
import '../providers/dashboard_providers.dart';
import '../providers/dashboard_state.dart';
import '../widgets/activity_item_widget.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/health_metric_card.dart';
import '../widgets/hero_banner.dart';
import '../widgets/progress_item_widget.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/section_header.dart';

/// Home Dashboard page — the primary screen of the HealthFit Heal app.
///
/// Architecture:
///   - Reads [dashboardNotifierProvider] for state management
///   - Triggers initial load in [initState]
///   - Pull-to-refresh via [RefreshIndicator]
///   - Segmented into widget sub-components for optimized rebuilds
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Preserve scroll position across tab switches

  @override
  void initState() {
    super.initState();
    // Trigger the first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardNotifierProvider.notifier).load();
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(dashboardNotifierProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(dashboardNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      body: switch (state) {
        DashboardLoading() => _LoadingView(),
        DashboardError(:final message) => _ErrorView(
            message: message,
            onRetry: () =>
                ref.read(dashboardNotifierProvider.notifier).load(),
          ),
        DashboardLoaded() || DashboardRefreshing() => _DashboardContent(
            isRefreshing: state is DashboardRefreshing,
            onRefresh: _onRefresh,
          ),
        DashboardInitial() => _LoadingView(),
      },
    );
  }
}

// ── Loading View ──────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        DashboardHeader(),
        Expanded(
          child: AppLoadingIndicator(size: 48),
        ),
      ],
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const DashboardHeader(),
        Expanded(
          child: AppErrorWidget(
            message: message,
            onRetry: onRetry,
            retryLabel: 'Retry',
          ),
        ),
      ],
    );
  }
}

// ── Dashboard Content ─────────────────────────────────────────────────────────

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({
    required this.isRefreshing,
    required this.onRefresh,
  });

  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final metrics = ref.watch(dashboardMetricsProvider);
    final quickActions = ref.watch(dashboardQuickActionsProvider);
    final progress = ref.watch(dashboardProgressProvider);
    final activities = ref.watch(dashboardActivitiesProvider);

    return Column(
      children: [
        // ── Sticky Header ────────────────────────────────────────────────────
        const DashboardHeader(),

        // ── Refreshable Body ─────────────────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            color: AppColors.primary,
            backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // Refresh indicator overlay
                if (isRefreshing)
                  const SliverToBoxAdapter(
                    child: _RefreshBanner(),
                  ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Hero Banner ─────────────────────────────────────────
                      const HeroBanner(),

                      // ── Health Overview ─────────────────────────────────────
                      SectionHeader(
                        title: 'Health Overview',
                        actionLabel: 'See All',
                        onAction: () =>
                            context.go(RouteNames.healthDashboard),
                      ),
                      HealthOverviewSection(metrics: metrics),

                      // ── Quick Actions ───────────────────────────────────────
                      const SectionHeader(title: 'Quick Actions'),
                      QuickActionsSection(actions: quickActions),

                      // ── Today's Progress ────────────────────────────────────
                      const SectionHeader(title: "Today's Progress"),
                      TodayProgressSection(items: progress),

                      // ── Recent Activity ─────────────────────────────────────
                      SectionHeader(
                        title: 'Recent Activity',
                        actionLabel: 'View All',
                        onAction: () => context.go(RouteNames.healthDashboard),
                      ),
                      RecentActivitySection(activities: activities),

                      // ── Bottom Spacer (above nav bar) ───────────────────────
                      const SizedBox(height: AppSpacing.xxxl),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Refresh Banner ────────────────────────────────────────────────────────────

class _RefreshBanner extends StatelessWidget {
  const _RefreshBanner();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      color: AppColors.primary.withOpacity(0.08),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Refreshing…',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

