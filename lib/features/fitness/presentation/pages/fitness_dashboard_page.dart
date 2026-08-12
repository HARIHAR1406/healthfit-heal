import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../providers/fitness_providers.dart';
import '../providers/fitness_state.dart';
import '../widgets/fitness_history_widgets.dart';
import '../widgets/fitness_widgets.dart';
import '../widgets/workout_card.dart';
import '../widgets/adaptive_workout_card.dart';

/// Fitness Module landing page — daily activity + quick actions + library preview.
class FitnessDashboardPage extends ConsumerStatefulWidget {
  const FitnessDashboardPage({super.key});

  @override
  ConsumerState<FitnessDashboardPage> createState() =>
      _FitnessDashboardPageState();
}

class _FitnessDashboardPageState
    extends ConsumerState<FitnessDashboardPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fitnessNotifierProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(fitnessNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      body: switch (state) {
        FitnessLoading() || FitnessInitial() =>
          const AppLoadingIndicator(size: 52),
        FitnessError(:final message) => AppErrorWidget(
            message: message,
            onRetry: () =>
                ref.read(fitnessNotifierProvider.notifier).refresh(),
          ),
        _ => _Body(
            isDark: isDark,
            onRefresh: () =>
                ref.read(fitnessNotifierProvider.notifier).refresh(),
          ),
      },
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends ConsumerWidget {
  const _Body({required this.isDark, required this.onRefresh});
  final bool isDark;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(fitnessLoadedDataProvider);
    if (data == null) return const AppLoadingIndicator(size: 52);

    final isRefreshing =
        ref.watch(fitnessNotifierProvider) is FitnessRefreshing;
    final stats = data.stats;
    final activity = data.todayActivity;
    final workouts = data.workouts;
    final history = data.history;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // ── App Bar ────────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
            floating: true,
            snap: true,
            elevation: 0,
            title: Text(
              'Fitness',
              style: AppTypography.titleLarge.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.analytics_outlined,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                tooltip: 'Analytics',
                onPressed: () => context.push(RouteNames.fitnessAnalytics),
              ),
              IconButton(
                icon: Icon(
                  Icons.history_rounded,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                tooltip: 'Workout History',
                onPressed: () => context.push(RouteNames.workoutHistory),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
          ),

          SliverPadding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (isRefreshing) _RefreshBanner(),

                // ── Today's Activity Hero ──────────────────────────────────────
                TodayActivityCard(activity: activity),
                const SizedBox(height: AppSpacing.lg),

                // ── Streak ────────────────────────────────────────────────────
                WorkoutStreakCard(
                  current: stats.currentStreak,
                  longest: stats.longestStreak,
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Weekly Stats ──────────────────────────────────────────────
                _SectionTitle(title: 'This Week', isDark: isDark),
                const SizedBox(height: AppSpacing.sm),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 1.6,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    FitnessStatTile(
                      label: 'Workouts',
                      value: '${stats.weeklyWorkouts}',
                      unit: 'sessions',
                      icon: Icons.fitness_center_rounded,
                      color: AppColors.primary,
                    ),
                    FitnessStatTile(
                      label: 'Calories',
                      value: '${stats.weeklyCalories}',
                      unit: 'kcal',
                      icon: Icons.local_fire_department_rounded,
                      color: AppColors.chartCoral,
                    ),
                    FitnessStatTile(
                      label: 'Active Time',
                      value: '${stats.weeklyMinutes}',
                      unit: 'min',
                      icon: Icons.bolt_rounded,
                      color: AppColors.tertiary,
                    ),
                    FitnessStatTile(
                      label: 'Distance',
                      value: stats.weeklyDistance.toStringAsFixed(1),
                      unit: 'km',
                      icon: Icons.directions_run_rounded,
                      color: AppColors.chartSky,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Quick Workout Actions ─────────────────────────────────────
                _SectionTitle(title: 'Quick Start', isDark: isDark),
                const SizedBox(height: AppSpacing.sm),
                _QuickStartRow(isDark: isDark),
                const SizedBox(height: AppSpacing.lg),

                // ── Workout Library Preview ───────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _SectionTitle(
                          title: 'Workout Library', isDark: isDark),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.push(RouteNames.workoutLibrary),
                      child: Text(
                        'See All',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ...workouts.take(3).map(
                      (w) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: WorkoutCard(
                          workout: w,
                          detailRoute: RouteNames.workoutDetail,
                          onFavouriteTap: () => ref
                              .read(workoutLibraryProvider.notifier)
                              .toggleFavourite(w.id),
                        ),
                      ),
                    ),
                const SizedBox(height: AppSpacing.lg),

                // ── Recent History ────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _SectionTitle(
                          title: 'Recent Activity', isDark: isDark),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.push(RouteNames.workoutHistory),
                      child: Text(
                        'See All',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ...history.take(3).map(
                      (h) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: WorkoutHistoryTile(entry: h),
                      ),
                    ),

                const SizedBox(height: AppSpacing.xxxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Start Row ───────────────────────────────────────────────────────────

class _QuickStartRow extends StatelessWidget {
  const _QuickStartRow({required this.isDark});
  final bool isDark;

  static const _quickActions = [
    _QuickAction(icon: Icons.fitness_center_rounded, label: 'Strength',
        color: Color(0xFF6C63FF), category: 'strength'),
    _QuickAction(icon: Icons.directions_run_rounded, label: 'Run',
        color: Color(0xFF00C896), category: 'running'),
    _QuickAction(icon: Icons.self_improvement_rounded, label: 'Yoga',
        color: Color(0xFFFFBF00), category: 'yoga'),
    _QuickAction(icon: Icons.electric_bolt_rounded, label: 'HIIT',
        color: Color(0xFFFF6B6B), category: 'hiit'),
    _QuickAction(icon: Icons.pedal_bike_rounded, label: 'Cycle',
        color: Color(0xFF00B4D8), category: 'cycling'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _quickActions.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final action = _quickActions[i];
          return _QuickTile(
            action: action,
            isDark: isDark,
            onTap: () => context.push(
              '${RouteNames.workoutLibrary}?category=${action.category}',
            ),
          );
        },
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.category});
  final IconData icon;
  final String label;
  final Color color;
  final String category;
}

class _QuickTile extends StatelessWidget {
  const _QuickTile(
      {required this.action, required this.isDark, required this.onTap});
  final _QuickAction action;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${action.label} workouts',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 76,
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
          decoration: BoxDecoration(
            color: action.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
                color: action.color.withOpacity(0.25)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, color: action.color, size: 28),
              const SizedBox(height: 5),
              Text(
                action.label,
                style: AppTypography.overline.copyWith(
                  color: action.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.isDark});
  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.titleMedium.copyWith(
        color:
            isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _RefreshBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Refreshing…',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

