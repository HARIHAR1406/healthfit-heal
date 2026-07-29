import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/ai_report_entity.dart';
import '../../domain/entities/health_report_entity.dart' show DataPoint;
import '../providers/reports_providers.dart';
import '../providers/reports_state.dart';
import '../widgets/chart_card.dart';
import '../widgets/report_filter_bar.dart';
import '../widgets/summary_card.dart';

// ══════════════════════════════════════════════════════════════════════════════
// AI ANALYTICS PAGE
// ══════════════════════════════════════════════════════════════════════════════

class AIAnalyticsPage extends ConsumerStatefulWidget {
  const AIAnalyticsPage({super.key});

  @override
  ConsumerState<AIAnalyticsPage> createState() => _AIAnalyticsPageState();
}

class _AIAnalyticsPageState extends ConsumerState<AIAnalyticsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final filter = ref.read(analyticsFilterProvider);
    ref.read(aiReportProvider.notifier).load(filter);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(aiReportProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'AI Coach Analytics',
          style: AppTypography.titleLarge.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
                bottom: AppSpacing.sm, top: AppSpacing.xs),
            child: ReportFilterBar(onFilterChanged: _load),
          ),
          Expanded(
            child: switch (state) {
              AIReportInitial() || AIReportLoading() => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              AIReportError(:final message) => Center(
                  child: Text(message,
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.error))),
              AIReportLoaded(:final report) =>
                _AIBody(report: report, isDark: isDark),
            },
          ),
        ],
      ),
    );
  }
}

class _AIBody extends StatelessWidget {
  const _AIBody({required this.report, required this.isDark});
  final AIReportEntity report;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      children: [
        // KPIs
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.45,
          children: [
            SummaryCard(
              title: 'Total Sessions',
              value: report.totalSessions.toDouble(),
              unit: 'sessions',
              icon: Icons.chat_rounded,
              color: AppColors.tertiary,
              isDark: isDark,
              delta: report.sessionsDelta.toDouble(),
            ),
            SummaryCard(
              title: 'Total Messages',
              value: report.totalMessages.toDouble(),
              unit: 'messages',
              icon: Icons.message_rounded,
              color: AppColors.primary,
              isDark: isDark,
              delta: report.messagesDelta.toDouble(),
            ),
            SummaryCard(
              title: 'Avg Session Duration',
              value: report.avgSessionDurationMins,
              unit: 'min',
              icon: Icons.timer_rounded,
              color: AppColors.warning,
              isDark: isDark,
              delta: report.durationDelta,
              formatValue: (v) => v.toStringAsFixed(1),
            ),
            SummaryCard(
              title: 'Insights Generated',
              value: report.totalInsightsGenerated.toDouble(),
              unit: 'insights',
              icon: Icons.lightbulb_rounded,
              color: AppColors.secondary,
              isDark: isDark,
              delta: report.insightsDelta.toDouble(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Usage Area Charts
        ChartCard(
          title: 'Session Activity',
          subtitle: 'Daily AI coaching sessions',
          isDark: isDark,
          height: 200,
          legend: const [
            LegendItem(label: 'Sessions', color: AppColors.tertiary),
          ],
          child: _AIAreaChart(
              series: report.sessionsSeries,
              color: AppColors.tertiary,
              isDark: isDark),
        ),
        const SizedBox(height: AppSpacing.md),

        ChartCard(
          title: 'Message Volume',
          subtitle: 'Daily messages sent & received',
          isDark: isDark,
          height: 200,
          legend: const [
            LegendItem(label: 'Messages', color: AppColors.primary),
          ],
          child: _AIAreaChart(
              series: report.messagesSeries,
              color: AppColors.primary,
              isDark: isDark),
        ),
        const SizedBox(height: AppSpacing.md),

        // Topic Frequency (Pie)
        ChartCard(
          title: 'Frequently Asked Topics',
          subtitle: 'By message volume',
          isDark: isDark,
          height: 260,
          child: _TopicPieChart(
              topics: report.topicFrequency, isDark: isDark),
        ),
        const SizedBox(height: AppSpacing.md),

        // Coach Usage (Donut)
        ChartCard(
          title: 'Coach Usage',
          subtitle:
              'Most used: ${report.mostUsedCoach} coach',
          isDark: isDark,
          height: 230,
          child: _CoachDonutChart(
              coaches: report.coachUsage, isDark: isDark),
        ),
        const SizedBox(height: AppSpacing.md),

        // Quality KPIs
        _QualityCard(report: report, isDark: isDark),
        const SizedBox(height: AppSpacing.md),

        // Weekly AI Insights
        _WeeklyInsightsSection(
            insights: report.weeklyInsights, isDark: isDark),
        const SizedBox(height: AppSpacing.massive),
      ],
    );
  }
}

// ── AI Area Chart ─────────────────────────────────────────────────────────────

class _AIAreaChart extends StatelessWidget {
  const _AIAreaChart(
      {required this.series, required this.color, required this.isDark});
  final List<DataPoint> series;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    const maxPts = 30;
    final s = series.length > maxPts
        ? series.sublist(series.length - maxPts)
        : series;

    final textColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
      child: LineChart(
        LineChartData(
          minY: 0,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (s.length / 5).ceilToDouble(),
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= s.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('d/M').format(s[idx].date),
                      style: AppTypography.captionText
                          .copyWith(color: textColor, fontSize: 9),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: s.asMap().entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                  .toList(),
              isCurved: true,
              color: color,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.25),
                    color.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      ),
    );
  }
}

// ── Topic Pie ─────────────────────────────────────────────────────────────────

class _TopicPieChart extends StatefulWidget {
  const _TopicPieChart({required this.topics, required this.isDark});
  final List<TopicFrequency> topics;
  final bool isDark;

  @override
  State<_TopicPieChart> createState() => _TopicPieChartState();
}

class _TopicPieChartState extends State<_TopicPieChart> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final total = widget.topics.fold(0, (s, t) => s + t.count);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: widget.topics.asMap().entries.map((e) {
                  final i = e.key;
                  final t = e.value;
                  final pct = total == 0 ? 0.0 : t.count / total;
                  final isTouched = i == _touched;
                  return PieChartSectionData(
                    color: t.color,
                    value: t.count.toDouble(),
                    title: isTouched
                        ? '${(pct * 100).toStringAsFixed(0)}%'
                        : '',
                    radius: isTouched ? 75 : 60,
                    titleStyle: AppTypography.captionText.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                pieTouchData: PieTouchData(
                  touchCallback: (event, resp) {
                    if (resp?.touchedSection != null &&
                        event is FlTapUpEvent) {
                      setState(() {
                        _touched = resp!
                            .touchedSection!.touchedSectionIndex;
                      });
                    }
                  },
                ),
              ),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.topics.map((t) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: t.color, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(
                      t.topic,
                      style: AppTypography.captionText.copyWith(
                        color: widget.isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${t.count})',
                      style: AppTypography.captionText.copyWith(
                        color: t.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Coach Donut ───────────────────────────────────────────────────────────────

class _CoachDonutChart extends StatefulWidget {
  const _CoachDonutChart({required this.coaches, required this.isDark});
  final List<CoachUsage> coaches;
  final bool isDark;

  @override
  State<_CoachDonutChart> createState() => _CoachDonutChartState();
}

class _CoachDonutChartState extends State<_CoachDonutChart> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final total = widget.coaches.fold(0, (s, c) => s + c.sessions);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: widget.coaches.asMap().entries.map((e) {
                  final i = e.key;
                  final c = e.value;
                  final pct = total == 0 ? 0.0 : c.sessions / total;
                  final isTouched = i == _touched;
                  return PieChartSectionData(
                    color: c.color,
                    value: c.sessions.toDouble(),
                    title:
                        isTouched ? '${(pct * 100).toStringAsFixed(0)}%' : '',
                    radius: isTouched ? 72 : 58,
                    titleStyle: AppTypography.captionText.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700),
                    badgeWidget:
                        isTouched ? null : Text(c.emoji, style: const TextStyle(fontSize: 16)),
                    badgePositionPercentageOffset: 0.85,
                  );
                }).toList(),
                sectionsSpace: 3,
                centerSpaceRadius: 38,
                pieTouchData: PieTouchData(
                  touchCallback: (event, resp) {
                    if (resp?.touchedSection != null &&
                        event is FlTapUpEvent) {
                      setState(() {
                        _touched =
                            resp!.touchedSection!.touchedSectionIndex;
                      });
                    }
                  },
                ),
              ),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.coaches.map((c) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(c.emoji,
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.coachType,
                          style: AppTypography.captionText.copyWith(
                            color: widget.isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '${c.sessions} sessions · ${c.messages} msgs',
                          style: AppTypography.captionText.copyWith(
                            color: c.color,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Quality Card ──────────────────────────────────────────────────────────────

class _QualityCard extends StatelessWidget {
  const _QualityCard({required this.report, required this.isDark});
  final AIReportEntity report;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.tertiary.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: AppColors.tertiary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Text('🤖', style: TextStyle(fontSize: 36)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Quality Score',
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(
                          begin: 0,
                          end: report.avgResponseQualityScore),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => Text(
                        '${v.toInt()} / 100',
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.tertiary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    TrendIndicator(delta: 3.5, compact: true),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${report.recommendationsGenerated} recommendations generated',
                  style: AppTypography.captionText.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Weekly Insights ───────────────────────────────────────────────────────────

class _WeeklyInsightsSection extends StatelessWidget {
  const _WeeklyInsightsSection(
      {required this.insights, required this.isDark});
  final List<WeeklyAIInsight> insights;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly AI Insights',
          style: AppTypography.titleMedium.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...insights.map(
          (insight) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: insight.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: insight.color.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: insight.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lightbulb_rounded,
                        color: insight.color, size: 18),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                insight.title,
                                style: AppTypography.bodySmall.copyWith(
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: insight.color
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                insight.category,
                                style: AppTypography.captionText.copyWith(
                                  color: insight.color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          insight.summary,
                          style: AppTypography.captionText.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d').format(insight.weekStart),
                          style: AppTypography.captionText.copyWith(
                            color: insight.color.withValues(alpha: 0.7),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
