import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/meal_entity.dart';
import '../providers/nutrition_providers.dart';
import '../providers/nutrition_state.dart';
import '../widgets/food_meal_widgets.dart';
import '../widgets/nutrition_widgets.dart';

/// Nutrition Module root page — daily summary + meals overview.
class NutritionDashboardPage extends ConsumerStatefulWidget {
  const NutritionDashboardPage({super.key});

  @override
  ConsumerState<NutritionDashboardPage> createState() =>
      _NutritionDashboardPageState();
}

class _NutritionDashboardPageState
    extends ConsumerState<NutritionDashboardPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nutritionNotifierProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(nutritionNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      body: switch (state) {
        NutritionLoading() || NutritionInitial() =>
          const AppLoadingIndicator(size: 52),
        NutritionError(:final message) => AppErrorWidget(
            message: message,
            onRetry: () =>
                ref.read(nutritionNotifierProvider.notifier).refresh(),
          ),
        _ => _Body(isDark: isDark),
      },
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends ConsumerWidget {
  const _Body({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(nutritionLoadedProvider);
    if (data == null) return const AppLoadingIndicator(size: 52);

    final daily = data.daily;
    final goals = daily.goals;
    final isRefreshing = ref.watch(nutritionNotifierProvider) is NutritionRefreshing;

    return RefreshIndicator(
      onRefresh: () => ref.read(nutritionNotifierProvider.notifier).refresh(),
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // ── App Bar ─────────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
            floating: true,
            snap: true,
            elevation: 0,
            title: Text(
              'Nutrition',
              style: AppTypography.titleLarge.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              // ── Phase 13: AI Food Vision scan entry ──────────────────────
              IconButton(
                icon: Icon(Icons.camera_enhance_rounded,
                    color: AppColors.primary),
                tooltip: 'Scan Food',
                onPressed: () => context.push(RouteNames.foodScanner),
              ),
              IconButton(
                icon: Icon(Icons.analytics_outlined,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
                tooltip: 'Analytics',
                onPressed: () =>
                    context.push(RouteNames.nutritionAnalytics),
              ),
              IconButton(
                icon: Icon(Icons.monitor_weight_outlined,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
                tooltip: 'Weight Tracker',
                onPressed: () =>
                    context.push(RouteNames.weightTracker),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (isRefreshing)
                  _RefreshBanner(),

                // ── Calorie Hero ───────────────────────────────────────────────
                _CalorieHeroCard(daily: daily, goals: goals, isDark: isDark),
                const SizedBox(height: AppSpacing.md),

                // ── Macro Summary ──────────────────────────────────────────────
                MacroSummaryCard(
                  proteinG: daily.totalProteinG,
                  proteinGoalG: goals.proteinGoalG,
                  carbsG: daily.totalCarbsG,
                  carbsGoalG: goals.carbsGoalG,
                  fatG: daily.totalFatG,
                  fatGoalG: goals.fatGoalG,
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Water + Score Row ─────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            context.push(RouteNames.waterTracker),
                        child: _WaterCard(
                          waterMl: daily.waterMl,
                          goalMl: daily.waterGoalMl,
                          isDark: isDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _ScoreCard(
                          score: daily.nutritionScore, isDark: isDark),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Micro Goals ────────────────────────────────────────────────
                _SectionTitle(title: 'Micro Goals', isDark: isDark),
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
                      label: 'Fiber',
                      current: 0,
                      goal: goals.fiberGoalG,
                      unit: 'g',
                      icon: Icons.grass_rounded,
                      color: AppColors.success,
                    ),
                    GoalCard(
                      label: 'Sodium',
                      current: 0,
                      goal: goals.sodiumGoalMg,
                      unit: 'mg',
                      icon: Icons.scatter_plot_rounded,
                      color: AppColors.chartAmber,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Quick Actions ──────────────────────────────────────────────
                _SectionTitle(title: 'Quick Actions', isDark: isDark),
                const SizedBox(height: AppSpacing.sm),
                _QuickActionsRow(isDark: isDark),
                const SizedBox(height: AppSpacing.lg),

                // ── Today's Meals Summary ──────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _SectionTitle(
                          title: "Today's Meals", isDark: isDark),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.push(RouteNames.mealPlanner),
                      child: Text(
                        'View Plan',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ...daily.meals.map(
                  (m) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: MealCalorieRow(
                      mealType: m.type,
                      calories: m.totalCalories,
                      goalCalories: goals.caloriesGoal / daily.meals.length,
                    ),
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

// ── Calorie Hero Card ─────────────────────────────────────────────────────────

class _CalorieHeroCard extends StatelessWidget {
  const _CalorieHeroCard({
    required this.daily,
    required this.goals,
    required this.isDark,
  });
  final DailyNutritionEntity daily;
  final NutritionGoals goals;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF9800)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        boxShadow: [
          BoxShadow(
            color: AppColors.chartCoral.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ring
          CalorieRingWidget(
            consumed: daily.totalCalories,
            goal: goals.caloriesGoal,
            remaining: daily.caloriesRemaining,
          ),
          const SizedBox(width: AppSpacing.lg),

          // Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✦  Calories',
                  style: AppTypography.overline.copyWith(
                    color: AppColors.white.withOpacity(0.8),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _CalStat(
                  label: 'Goal',
                  value: goals.caloriesGoal.toStringAsFixed(0),
                  isDark: false,
                ),
                _CalStat(
                  label: 'Food',
                  value: daily.totalCalories.toStringAsFixed(0),
                  isDark: false,
                  highlight: true,
                ),
                _CalStat(
                  label: 'Exercise',
                  value: '−0',
                  isDark: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalStat extends StatelessWidget {
  const _CalStat({
    required this.label,
    required this.value,
    required this.isDark,
    this.highlight = false,
  });
  final String label;
  final String value;
  final bool isDark;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.white.withOpacity(0.8),
            ),
          ),
          Text(
            '$value kcal',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.white,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Water + Score Cards ───────────────────────────────────────────────────────

class _WaterCard extends StatelessWidget {
  const _WaterCard({
    required this.waterMl,
    required this.goalMl,
    required this.isDark,
  });
  final int waterMl;
  final int goalMl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        border: Border.all(
          color: AppColors.chartSky.withOpacity(0.3),
          width: AppSpacing.borderThin,
        ),
      ),
      child: Column(
        children: [
          WaterProgressWidget(currentMl: waterMl, goalMl: goalMl, size: 90),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Water',
            style: AppTypography.labelSmall.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score, required this.isDark});
  final int score;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: AppSpacing.borderThin,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          NutritionScoreBadge(score: score),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Improve by adding\nmore variety',
            textAlign: TextAlign.center,
            style: AppTypography.captionText.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Actions ─────────────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QAction(
        icon: Icons.search_rounded,
        label: 'Find Food',
        color: AppColors.primary,
        route: RouteNames.foodDatabase,
      ),
      _QAction(
        icon: Icons.restaurant_menu_rounded,
        label: 'Meal Plan',
        color: AppColors.chartIndigo,
        route: RouteNames.mealPlanner,
      ),
      _QAction(
        icon: Icons.water_drop_rounded,
        label: 'Water',
        color: AppColors.chartSky,
        route: RouteNames.waterTracker,
      ),
      _QAction(
        icon: Icons.monitor_weight_rounded,
        label: 'Weight',
        color: AppColors.tertiary,
        route: RouteNames.weightTracker,
      ),
    ];

    return Row(
      children: actions
          .map(
            (a) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _QuickActionTile(action: a, isDark: isDark),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _QAction {
  const _QAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });
  final IconData icon;
  final String label;
  final Color color;
  final String route;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action, required this.isDark});
  final _QAction action;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(action.route),
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          color: action.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
              color: action.color.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(action.icon, color: action.color, size: 26),
            const SizedBox(height: 4),
            Text(
              action.label,
              textAlign: TextAlign.center,
              style: AppTypography.overline.copyWith(
                color: action.color,
                fontWeight: FontWeight.w700,
                fontSize: 9,
              ),
            ),
          ],
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
