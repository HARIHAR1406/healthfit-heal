import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../providers/fitness_providers.dart';
import '../widgets/fitness_chart_widgets.dart';
import '../widgets/fitness_history_widgets.dart';

/// Fitness analytics dashboard with fl_chart visuals.
class FitnessAnalyticsPage extends ConsumerWidget {
  const FitnessAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(fitnessStatsProvider);
    final period = ref.watch(analyticsPeriodProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Analytics',
          style: AppTypography.titleLarge.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // Period toggle
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: SegmentedButton<AnalyticsPeriod>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                backgroundColor:
                    isDark ? AppColors.cardDark : AppColors.cardLight,
                selectedBackgroundColor: AppColors.primary,
                selectedForegroundColor: AppColors.white,
                side: BorderSide(
                    color: isDark
                        ? AppColors.dividerDark
                        : AppColors.dividerLight),
              ),
              segments: const [
                ButtonSegment(value: AnalyticsPeriod.week, label: Text('Week')),
                ButtonSegment(value: AnalyticsPeriod.month, label: Text('Month')),
              ],
              selected: {period},
              onSelectionChanged: (s) => ref
                  .read(analyticsPeriodProvider.notifier)
                  .state = s.first,
            ),
          ),
        ],
      ),
      body: stats == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // ── All-Time Stats ────────────────────────────────────────────
                Text(
                  'All-Time Records',
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 1.55,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    FitnessStatTile(
                      label: 'Total Workouts',
                      value: '${stats.totalWorkouts}',
                      unit: 'sessions',
                      icon: Icons.fitness_center_rounded,
                      color: AppColors.primary,
                    ),
                    FitnessStatTile(
                      label: 'Total Calories',
                      value: '${(stats.totalCalories / 1000).toStringAsFixed(1)}k',
                      unit: 'kcal',
                      icon: Icons.local_fire_department_rounded,
                      color: AppColors.chartCoral,
                    ),
                    FitnessStatTile(
                      label: 'Total Time',
                      value:
                          '${(stats.totalMinutes / 60).toStringAsFixed(0)}h',
                      unit: '${stats.totalMinutes % 60}min',
                      icon: Icons.timer_rounded,
                      color: AppColors.tertiary,
                    ),
                    FitnessStatTile(
                      label: 'Best Streak',
                      value: '${stats.longestStreak}',
                      unit: 'days',
                      icon: Icons.local_fire_department_rounded,
                      color: AppColors.chartAmber,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Weekly Frequency ──────────────────────────────────────────
                FitnessChartCard(
                  title: 'Workout Frequency',
                  subtitle: 'Days worked out this week',
                  chart: WeeklyFrequencyChart(
                    values: stats.weeklyFrequencyData,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Calories Trend ────────────────────────────────────────────
                FitnessChartCard(
                  title: period == AnalyticsPeriod.week
                      ? 'Weekly Calories Burned'
                      : 'Monthly Calories Burned',
                  subtitle: 'kcal burned per session',
                  chart: CaloriesTrendChart(
                    values: period == AnalyticsPeriod.week
                        ? stats.weeklyCaloriesData
                        : stats.monthlyCaloriesData,
                    color: AppColors.chartCoral,
                  ),
                  height: period == AnalyticsPeriod.month ? 220 : 190,
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Active Minutes ────────────────────────────────────────────
                FitnessChartCard(
                  title: 'Active Minutes',
                  subtitle: 'Minutes per workout this week',
                  chart: ActiveMinutesChart(
                    values: stats.weeklyMinutesData,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
    );
  }
}
