import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/fitness_report_entity.dart';
import '../../domain/entities/health_report_entity.dart' show DataPoint;
import '../providers/reports_providers.dart';
import '../providers/reports_state.dart';
import '../widgets/chart_card.dart';
import '../widgets/report_filter_bar.dart';
import '../widgets/summary_card.dart';

// ══════════════════════════════════════════════════════════════════════════════
// FITNESS ANALYTICS REPORT PAGE
// ══════════════════════════════════════════════════════════════════════════════

/// Fitness-specific analytics page with 7 chart sections.
class FitnessAnalyticsReportPage extends ConsumerStatefulWidget {
  const FitnessAnalyticsReportPage({super.key});

  @override
  ConsumerState<FitnessAnalyticsReportPage> createState() =>
      _FitnessAnalyticsReportPageState();
}

class _FitnessAnalyticsReportPageState
    extends ConsumerState<FitnessAnalyticsReportPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final filter = ref.read(analyticsFilterProvider);
    ref.read(fitnessReportProvider.notifier).load(filter);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(fitnessReportProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Fitness Analytics',
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
              FitnessReportInitial() || FitnessReportLoading() => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              FitnessReportError(:final message) => Center(
                  child: Text(message,
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.error))),
              FitnessReportLoaded(:final report) =>
                _FitnessBody(report: report, isDark: isDark),
            },
          ),
        ],
      ),
    );
  }
}

class _FitnessBody extends StatelessWidget {
  const _FitnessBody({required this.report, required this.isDark});
  final FitnessReportEntity report;
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
              title: 'Total Workouts',
              value: report.totalWorkouts.toDouble(),
              unit: 'sessions',
              icon: Icons.fitness_center_rounded,
              color: AppColors.primary,
              isDark: isDark,
              delta: report.workoutsDelta.toDouble(),
            ),
            SummaryCard(
              title: 'Calories Burned',
              value: report.totalCaloriesBurned,
              unit: 'kcal',
              icon: Icons.local_fire_department_rounded,
              color: AppColors.secondary,
              isDark: isDark,
              delta: report.caloriesBurnedDelta,
              formatValue: (v) => '${(v / 1000).toStringAsFixed(1)}k',
            ),
            SummaryCard(
              title: 'Active Minutes',
              value: report.totalActiveMinutes.toDouble(),
              unit: 'min',
              icon: Icons.timer_rounded,
              color: AppColors.tertiary,
              isDark: isDark,
              delta: report.activeMinutesDelta.toDouble(),
            ),
            SummaryCard(
              title: 'Distance',
              value: report.totalDistanceKm,
              unit: 'km',
              icon: Icons.directions_run_rounded,
              color: AppColors.warning,
              isDark: isDark,
              delta: report.distanceDelta,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Streak Card
        _StreakCard(streak: report.streak, isDark: isDark),
        const SizedBox(height: AppSpacing.md),

        // Workout Frequency (bar chart)
        ChartCard(
          title: 'Workout Frequency',
          subtitle: '${report.totalWorkouts} workouts in selected period',
          isDark: isDark,
          height: 200,
          child: _FrequencyBarChart(
              series: report.workoutFrequencySeries, isDark: isDark),
        ),
        const SizedBox(height: AppSpacing.md),

        // Calories Burned (area chart)
        ChartCard(
          title: 'Calories Burned',
          subtitle:
              'Daily avg ${(report.totalCaloriesBurned / report.totalWorkouts.clamp(1, 999)).toStringAsFixed(0)} kcal/workout',
          isDark: isDark,
          height: 220,
          legend: const [
            LegendItem(label: 'Calories', color: AppColors.secondary),
          ],
          child: _AreaLineChart(
              series: report.caloriesBurnedSeries,
              color: AppColors.secondary,
              isDark: isDark),
        ),
        const SizedBox(height: AppSpacing.md),

        // Active Minutes (area chart)
        ChartCard(
          title: 'Active Minutes',
          subtitle:
              'Avg ${(report.totalActiveMinutes / (report.workoutFrequencySeries.length)).toStringAsFixed(0)} min/day',
          isDark: isDark,
          height: 200,
          legend: const [
            LegendItem(label: 'Active Minutes', color: AppColors.tertiary),
          ],
          child: _AreaLineChart(
              series: report.activeMinutesSeries,
              color: AppColors.tertiary,
              isDark: isDark),
        ),
        const SizedBox(height: AppSpacing.md),

        // Distance (area chart)
        ChartCard(
          title: 'Distance Covered',
          subtitle:
              '${report.totalDistanceKm.toStringAsFixed(1)} km total',
          isDark: isDark,
          height: 200,
          legend: const [
            LegendItem(label: 'Distance (km)', color: AppColors.warning),
          ],
          child: _AreaLineChart(
              series: report.distanceSeries,
              color: AppColors.warning,
              isDark: isDark),
        ),
        const SizedBox(height: AppSpacing.md),

        // Category Breakdown (Pie Chart)
        ChartCard(
          title: 'Workout Categories',
          subtitle: 'Distribution by session count',
          isDark: isDark,
          height: 250,
          child: _CategoryPieChart(
              categories: report.categoryBreakdown, isDark: isDark),
        ),
        const SizedBox(height: AppSpacing.md),

        // Goal Completion (comparison)
        _GoalCompletionCard(report: report, isDark: isDark),
        const SizedBox(height: AppSpacing.massive),
      ],
    );
  }
}

// ── Streak Card ───────────────────────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak, required this.isDark});
  final StreakData streak;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C896), Color(0xFF00A87C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🔥 Current Streak',
                  style: AppTypography.bodySmall
                      .copyWith(color: Colors.white.withOpacity(0.85))),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${streak.current}',
                    style: AppTypography.headlineLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(' days',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        )),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Column(
            children: [
              _StatPill(label: 'Longest', value: '${streak.longest}d'),
              const SizedBox(height: 4),
              _StatPill(
                label: 'Active Days',
                value: '${streak.activeDays}/${streak.totalDays}',
              ),
              const SizedBox(height: 4),
              _StatPill(
                label: 'Completion',
                value:
                    '${(streak.completionRate * 100).toStringAsFixed(0)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style:
                AppTypography.captionText.copyWith(color: Colors.white70),
          ),
          Text(
            value,
            style: AppTypography.captionText.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Frequency Bar Chart ───────────────────────────────────────────────────────

class _FrequencyBarChart extends StatelessWidget {
  const _FrequencyBarChart(
      {required this.series, required this.isDark});
  final List<DataPoint> series;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    const maxPts = 28;
    final slice = series.length > maxPts
        ? series.sublist(series.length - maxPts)
        : series;

    final textColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
      child: BarChart(
        BarChartData(
          maxY: 1.5,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: (isDark ? Colors.white : Colors.grey)
                  .withOpacity(0.08),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: (slice.length / 7).ceilToDouble(),
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= slice.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('d/M').format(slice[idx].date),
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
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) =>
                  isDark ? const Color(0xFF2A3550) : Colors.white,
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                rod.toY > 0 ? '✓ Active' : 'Rest',
                AppTypography.captionText.copyWith(
                  color: rod.toY > 0
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          barGroups: slice.asMap().entries.map((e) {
            final isActive = e.value.value > 0;
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: isActive ? 1 : 0.15,
                  color: isActive
                      ? AppColors.primary
                      : (isDark ? Colors.white : Colors.grey)
                          .withOpacity(0.12),
                  width: 6,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      ),
    );
  }
}

// ── Area Line Chart ───────────────────────────────────────────────────────────

class _AreaLineChart extends StatelessWidget {
  const _AreaLineChart(
      {required this.series, required this.color, required this.isDark});
  final List<DataPoint> series;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    const maxPts = 30;
    final slice = series.length > maxPts
        ? series.sublist(series.length - maxPts)
        : series;

    double minY = slice.fold(double.infinity, (m, p) => p.value < m ? p.value : m);
    double maxY = slice.fold(0.0, (m, p) => p.value > m ? p.value : m);
    final pad = (maxY - minY) * 0.15;
    minY = (minY - pad).floorToDouble();
    maxY = (maxY + pad).ceilToDouble();

    final textColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: (isDark ? Colors.white : Colors.grey)
                  .withOpacity(0.08),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (v, _) => Text(
                  v >= 1000
                      ? '${(v / 1000).toStringAsFixed(1)}k'
                      : v.toInt().toString(),
                  style: AppTypography.captionText
                      .copyWith(color: textColor, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (slice.length / 5).ceilToDouble(),
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= slice.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('d/M').format(slice[idx].date),
                      style: AppTypography.captionText
                          .copyWith(color: textColor, fontSize: 9),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) =>
                  isDark ? const Color(0xFF2A3550) : Colors.white,
              getTooltipItems: (spots) => spots.map((s) {
                return LineTooltipItem(
                  s.y >= 1000
                      ? '${(s.y / 1000).toStringAsFixed(1)}k'
                      : s.y.toStringAsFixed(1),
                  AppTypography.captionText.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: slice.asMap().entries
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
                    color.withOpacity(0.25),
                    color.withOpacity(0.02),
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

// ── Category Pie Chart ────────────────────────────────────────────────────────

class _CategoryPieChart extends StatefulWidget {
  const _CategoryPieChart(
      {required this.categories, required this.isDark});
  final List<WorkoutCategoryBreakdown> categories;
  final bool isDark;

  @override
  State<_CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<_CategoryPieChart> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final total = widget.categories.fold(0, (s, c) => s + c.sessions);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Pie
          Expanded(
            child: PieChart(
              PieChartData(
                sections: widget.categories.asMap().entries.map((e) {
                  final i = e.key;
                  final c = e.value;
                  final isTouched = i == _touched;
                  final pct = total == 0 ? 0.0 : c.sessions / total;
                  return PieChartSectionData(
                    color: c.color,
                    value: c.sessions.toDouble(),
                    title: isTouched
                        ? '${(pct * 100).toStringAsFixed(0)}%'
                        : '',
                    radius: isTouched ? 72 : 60,
                    titleStyle: AppTypography.captionText.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList(),
                sectionsSpace: 3,
                centerSpaceRadius: 36,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    if (response?.touchedSection != null &&
                        event is FlTapUpEvent) {
                      setState(() {
                        _touched = response!
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

          // Legend
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.categories.map((c) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: c.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${c.category} (${c.sessions})',
                      style: AppTypography.captionText.copyWith(
                        color: widget.isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        fontSize: 11,
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

// ── Goal Completion ───────────────────────────────────────────────────────────

class _GoalCompletionCard extends StatelessWidget {
  const _GoalCompletionCard(
      {required this.report, required this.isDark});
  final FitnessReportEntity report;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final pct = report.goalCompletionRate.clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Goal Completion',
                style: AppTypography.titleSmall.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TrendIndicator(
                delta: report.goalCompletionDelta * 100,
                label:
                    '+${(report.goalCompletionDelta * 100).toStringAsFixed(0)}%',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: pct * 100),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => Text(
                  '${v.toInt()}%',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: pct),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => LinearProgressIndicator(
                      value: v,
                      backgroundColor:
                          AppColors.primary.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation(
                          AppColors.primary),
                      minHeight: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

