import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../providers/nutrition_providers.dart';
import '../providers/nutrition_state.dart';
import '../widgets/nutrition_chart_widgets.dart';
import '../widgets/nutrition_widgets.dart';
import '../widgets/food_meal_widgets.dart';

/// Nutrition analytics with 5 fl_chart visualisations.
class NutritionAnalyticsPage extends ConsumerWidget {
  const NutritionAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(nutritionLoadedProvider);
    final period = ref.watch(nutritionPeriodProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Nutrition Analytics',
          style: AppTypography.titleLarge.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: SegmentedButton<NutritionPeriod>(
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
                ButtonSegment(
                    value: NutritionPeriod.week, label: Text('Week')),
                ButtonSegment(
                    value: NutritionPeriod.month, label: Text('Month')),
              ],
              selected: {period},
              onSelectionChanged: (s) =>
                  ref.read(nutritionPeriodProvider.notifier).state = s.first,
            ),
          ),
        ],
      ),
      body: data == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _AnalyticsBody(data: data, period: period, isDark: isDark),
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  const _AnalyticsBody({
    required this.data,
    required this.period,
    required this.isDark,
  });
  final NutritionLoaded data;
  final NutritionPeriod period;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final analytics = data.analytics;
    final daily = data.daily;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // ── Weekly Summary Stats ───────────────────────────────────────────────
        Text(
          'This Week',
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
          childAspectRatio: 1.7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            GoalCard(
              label: 'Avg. Calories',
              current: analytics.weeklyCalories
                      .fold(0.0, (s, v) => s + v) /
                  analytics.weeklyCalories.length,
              goal: analytics.caloriesGoal,
              unit: 'kcal',
              icon: Icons.local_fire_department_rounded,
              color: AppColors.chartCoral,
            ),
            GoalCard(
              label: 'Avg. Protein',
              current:
                  analytics.weeklyProtein.fold(0.0, (s, v) => s + v) /
                      analytics.weeklyProtein.length,
              goal: daily.goals.proteinGoalG,
              unit: 'g',
              icon: Icons.fitness_center_rounded,
              color: AppColors.chartIndigo,
            ),
            GoalCard(
              label: 'Avg. Water',
              current: analytics.weeklyWaterMl
                      .fold(0.0, (s, v) => s + v) /
                  analytics.weeklyWaterMl.length /
                  1000,
              goal: daily.goals.waterGoalMl / 1000.0,
              unit: 'L',
              icon: Icons.water_drop_rounded,
              color: AppColors.chartSky,
            ),
            GoalCard(
              label: 'Avg. Score',
              current:
                  analytics.weeklyScores.fold(0, (s, v) => s + v) /
                      analytics.weeklyScores.length,
              goal: 100,
              unit: '/100',
              icon: Icons.star_rounded,
              color: AppColors.chartAmber,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Calories Chart ────────────────────────────────────────────────────
        NutritionChartCard(
          title: period == NutritionPeriod.week
              ? 'Daily Calories (Week)'
              : 'Daily Calories (Month)',
          subtitle: 'kcal vs. ${analytics.caloriesGoal.toStringAsFixed(0)} kcal goal',
          height: 220,
          child: CaloriesBarChart(
            values: period == NutritionPeriod.week
                ? analytics.weeklyCalories
                : analytics.monthlyCalories,
            goal: analytics.caloriesGoal,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Macro Pie ─────────────────────────────────────────────────────────
        NutritionChartCard(
          title: 'Macronutrient Distribution',
          subtitle: 'Today\'s protein / carbs / fat split',
          height: 180,
          child: MacroPieChart(
            proteinG: daily.totalProteinG,
            carbsG: daily.totalCarbsG,
            fatG: daily.totalFatG,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Water Chart ────────────────────────────────────────────────────────
        NutritionChartCard(
          title: 'Water Intake (Week)',
          subtitle: 'Daily intake vs. 2.5 L goal',
          child: WaterIntakeChart(
            values: analytics.weeklyWaterMl,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Weight Chart ───────────────────────────────────────────────────────
        NutritionChartCard(
          title: 'Weight Progress',
          subtitle: 'Recent measurements vs. goal',
          height: 220,
          child: WeightProgressChart(
            values: data.weightTracker.entries
                .take(10)
                .map<double>((e) => e.weightKg)
                .toList()
                .reversed
                .toList(),
            goalKg: data.weightTracker.goalKg,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Nutrition Score Chart ──────────────────────────────────────────────
        NutritionChartCard(
          title: 'Weekly Nutrition Score',
          subtitle: 'Score 0–100 per day',
          child: NutritionScoreChart(scores: analytics.weeklyScores),
        ),

        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }
}

