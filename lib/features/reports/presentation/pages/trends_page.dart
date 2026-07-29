import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/trend_data_entity.dart';
import '../providers/analytics_notifier.dart';
import '../providers/analytics_providers.dart';
import '../providers/analytics_state.dart';
import '../providers/reports_providers.dart';
import '../widgets/analytics_widgets.dart';
import '../widgets/chart_card.dart';

// ══════════════════════════════════════════════════════════════════════════════
// TRENDS PAGE
// ══════════════════════════════════════════════════════════════════════════════

/// Full trends analysis page — improving vs declining metrics, sparklines,
/// risk indicators, and a weekly heatmap for workout consistency.
class TrendsPage extends ConsumerStatefulWidget {
  const TrendsPage({super.key});

  @override
  ConsumerState<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends ConsumerState<TrendsPage> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final filter = ref.read(analyticsFilterProvider);
    ref.read(trendNotifierProvider.notifier).load(filter);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(trendNotifierProvider);
    final improving = ref.watch(improvingTrendCountProvider);
    final declining = ref.watch(decliningTrendCountProvider);

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
            actions: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                onPressed: () => FilterBottomSheet.show(
                  context,
                  currentFilter: ref.read(analyticsFilterProvider),
                  onApply: (f) {
                    ref.read(analyticsFilterProvider.notifier).state = f;
                    _load();
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                  left: AppSpacing.xxl, bottom: AppSpacing.md),
              title: Text(
                'Trend Analysis',
                style: AppTypography.titleLarge.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          if (state is TrendsLoading || state is TrendsInitial)
            const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (state is TrendsError)
            SliverFillRemaining(
              child: _ErrorView(message: state.message, onRetry: _load),
            )
          else if (state is TrendsLoaded) ...[
            // ── Summary Tiles ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                child: _TrendSummaryRow(
                  improving: improving,
                  declining: declining,
                  stable:
                      state.report.trends.length - improving - declining,
                  isDark: isDark,
                ),
              ),
            ),

            // ── Risk Alerts Section ──────────────────────────────────────
            if (state.report.highRisk.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.xl, AppSpacing.md,
                      AppSpacing.sm),
                  child: _SectionHeader(
                      title: '⚠️ Risk Indicators',
                      isDark: isDark),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 1.1,
                  children: state.report.highRisk
                      .map((t) => TrendCard(trend: t, isDark: isDark))
                      .toList(),
                ),
              ),
            ],

            // ── Improving Trends ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.xl, AppSpacing.md,
                    AppSpacing.sm),
                child: _SectionHeader(
                    title: '📈 Improving', isDark: isDark),
              ),
            ),
            SliverPadding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.05,
                children: state.report.improving
                    .map((t) => TrendCard(trend: t, isDark: isDark))
                    .toList(),
              ),
            ),

            // ── Declining Trends ─────────────────────────────────────────
            if (state.report.declining.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.xl, AppSpacing.md,
                      AppSpacing.sm),
                  child: _SectionHeader(
                      title: '📉 Needs Attention', isDark: isDark),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 1.05,
                  children: state.report.declining
                      .map((t) => TrendCard(trend: t, isDark: isDark))
                      .toList(),
                ),
              ),
            ],

            // ── Stable Metrics ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.xl, AppSpacing.md,
                    AppSpacing.sm),
                child: _SectionHeader(
                    title: '➡️ Stable Metrics', isDark: isDark),
              ),
            ),
            SliverPadding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.05,
                children: state.report.trends
                    .where((t) =>
                        t.direction == TrendDirection.stable ||
                        t.direction == TrendDirection.fluctuating)
                    .map((t) => TrendCard(trend: t, isDark: isDark))
                    .toList(),
              ),
            ),

            // ── Workout Heatmap ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _WorkoutHeatmapCard(
                  trends: state.report.trends,
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

// ── Trend Summary Row ──────────────────────────────────────────────────────

class _TrendSummaryRow extends StatelessWidget {
  const _TrendSummaryRow({
    required this.improving,
    required this.declining,
    required this.stable,
    required this.isDark,
  });
  final int improving;
  final int declining;
  final int stable;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryPill(
            value: improving.toString(),
            label: 'Improving',
            color: AppColors.secondary,
            icon: Icons.trending_up_rounded,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryPill(
            value: stable.toString(),
            label: 'Stable',
            color: AppColors.warning,
            icon: Icons.trending_flat_rounded,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryPill(
            value: declining.toString(),
            label: 'Declining',
            color: AppColors.error,
            icon: Icons.trending_down_rounded,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
    required this.isDark,
  });
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Text(
            value,
            style: AppTypography.titleSmall
                .copyWith(color: color, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.captionText.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Workout Heatmap Card ───────────────────────────────────────────────────

class _WorkoutHeatmapCard extends StatelessWidget {
  const _WorkoutHeatmapCard({
    required this.trends,
    required this.isDark,
  });
  final List<TrendDataEntity> trends;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Build a Map<date, value> from the workout frequency trend
    final workoutTrend = trends.firstWhere(
      (t) => t.metric == TrendMetric.workouts,
      orElse: () => trends.first,
    );

    final Map<DateTime, double> heatData = {
      for (final p in workoutTrend.series)
        DateTime(p.date.year, p.date.month, p.date.day): p.value,
    };

    return ChartCard(
      title: 'Workout Consistency Heatmap',
      subtitle: 'Darker = more active',
      isDark: isDark,
      height: 200,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: WeeklyHeatMap(
          data: heatData,
          isDark: isDark,
          maxValue: 1.0,
          color: AppColors.primary,
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
              color: AppColors.error.withValues(alpha: 0.5), size: 48),
          const SizedBox(height: AppSpacing.sm),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
