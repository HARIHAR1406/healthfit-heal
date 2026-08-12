import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/comparison_data_entity.dart';
import '../providers/analytics_notifier.dart';
import '../providers/analytics_providers.dart';
import '../providers/analytics_state.dart';
import '../widgets/analytics_widgets.dart';
import '../widgets/chart_card.dart';

// ══════════════════════════════════════════════════════════════════════════════
// COMPARE REPORTS PAGE
// ══════════════════════════════════════════════════════════════════════════════

/// Side-by-side comparison of current vs previous health period.
/// Supports week-over-week, month-over-month, year-over-year, and custom.
class CompareReportsPage extends ConsumerStatefulWidget {
  const CompareReportsPage({super.key});

  @override
  ConsumerState<CompareReportsPage> createState() =>
      _CompareReportsPageState();
}

class _CompareReportsPageState extends ConsumerState<CompareReportsPage> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load([ComparisonPeriod? period]) {
    final p = period ?? ref.read(selectedComparisonPeriodProvider);
    ref.read(comparisonNotifierProvider.notifier).load(p);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(comparisonNotifierProvider);
    final selectedPeriod = ref.watch(selectedComparisonPeriodProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ─────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 110,
            floating: true,
            snap: true,
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
            surfaceTintColor: Colors.transparent,
            leading: const BackButton(),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                  left: AppSpacing.xxl, bottom: AppSpacing.md),
              title: Text(
                'Compare Reports',
                style: AppTypography.titleLarge.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          // ── Period Selector ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: _PeriodSelector(
                selected: selectedPeriod,
                isDark: isDark,
                onChanged: (p) {
                  ref.read(selectedComparisonPeriodProvider.notifier).state = p;
                  _load(p);
                },
              ),
            ),
          ),

          if (state is ComparisonLoading || state is ComparisonInitial)
            const SliverFillRemaining(
              child: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (state is ComparisonError)
            SliverFillRemaining(
              child: _ErrorView(message: state.message, onRetry: _load),
            )
          else if (state is ComparisonLoaded) ...[
            // ── Overall Banner ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _OverallBanner(
                  data: state.data,
                  isDark: isDark,
                ),
              ),
            ),

            // ── Scores Grid ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md),
                child: _ScoresComparisonRow(
                  current: state.data.current,
                  previous: state.data.previous,
                  isDark: isDark,
                ),
              ),
            ),

            // ── Metric Comparisons ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.xl, AppSpacing.md,
                    AppSpacing.sm),
                child: _SectionHeader(
                    title: 'Metric-by-Metric', isDark: isDark),
              ),
            ),
            SliverPadding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.1,
                children: state.data.metricComparisons
                    .map((c) =>
                        ComparisonCard(comparison: c, isDark: isDark))
                    .toList(),
              ),
            ),

            // ── Improvements / Regressions Summary ───────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _ImprovementSummaryCard(
                  data: state.data,
                  isDark: isDark,
                ),
              ),
            ),

            const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.massive)),
          ],
        ],
      ),
    );
  }
}

// ── Period Selector ────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });
  final ComparisonPeriod selected;
  final bool isDark;
  final ValueChanged<ComparisonPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ComparisonPeriod.values
            .where((p) => p != ComparisonPeriod.custom)
            .map((p) {
          final active = p == selected;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: ChoiceChip(
              label: Text(p.label),
              selected: active,
              onSelected: (_) => onChanged(p),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: active ? Colors.white : null,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Overall Banner ─────────────────────────────────────────────────────────

class _OverallBanner extends StatelessWidget {
  const _OverallBanner({required this.data, required this.isDark});
  final ComparisonDataEntity data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final better = data.currentIsBetter;
    final delta = data.overallDelta;
    final deltaColor = better ? AppColors.secondary : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: better
              ? [const Color(0xFF00C896), const Color(0xFF00A87A)]
              : [const Color(0xFFFF6B6B), const Color(0xFFFF3D00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        boxShadow: [
          BoxShadow(
            color:
                (better ? AppColors.secondary : AppColors.error)
                    .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            better ? '🎉 You\'re Improving!' : '📉 Needs Attention',
            style: AppTypography.titleSmall.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}',
                style: AppTypography.displayMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  ' pts overall',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${data.current.label} vs ${data.previous.label}  ·  Winner: ${data.winnerLabel}',
            style: AppTypography.captionText.copyWith(
              color: Colors.white.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _BannerStat2(
                value: data.improvementsCount.toString(),
                label: 'Improvements',
                emoji: '✅',
              ),
              _BannerStat2(
                value: data.regressionsCount.toString(),
                label: 'Regressions',
                emoji: '⬇️',
              ),
              _BannerStat2(
                value:
                    '${data.current.overallScore.toStringAsFixed(0)}pts',
                label: 'Current Score',
                emoji: '📊',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerStat2 extends StatelessWidget {
  const _BannerStat2(
      {required this.value, required this.label, required this.emoji});
  final String value;
  final String label;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTypography.titleSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            )),
        Text(label,
            style: AppTypography.captionText.copyWith(
              color: Colors.white.withOpacity(0.65),
              fontSize: 10,
            )),
      ],
    );
  }
}

// ── Scores Comparison Row ──────────────────────────────────────────────────

class _ScoresComparisonRow extends StatelessWidget {
  const _ScoresComparisonRow({
    required this.current,
    required this.previous,
    required this.isDark,
  });
  final PeriodStats current;
  final PeriodStats previous;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ScoreBlock(
            label: '❤️ Health',
            current: current.healthScore,
            previous: previous.healthScore,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ScoreBlock(
            label: '🏋️ Fitness',
            current: current.fitnessScore,
            previous: previous.fitnessScore,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ScoreBlock(
            label: '🥗 Nutrition',
            current: current.nutritionScore,
            previous: previous.nutritionScore,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _ScoreBlock extends StatelessWidget {
  const _ScoreBlock({
    required this.label,
    required this.current,
    required this.previous,
    required this.isDark,
  });
  final String label;
  final double current;
  final double previous;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final improved = current >= previous;
    final color = improved ? AppColors.secondary : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color:
              color.withOpacity(0.25),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTypography.captionText.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            current.toStringAsFixed(0),
            style: AppTypography.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'prev: ${previous.toStringAsFixed(0)}',
            style: AppTypography.captionText.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Icon(
            improved ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 14,
            color: color,
          ),
        ],
      ),
    );
  }
}

// ── Improvement Summary Card ───────────────────────────────────────────────

class _ImprovementSummaryCard extends StatelessWidget {
  const _ImprovementSummaryCard({
    required this.data,
    required this.isDark,
  });
  final ComparisonDataEntity data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ChartCard(
      title: 'What Changed?',
      subtitle: '${data.current.label} vs ${data.previous.label}',
      isDark: isDark,
      height: 200,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: data.metricComparisons.map((c) {
            final color =
                c.improved ? AppColors.secondary : AppColors.error;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    c.improved
                        ? Icons.check_circle_outline_rounded
                        : Icons.remove_circle_outline_rounded,
                    size: 14,
                    color: color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    c.label,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${c.changePercent >= 0 ? '+' : ''}${c.changePercent.toStringAsFixed(1)}%',
                    style: AppTypography.bodySmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.isDark});
  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.titleMedium.copyWith(
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ── Shared error view ──────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              color: AppColors.error.withOpacity(0.5), size: 48),
          const SizedBox(height: AppSpacing.sm),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
