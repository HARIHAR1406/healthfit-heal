import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/achievement_statistics_entity.dart';
import '../../domain/entities/trend_data_entity.dart';
import '../providers/analytics_notifier.dart';
import '../providers/analytics_providers.dart';
import '../providers/analytics_state.dart';
import '../providers/reports_providers.dart';
import '../widgets/analytics_widgets.dart';
import '../widgets/health_score_ring.dart';

// ══════════════════════════════════════════════════════════════════════════════
// ACHIEVEMENTS PAGE
// ══════════════════════════════════════════════════════════════════════════════

/// Achievement timeline, goal completion stats, personal records, and streaks.
class AchievementsPage extends ConsumerStatefulWidget {
  const AchievementsPage({super.key});

  @override
  ConsumerState<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends ConsumerState<AchievementsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _load() {
    final filter = ref.read(analyticsFilterProvider);
    ref.read(achievementsNotifierProvider.notifier).load(filter);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(achievementsNotifierProvider);
    final streak = ref.watch(activityStreakProvider);
    final goalRate = ref.watch(overallGoalRateProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            leading: const BackButton(),
            flexibleSpace: FlexibleSpaceBar(
              background: _AchievementsHeroHeader(
                streak: streak,
                goalRate: goalRate,
                isDark: isDark,
                state: state,
              ),
            ),
            bottom: TabBar(
              controller: _tabs,
              tabs: const [
                Tab(text: 'Achievements'),
                Tab(text: 'Goals'),
                Tab(text: 'Records'),
              ],
              indicatorColor: AppColors.primary,
              labelStyle:
                  AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700),
              unselectedLabelStyle: AppTypography.bodySmall,
              dividerColor: Colors.transparent,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _AchievementsTab(state: state, isDark: isDark),
            _GoalsTab(state: state, isDark: isDark),
            _RecordsTab(state: state, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

// ── Hero Header ─────────────────────────────────────────────────────────────

class _AchievementsHeroHeader extends StatelessWidget {
  const _AchievementsHeroHeader({
    required this.streak,
    required this.goalRate,
    required this.isDark,
    required this.state,
  });
  final int streak;
  final double goalRate;
  final bool isDark;
  final AchievementsState state;

  @override
  Widget build(BuildContext context) {
    final loaded = state is AchievementsLoaded ? state as AchievementsLoaded : null;
    final pts = loaded?.statistics.totalPoints ?? 0;
    final level = loaded?.statistics.currentLevel ?? 1;
    final progress = loaded?.statistics.progressToNextLevel ?? 0.0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A2A4A), Color(0xFF0A1628)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, 72, AppSpacing.xl, AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Achievements',
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Level $level  ·  $pts pts',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Level progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress.clamp(0, 1)),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => LinearProgressIndicator(
                          value: v,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation(
                              AppColors.warning),
                          minHeight: 7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${(progress * 100).round()}% to Level ${level + 1}',
                      style: AppTypography.captionText.copyWith(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _HeaderPill(
                        emoji: '🔥', value: '$streak', label: 'day streak'),
                    const SizedBox(width: AppSpacing.sm),
                    _HeaderPill(
                        emoji: '🎯',
                        value: '${(goalRate * 100).round()}%',
                        label: 'goal rate'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          // Points ring
          HealthScoreRing(
            score: progress * 100,
            isDark: true,
            size: 90,
            strokeWidth: 10,
            healthScore: goalRate * 100,
            fitnessScore: streak.toDouble().clamp(0, 100),
            nutritionScore: (loaded?.statistics.totalAchievements ?? 0)
                .clamp(0, 100)
                .toDouble(),
          ),
        ],
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill(
      {required this.emoji, required this.value, required this.label});
  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji),
          const SizedBox(width: 4),
          Text(
            '$value $label',
            style: AppTypography.captionText.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Achievements Tab ──────────────────────────────────────────────────────

class _AchievementsTab extends StatelessWidget {
  const _AchievementsTab({required this.state, required this.isDark});
  final AchievementsState state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (state is AchievementsLoading || state is AchievementsInitial) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (state is AchievementsError) {
      return Center(child: Text((state as AchievementsError).message));
    }
    final loaded = state as AchievementsLoaded;

    return CustomScrollView(
      slivers: [
        // New achievements
        if (loaded.statistics.newOnes.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
              child: Text(
                '✨ New Achievements',
                style: AppTypography.titleSmall.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverGrid.count(
              crossAxisCount: 3,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.75,
              children: loaded.statistics.newOnes
                  .map((a) => AchievementCard(
                      achievement: a, isDark: isDark))
                  .toList(),
            ),
          ),
        ],

        // All achievements
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.xl, AppSpacing.md, AppSpacing.xs),
            child: Text(
              'All Achievements (${loaded.statistics.totalAchievements})',
              style: AppTypography.titleSmall.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverGrid.count(
            crossAxisCount: 3,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.75,
            children: loaded.statistics.achievements
                .map((a) =>
                    AchievementCard(achievement: a, isDark: isDark))
                .toList(),
          ),
        ),
        const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.massive)),
      ],
    );
  }
}

// ── Goals Tab ──────────────────────────────────────────────────────────────

class _GoalsTab extends StatelessWidget {
  const _GoalsTab({required this.state, required this.isDark});
  final AchievementsState state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (state is! AchievementsLoaded) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    final loaded = state as AchievementsLoaded;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Overall rate
        _OverallGoalRateCard(
          rate: loaded.statistics.overallGoalCompletionRate,
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.md),

        // Individual goals
        ...loaded.statistics.goalStats
            .map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: GoalStatsCard(goal: g, isDark: isDark),
                )),

        // Streak summary
        const SizedBox(height: AppSpacing.md),
        _StreakSummaryCard(
          activityCurrent: loaded.statistics.currentActivityStreak,
          activityBest: loaded.statistics.longestActivityStreak,
          medCurrent: loaded.statistics.currentMedicationStreak,
          medBest: loaded.statistics.longestMedicationStreak,
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.massive),
      ],
    );
  }
}

class _OverallGoalRateCard extends StatelessWidget {
  const _OverallGoalRateCard({required this.rate, required this.isDark});
  final double rate;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final pct = (rate * 100).round();
    final color = rate >= 0.8
        ? AppColors.secondary
        : rate >= 0.6
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Goal Rate',
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pct >= 80
                      ? 'Excellent — keep it up! 🔥'
                      : pct >= 60
                          ? 'Good progress — push harder!'
                          : 'Room to improve — stay consistent!',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: rate.clamp(0, 1)),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: v,
                      backgroundColor:
                          isDark ? Colors.white12 : Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: rate * 100),
            duration: const Duration(milliseconds: 1000),
            builder: (_, v, __) => Text(
              '${v.round()}%',
              style: AppTypography.displaySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakSummaryCard extends StatelessWidget {
  const _StreakSummaryCard({
    required this.activityCurrent,
    required this.activityBest,
    required this.medCurrent,
    required this.medBest,
    required this.isDark,
  });
  final int activityCurrent;
  final int activityBest;
  final int medCurrent;
  final int medBest;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔥 Streaks',
            style: AppTypography.titleSmall.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _StreakRow(
            label: '🏋️ Activity',
            current: activityCurrent,
            best: activityBest,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.xs),
          _StreakRow(
            label: '💊 Medication',
            current: medCurrent,
            best: medBest,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _StreakRow extends StatelessWidget {
  const _StreakRow({
    required this.label,
    required this.current,
    required this.best,
    required this.isDark,
  });
  final String label;
  final int current;
  final int best;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const Spacer(),
        Text(
          '$current days',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.warning,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          '  (best: $best)',
          style: AppTypography.captionText.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

// ── Records Tab ────────────────────────────────────────────────────────────

class _RecordsTab extends StatelessWidget {
  const _RecordsTab({required this.state, required this.isDark});
  final AchievementsState state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (state is! AchievementsLoaded) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    final loaded = state as AchievementsLoaded;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.grey.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: loaded.personalRecords.asMap().entries.map((e) {
              final rec = e.value;
              final isLast = e.key == loaded.personalRecords.length - 1;
              return Column(
                children: [
                  ListTile(
                    leading: Text(
                      rec.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      rec.label,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${rec.achievedAt.day}/${rec.achievedAt.month}/${rec.achievedAt.year}',
                      style: AppTypography.captionText.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    trailing: Text(
                      '${rec.value.toStringAsFixed(rec.value % 1 == 0 ? 0 : 1)} ${rec.unit}',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 72,
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.grey.withOpacity(0.08),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.massive),
      ],
    );
  }
}
