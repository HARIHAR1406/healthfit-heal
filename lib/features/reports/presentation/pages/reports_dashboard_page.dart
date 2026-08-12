import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../providers/reports_providers.dart';
import '../providers/reports_state.dart';
import '../widgets/chart_card.dart';
import '../widgets/health_score_ring.dart';
import '../widgets/report_filter_bar.dart';
import '../widgets/summary_card.dart';

// ══════════════════════════════════════════════════════════════════════════════
// REPORTS DASHBOARD PAGE
// ══════════════════════════════════════════════════════════════════════════════

/// Master hub for all analytics — shows overall score, quick KPIs,
/// and navigation cards to each sub-analytics section.
class ReportsDashboardPage extends ConsumerStatefulWidget {
  const ReportsDashboardPage({super.key});

  @override
  ConsumerState<ReportsDashboardPage> createState() =>
      _ReportsDashboardPageState();
}

class _ReportsDashboardPageState extends ConsumerState<ReportsDashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _entranceCtrl.forward();
    _loadAll();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  void _loadAll() {
    final filter = ref.read(analyticsFilterProvider);
    ref.read(dashboardReportProvider.notifier).load(filter);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dashState = ref.watch(dashboardReportProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            snap: true,
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                  left: AppSpacing.xxl, bottom: AppSpacing.md),
              title: Text(
                'Reports & Analytics',
                style: AppTypography.titleLarge.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.share_outlined,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
                onPressed: () => context.push(RouteNames.reportsExport),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
          ),

          // ── Filter Bar ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                  top: AppSpacing.sm, bottom: AppSpacing.md),
              child: ReportFilterBar(onFilterChanged: _loadAll),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          SliverPadding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Overall Score Ring
                _OverallScoreSection(
                  dashState: dashState,
                  isDark: isDark,
                  entranceCtrl: _entranceCtrl,
                ),
                const SizedBox(height: AppSpacing.xl),

                // KPI Row
                if (dashState is DashboardReportLoaded) ...[
                  _KpiRow(report: dashState, isDark: isDark),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // Analytics Navigation Cards
                _SectionHeader(
                    title: 'Analytics', isDark: isDark),
                const SizedBox(height: AppSpacing.md),
                _AnalyticsGrid(isDark: isDark),
                const SizedBox(height: AppSpacing.xl),

                // Quick Summary
                _SectionHeader(title: 'Quick Summary', isDark: isDark),
                const SizedBox(height: AppSpacing.md),
                _QuickSummaryList(isDark: isDark),
                const SizedBox(height: AppSpacing.massive),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Overall Score Section ─────────────────────────────────────────────────────

class _OverallScoreSection extends StatelessWidget {
  const _OverallScoreSection({
    required this.dashState,
    required this.isDark,
    required this.entranceCtrl,
  });

  final DashboardReportState dashState;
  final bool isDark;
  final AnimationController entranceCtrl;

  @override
  Widget build(BuildContext context) {
    if (dashState is DashboardReportLoading ||
        dashState is DashboardReportInitial) {
      return const _LoadingScorePlaceholder();
    }
    if (dashState is DashboardReportError) {
      final err = dashState as DashboardReportError;
      return Center(child: Text(err.message));
    }
    final report = dashState as DashboardReportLoaded;

    return FadeTransition(
      opacity: entranceCtrl,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A2A4A), Color(0xFF0A1628)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Health Score',
                    style: AppTypography.titleSmall.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(
                            begin: 0, end: report.overallScore),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => Text(
                          v.toInt().toString(),
                          style: AppTypography.displayMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          ' / 100',
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ScoreBar(
                      label: '❤️ Health',
                      value: report.healthScore / 100),
                  const SizedBox(height: AppSpacing.xs),
                  _ScoreBar(
                      label: '🏋️ Fitness',
                      value: report.fitnessScore / 100,
                      color: AppColors.primary),
                  const SizedBox(height: AppSpacing.xs),
                  _ScoreBar(
                      label: '🥗 Nutrition',
                      value: report.nutritionScore / 100,
                      color: AppColors.tertiary),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            HealthScoreRing(
              score: report.overallScore,
              isDark: true,
              size: 110,
              strokeWidth: 12,
              healthScore: report.healthScore,
              fitnessScore: report.fitnessScore,
              nutritionScore: report.nutritionScore,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({
    required this.label,
    required this.value,
    this.color = AppColors.secondary,
  });
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: AppTypography.captionText.copyWith(
              color: Colors.white.withOpacity(0.75),
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        SizedBox(
          width: 32,
          child: Text(
            '${(value * 100).toInt()}',
            style: AppTypography.captionText.copyWith(
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _LoadingScorePlaceholder extends StatelessWidget {
  const _LoadingScorePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A4A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

// ── KPI Row ───────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.report, required this.isDark});
  final DashboardReportLoaded report;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            title: 'Readings',
            value: report.totalReadings.toDouble(),
            unit: 'total',
            icon: Icons.favorite_rounded,
            color: AppColors.secondary,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: SummaryCard(
            title: 'Workouts',
            value: report.totalWorkouts.toDouble(),
            unit: 'sessions',
            icon: Icons.fitness_center_rounded,
            color: AppColors.primary,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: SummaryCard(
            title: 'Days Logged',
            value: report.daysLogged.toDouble(),
            unit: 'days',
            icon: Icons.restaurant_rounded,
            color: AppColors.tertiary,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

// ── Analytics Grid ────────────────────────────────────────────────────────────

class _AnalyticsGrid extends StatelessWidget {
  const _AnalyticsGrid({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _NavCard(
        title: 'Health',
        subtitle: 'Vitals & medical trends',
        emoji: '❤️',
        colors: [AppColors.secondary, const Color(0xFFFF9E9E)],
        route: RouteNames.reportsHealth,
      ),
      _NavCard(
        title: 'Fitness',
        subtitle: 'Workouts & performance',
        emoji: '🏋️',
        colors: [AppColors.primary, const Color(0xFF00A87C)],
        route: RouteNames.reportsFitness,
      ),
      _NavCard(
        title: 'Nutrition',
        subtitle: 'Macros & meal quality',
        emoji: '🥗',
        colors: [AppColors.tertiary, const Color(0xFF9D97FF)],
        route: RouteNames.reportsNutrition,
      ),
      _NavCard(
        title: 'AI Insights',
        subtitle: 'Coach usage & topics',
        emoji: '🤖',
        colors: [AppColors.warning, const Color(0xFFFFCC80)],
        route: RouteNames.reportsAI,
      ),
      _NavCard(
        title: 'Insights',
        subtitle: 'AI-generated health tips',
        emoji: '🧠',
        colors: [const Color(0xFF6C63FF), const Color(0xFF9D97FF)],
        route: RouteNames.reportsInsights,
      ),
      _NavCard(
        title: 'Compare',
        subtitle: 'Period-over-period analysis',
        emoji: '📊',
        colors: [const Color(0xFF00B4D8), const Color(0xFF0077B6)],
        route: RouteNames.reportsCompare,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.25,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) {
        final card = cards[i];
        return AnalyticsCard(
          title: card.title,
          subtitle: card.subtitle,
          emoji: card.emoji,
          gradientColors: card.colors,
          isDark: isDark,
          onTap: () => context.push(card.route),
        );
      },
    );
  }
}

class _NavCard {
  const _NavCard({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.colors,
    required this.route,
  });
  final String title;
  final String subtitle;
  final String emoji;
  final List<Color> colors;
  final String route;
}

// ── Quick Summary ─────────────────────────────────────────────────────────────

class _QuickSummaryList extends StatelessWidget {
  const _QuickSummaryList({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryItem(
        icon: Icons.bar_chart_rounded,
        iconColor: AppColors.primary,
        title: 'Weekly Summary',
        sub: 'View 7-day performance overview',
        route: RouteNames.reportsHealth,
      ),
      _SummaryItem(
        icon: Icons.calendar_month_rounded,
        iconColor: AppColors.tertiary,
        title: 'Monthly Summary',
        sub: 'View 30-day health trends',
        route: RouteNames.reportsHealth,
      ),
      _SummaryItem(
        icon: Icons.psychology_rounded,
        iconColor: const Color(0xFF6C63FF),
        title: 'AI Insights',
        sub: 'Personalized health recommendations',
        route: RouteNames.reportsInsights,
      ),
      _SummaryItem(
        icon: Icons.trending_up_rounded,
        iconColor: AppColors.secondary,
        title: 'Trend Analysis',
        sub: 'Improving & declining metrics',
        route: RouteNames.reportsTrends,
      ),
      _SummaryItem(
        icon: Icons.compare_arrows_rounded,
        iconColor: const Color(0xFF00B4D8),
        title: 'Compare Periods',
        sub: 'Week vs week, month vs month',
        route: RouteNames.reportsCompare,
      ),
      _SummaryItem(
        icon: Icons.emoji_events_rounded,
        iconColor: AppColors.warning,
        title: 'Achievements',
        sub: 'Streak records & milestones',
        route: RouteNames.reportsAchievements,
      ),
      _SummaryItem(
        icon: Icons.download_rounded,
        iconColor: AppColors.secondary,
        title: 'Export Center',
        sub: 'PDF, CSV, Excel reports',
        route: RouteNames.reportsExport,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.withOpacity(0.08),
        ),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final item = e.value;
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              ReportTile(
                title: item.title,
                subtitle: item.sub,
                isDark: isDark,
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: item.iconColor.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 20),
                ),
                onTap: () => context.push(item.route),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: AppSpacing.xxl + AppSpacing.xs,
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.08),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SummaryItem {
  const _SummaryItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.sub,
    required this.route,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String sub;
  final String route;
}

// ── Section Header ────────────────────────────────────────────────────────────

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

