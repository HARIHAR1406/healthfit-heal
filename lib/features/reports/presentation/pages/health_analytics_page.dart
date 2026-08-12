import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/health_report_entity.dart';
import '../providers/reports_providers.dart';
import '../providers/reports_state.dart';
import '../widgets/chart_card.dart';
import '../widgets/health_score_ring.dart';
import '../widgets/report_filter_bar.dart';
import '../widgets/summary_card.dart';

// ══════════════════════════════════════════════════════════════════════════════
// HEALTH ANALYTICS PAGE
// ══════════════════════════════════════════════════════════════════════════════

class HealthAnalyticsPage extends ConsumerStatefulWidget {
  const HealthAnalyticsPage({super.key});

  @override
  ConsumerState<HealthAnalyticsPage> createState() =>
      _HealthAnalyticsPageState();
}

class _HealthAnalyticsPageState extends ConsumerState<HealthAnalyticsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final filter = ref.read(analyticsFilterProvider);
    ref.read(healthReportProvider.notifier).load(filter);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(healthReportProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Health Analytics',
          style: AppTypography.titleLarge.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
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
              HealthReportInitial() => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              HealthReportLoading() => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              HealthReportError(:final message) => Center(
                  child: Text(message,
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.error))),
              HealthReportLoaded(:final report) =>
                _HealthAnalyticsBody(report: report, isDark: isDark),
            },
          ),
        ],
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _HealthAnalyticsBody extends StatelessWidget {
  const _HealthAnalyticsBody(
      {required this.report, required this.isDark});

  final HealthReportEntity report;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      children: [
        // ── Radar + Score KPIs ──────────────────────────────────────────────
        _RadarScoreRow(report: report, isDark: isDark),
        const SizedBox(height: AppSpacing.md),

        // ── KPI Summary Cards ───────────────────────────────────────────────
        _HealthKpiGrid(report: report, isDark: isDark),
        const SizedBox(height: AppSpacing.md),

        // ── Heart Rate Chart ────────────────────────────────────────────────
        ChartCard(
          title: 'Heart Rate Trends',
          subtitle:
              'Avg ${report.avgHeartRate.toStringAsFixed(0)} bpm · '
              'Min ${report.minHeartRate.toStringAsFixed(0)} · '
              'Max ${report.maxHeartRate.toStringAsFixed(0)}',
          isDark: isDark,
          height: 220,
          legend: const [
            LegendItem(label: 'Heart Rate', color: AppColors.secondary),
          ],
          child: _LineChartWidget(
            series: [report.heartRateSeries],
            colors: const [AppColors.secondary],
            isDark: isDark,
            yAxisLabel: 'bpm',
            showArea: true,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Blood Pressure Chart ────────────────────────────────────────────
        ChartCard(
          title: 'Blood Pressure Trends',
          subtitle:
              'Avg ${report.avgSystolic.toStringAsFixed(0)}/'
              '${report.avgDiastolic.toStringAsFixed(0)} mmHg',
          isDark: isDark,
          height: 220,
          legend: const [
            LegendItem(label: 'Systolic', color: AppColors.secondary),
            LegendItem(label: 'Diastolic', color: AppColors.primary),
          ],
          child: _BPChartWidget(bpSeries: report.bpSeries, isDark: isDark),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Blood Sugar Chart ───────────────────────────────────────────────
        ChartCard(
          title: 'Blood Sugar Trends',
          subtitle:
              'Avg ${report.avgBloodSugar.toStringAsFixed(0)} mg/dL · '
              'Target: 70–99 mg/dL',
          isDark: isDark,
          height: 220,
          legend: const [
            LegendItem(label: 'Blood Sugar', color: AppColors.warning),
          ],
          child: _LineChartWidget(
            series: [report.bloodSugarSeries],
            colors: const [AppColors.warning],
            isDark: isDark,
            yAxisLabel: 'mg/dL',
            showRefBand: true,
            refBandMin: 70,
            refBandMax: 99,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── SpO₂ Chart ──────────────────────────────────────────────────────
        ChartCard(
          title: 'SpO₂ Trends',
          subtitle:
              'Avg ${report.avgSpo2.toStringAsFixed(1)}% · Normal: ≥ 95%',
          isDark: isDark,
          height: 200,
          legend: const [
            LegendItem(label: 'SpO₂', color: AppColors.info),
          ],
          child: _LineChartWidget(
            series: [report.spo2Series],
            colors: const [AppColors.info],
            isDark: isDark,
            yAxisLabel: '%',
            showRefBand: true,
            refBandMin: 95,
            refBandMax: 100,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── BMI + Weight in a row ───────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: ChartCard(
                title: 'BMI Progress',
                subtitle: BmiCategory.fromBmi(report.currentBmi).label,
                isDark: isDark,
                height: 180,
                child: _LineChartWidget(
                  series: [report.bmiSeries],
                  colors: [
                    BmiCategory.fromBmi(report.currentBmi).color,
                  ],
                  isDark: isDark,
                  compact: true,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ChartCard(
                title: 'Weight Progress',
                subtitle: '${report.currentWeight.toStringAsFixed(1)} kg',
                isDark: isDark,
                height: 180,
                child: _LineChartWidget(
                  series: [report.weightSeries],
                  colors: const [AppColors.primary],
                  isDark: isDark,
                  compact: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.massive),
      ],
    );
  }
}

// ── Radar + Score Row ─────────────────────────────────────────────────────────

class _RadarScoreRow extends StatelessWidget {
  const _RadarScoreRow({required this.report, required this.isDark});
  final HealthReportEntity report;
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
              : Colors.grey.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          HealthRadarChart(
            scores: report.radarScores,
            isDark: isDark,
            size: 170,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health Score',
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: report.healthScore),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Text(
                    v.toInt().toString(),
                    style: AppTypography.displaySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TrendIndicator(delta: report.healthScoreDelta),
                const SizedBox(height: AppSpacing.md),
                ...report.radarScores.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.key,
                              style: AppTypography.captionText.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                          Text(
                            '${(e.value * 100).toInt()}%',
                            style: AppTypography.captionText.copyWith(
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── KPI Grid ──────────────────────────────────────────────────────────────────

class _HealthKpiGrid extends StatelessWidget {
  const _HealthKpiGrid({required this.report, required this.isDark});
  final HealthReportEntity report;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.5,
      children: [
        SummaryCard(
          title: 'Avg Heart Rate',
          value: report.avgHeartRate,
          unit: 'bpm',
          icon: Icons.favorite_rounded,
          color: AppColors.secondary,
          isDark: isDark,
          delta: report.heartRateDelta,
        ),
        SummaryCard(
          title: 'Avg Blood Pressure',
          value: report.avgSystolic,
          unit: 'mmHg',
          icon: Icons.water_drop_rounded,
          color: AppColors.info,
          isDark: isDark,
          delta: report.bpDelta,
          subtitle: '/ ${report.avgDiastolic.toStringAsFixed(0)} diastolic',
        ),
        SummaryCard(
          title: 'Blood Sugar',
          value: report.avgBloodSugar,
          unit: 'mg/dL',
          icon: Icons.bloodtype_rounded,
          color: AppColors.warning,
          isDark: isDark,
          delta: report.bloodSugarDelta,
          positiveIsGood: false,
        ),
        SummaryCard(
          title: 'SpO₂',
          value: report.avgSpo2,
          unit: '%',
          icon: Icons.air_rounded,
          color: AppColors.primary,
          isDark: isDark,
          delta: report.spo2Delta,
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARED CHART WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _LineChartWidget extends StatelessWidget {
  const _LineChartWidget({
    required this.series,
    required this.colors,
    required this.isDark,
    this.yAxisLabel = '',
    this.showArea = false,
    this.showRefBand = false,
    this.refBandMin = 0,
    this.refBandMax = double.infinity,
    this.compact = false,
  });

  final List<List<DataPoint>> series;
  final List<Color> colors;
  final bool isDark;
  final String yAxisLabel;
  final bool showArea;
  final bool showRefBand;
  final double refBandMin;
  final double refBandMax;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty || series.first.isEmpty) {
      return const Center(child: Text('No data'));
    }
    final maxPts = 30; // only show last 30 for readability
    final all = series.first;
    final slice = all.length > maxPts ? all.sublist(all.length - maxPts) : all;

    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    for (final s in series) {
      final sl = s.length > maxPts ? s.sublist(s.length - maxPts) : s;
      for (final p in sl) {
        if (p.value < minY) minY = p.value;
        if (p.value > maxY) maxY = p.value;
      }
    }
    final padding = (maxY - minY) * 0.15;
    minY = (minY - padding).floorToDouble();
    maxY = (maxY + padding).ceilToDouble();

    final lineBarsData = series.asMap().entries.map((e) {
      final i = e.key;
      final s = e.value;
      final sl = s.length > maxPts ? s.sublist(s.length - maxPts) : s;
      final color = colors[i % colors.length];
      return LineChartBarData(
        spots: sl.asMap().entries
            .map((ep) => FlSpot(ep.key.toDouble(), ep.value.value))
            .toList(),
        isCurved: true,
        color: color,
        barWidth: 2.5,
        dotData: const FlDotData(show: false),
        belowBarData: showArea && i == 0
            ? BarAreaData(
                show: true,
                color: color.withOpacity(0.12),
              )
            : BarAreaData(show: false),
      );
    }).toList();

    final textColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final gridColor = (isDark ? Colors.white : Colors.grey)
        .withOpacity(0.08);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          compact ? 4 : AppSpacing.sm,
          AppSpacing.md,
          compact ? 4 : AppSpacing.sm,
          AppSpacing.sm),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: !compact,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: gridColor, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: compact
              ? const FlTitlesData(show: false)
              : FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style:
                            AppTypography.captionText.copyWith(
                              color: textColor,
                              fontSize: 10,
                            ),
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
                            DateFormat('d/M')
                                .format(slice[idx].date),
                            style:
                                AppTypography.captionText.copyWith(
                                  color: textColor,
                                  fontSize: 9,
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) =>
                  isDark ? const Color(0xFF2A3550) : Colors.white,
              getTooltipItems: (spots) => spots.map((s) {
                final color = colors[s.barIndex % colors.length];
                return LineTooltipItem(
                  '${s.y.toStringAsFixed(1)} $yAxisLabel',
                  AppTypography.captionText.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: lineBarsData,
        ),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      ),
    );
  }
}

class _BPChartWidget extends StatelessWidget {
  const _BPChartWidget(
      {required this.bpSeries, required this.isDark});
  final List<DataPoint2> bpSeries;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    const maxPts = 30;
    final slice = bpSeries.length > maxPts
        ? bpSeries.sublist(bpSeries.length - maxPts)
        : bpSeries;

    final textColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
      child: LineChart(
        LineChartData(
          minY: 55,
          maxY: 175,
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
                reservedSize: 38,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
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
                final label = s.barIndex == 0 ? 'Systolic' : 'Diastolic';
                final color = s.barIndex == 0
                    ? AppColors.secondary
                    : AppColors.primary;
                return LineTooltipItem(
                  '$label ${s.y.toStringAsFixed(0)} mmHg',
                  AppTypography.captionText
                      .copyWith(color: color, fontWeight: FontWeight.w700),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: slice.asMap().entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.value1))
                  .toList(),
              isCurved: true,
              color: AppColors.secondary,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.secondary.withOpacity(0.08),
              ),
            ),
            LineChartBarData(
              spots: slice.asMap().entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.value2))
                  .toList(),
              isCurved: true,
              color: AppColors.primary,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withOpacity(0.08),
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




