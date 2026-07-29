import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/health_report_entity.dart' show DataPoint;
import '../../domain/entities/nutrition_report_entity.dart';
import '../providers/reports_providers.dart';
import '../providers/reports_state.dart';
import '../widgets/chart_card.dart';
import '../widgets/report_filter_bar.dart';
import '../widgets/summary_card.dart';

// ══════════════════════════════════════════════════════════════════════════════
// NUTRITION ANALYTICS REPORT PAGE
// ══════════════════════════════════════════════════════════════════════════════

class NutritionAnalyticsReportPage extends ConsumerStatefulWidget {
  const NutritionAnalyticsReportPage({super.key});

  @override
  ConsumerState<NutritionAnalyticsReportPage> createState() =>
      _NutritionAnalyticsReportPageState();
}

class _NutritionAnalyticsReportPageState
    extends ConsumerState<NutritionAnalyticsReportPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final filter = ref.read(analyticsFilterProvider);
    ref.read(nutritionReportProvider.notifier).load(filter);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(nutritionReportProvider);

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
              NutritionReportInitial() ||
              NutritionReportLoading() =>
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              NutritionReportError(:final message) => Center(
                  child: Text(message,
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.error))),
              NutritionReportLoaded(:final report) =>
                _NutritionBody(report: report, isDark: isDark),
            },
          ),
        ],
      ),
    );
  }
}

class _NutritionBody extends StatelessWidget {
  const _NutritionBody({required this.report, required this.isDark});
  final NutritionReportEntity report;
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
              title: 'Avg Daily Calories',
              value: report.avgDailyCalories,
              unit: 'kcal',
              icon: Icons.local_fire_department_rounded,
              color: AppColors.warning,
              isDark: isDark,
              delta: report.caloriesDelta,
            ),
            SummaryCard(
              title: 'Avg Water',
              value: report.avgWaterMl / 1000,
              unit: 'L/day',
              icon: Icons.water_drop_rounded,
              color: kWaterColor,
              isDark: isDark,
              delta: report.waterDelta / 1000,
              formatValue: (v) => v.toStringAsFixed(1),
            ),
            SummaryCard(
              title: 'Nutrition Score',
              value: report.nutritionScore,
              unit: '/ 100',
              icon: Icons.stars_rounded,
              color: AppColors.primary,
              isDark: isDark,
              delta: report.nutritionScoreDelta,
            ),
            SummaryCard(
              title: 'Days Logged',
              value: report.daysLogged.toDouble(),
              unit: 'days',
              icon: Icons.calendar_today_rounded,
              color: AppColors.tertiary,
              isDark: isDark,
              delta: null,
              subtitle:
                  '${(report.loggingConsistencyPct * 100).toStringAsFixed(0)}% consistent',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Macro Donut
        ChartCard(
          title: 'Macronutrient Breakdown',
          subtitle:
              'P ${report.macroAvg.proteinG.toStringAsFixed(0)}g · '
              'C ${report.macroAvg.carbsG.toStringAsFixed(0)}g · '
              'F ${report.macroAvg.fatG.toStringAsFixed(0)}g',
          isDark: isDark,
          height: 230,
          child: _MacroDonutChart(macro: report.macroAvg, isDark: isDark),
        ),
        const SizedBox(height: AppSpacing.md),

        // Calorie Area Chart
        ChartCard(
          title: 'Calorie Intake',
          subtitle:
              'Target ${report.targetCalories.toStringAsFixed(0)} kcal/day',
          isDark: isDark,
          height: 220,
          legend: const [
            LegendItem(label: 'Calories', color: AppColors.warning),
          ],
          child: _CalorieAreaChart(
            series: report.calorieSeries,
            target: report.targetCalories,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Water Area Chart
        ChartCard(
          title: 'Water Intake',
          subtitle:
              'Target ${(report.waterTargetMl / 1000).toStringAsFixed(1)} L/day',
          isDark: isDark,
          height: 200,
          legend: const [
            LegendItem(label: 'Water (mL)', color: kWaterColor),
          ],
          child: _SimpleAreaChart(
            series: report.waterSeries,
            color: kWaterColor,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Macro Stacked Bar (weekly)
        ChartCard(
          title: 'Macro Trends',
          subtitle: 'Protein · Carbs · Fat — daily averages',
          isDark: isDark,
          height: 220,
          legend: const [
            LegendItem(label: 'Protein', color: kProteinColor),
            LegendItem(label: 'Carbs', color: kCarbsColor),
            LegendItem(label: 'Fat', color: kFatColor),
          ],
          child: _MacroStackedChart(
            protein: report.proteinSeries,
            carbs: report.carbsSeries,
            fat: report.fatSeries,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Meal Consistency Heat Map
        ChartCard(
          title: 'Meal Consistency',
          subtitle: 'Logged vs. missed meals per day',
          isDark: isDark,
          height: 160,
          child: _MealConsistencyChart(
            records: report.mealConsistency,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: AppSpacing.massive),
      ],
    );
  }
}

// ── Macro Donut ───────────────────────────────────────────────────────────────

class _MacroDonutChart extends StatefulWidget {
  const _MacroDonutChart({required this.macro, required this.isDark});
  final MacroBreakdown macro;
  final bool isDark;

  @override
  State<_MacroDonutChart> createState() => _MacroDonutChartState();
}

class _MacroDonutChartState extends State<_MacroDonutChart> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final m = widget.macro;
    final slices = [
      ('Protein', m.proteinPct, m.proteinG, kProteinColor),
      ('Carbs', m.carbsPct, m.carbsG, kCarbsColor),
      ('Fat', m.fatPct, m.fatG, kFatColor),
    ];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: slices.asMap().entries.map((e) {
                  final i = e.key;
                  final (name, pct, _, color) = e.value;
                  final isTouched = i == _touched;
                  return PieChartSectionData(
                    color: color,
                    value: pct,
                    title:
                        isTouched ? '${(pct * 100).toStringAsFixed(0)}%' : '',
                    radius: isTouched ? 78 : 65,
                    titleStyle: AppTypography.captionText.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList(),
                sectionsSpace: 3,
                centerSpaceRadius: 42,
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
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: slices.map((s) {
              final (name, pct, grams, color) = s;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: AppTypography.captionText.copyWith(
                              color: widget.isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                              fontSize: 11,
                            )),
                        Text(
                          '${grams.toStringAsFixed(0)}g · ${(pct * 100).toStringAsFixed(0)}%',
                          style: AppTypography.captionText.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
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

// ── Calorie Area Chart (with target line) ─────────────────────────────────────

class _CalorieAreaChart extends StatelessWidget {
  const _CalorieAreaChart({
    required this.series,
    required this.target,
    required this.isDark,
  });
  final List<DataPoint> series;
  final double target;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    const maxPts = 30;
    final slice = series.length > maxPts
        ? series.sublist(series.length - maxPts)
        : series;

    double minY =
        (slice.fold(double.infinity, (m, p) => p.value < m ? p.value : m) -
                200)
            .floorToDouble();
    double maxY =
        (slice.fold(0.0, (m, p) => p.value > m ? p.value : m) + 200)
            .ceilToDouble();

    final textColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: target,
                color: AppColors.primary.withValues(alpha: 0.5),
                strokeWidth: 1.5,
                dashArray: [6, 4],
                label: HorizontalLineLabel(
                  show: true,
                  style: AppTypography.captionText.copyWith(
                    color: AppColors.primary,
                    fontSize: 10,
                  ),
                  labelResolver: (_) => 'Target',
                  alignment: Alignment.topRight,
                ),
              ),
            ],
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: (isDark ? Colors.white : Colors.grey)
                  .withValues(alpha: 0.08),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}',
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
          lineBarsData: [
            LineChartBarData(
              spots: slice.asMap().entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                  .toList(),
              isCurved: true,
              color: AppColors.warning,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.warning.withValues(alpha: 0.25),
                    AppColors.warning.withValues(alpha: 0.02),
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

// ── Simple Area Chart ─────────────────────────────────────────────────────────

class _SimpleAreaChart extends StatelessWidget {
  const _SimpleAreaChart(
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

    double minY =
        slice.fold(double.infinity, (m, p) => p.value < m ? p.value : m) *
            0.85;
    double maxY =
        slice.fold(0.0, (m, p) => p.value > m ? p.value : m) * 1.1;

    final textColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
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
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
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

// ── Macro Stacked Bar Chart ───────────────────────────────────────────────────

class _MacroStackedChart extends StatelessWidget {
  const _MacroStackedChart({
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.isDark,
  });
  final List<DataPoint> protein;
  final List<DataPoint> carbs;
  final List<DataPoint> fat;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Downsample to weekly averages for readability
    const weeks = 8;
    final pLen = protein.length;
    List<(double, double, double)> weeklyData = [];
    for (var w = weeks - 1; w >= 0; w--) {
      final start = pLen - (w + 1) * 7;
      final end = start + 7;
      if (start < 0) continue;
      double avgProt = 0, avgCarb = 0, avgFat = 0;
      int count = 0;
      for (var i = start.clamp(0, pLen); i < end.clamp(0, pLen); i++) {
        avgProt += protein[i].value;
        avgCarb += carbs[i].value;
        avgFat += fat[i].value;
        count++;
      }
      if (count == 0) continue;
      weeklyData
          .add((avgProt / count, avgCarb / count, avgFat / count));
    }

    if (weeklyData.isEmpty) return const Center(child: Text('No data'));

    final textColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xs, AppSpacing.md, AppSpacing.xs, AppSpacing.sm),
      child: BarChart(
        BarChartData(
          maxY: weeklyData.fold(
              0.0,
              (m, w) =>
                  w.$1 + w.$2 + w.$3 > m ? w.$1 + w.$2 + w.$3 : m) *
              1.1,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: (isDark ? Colors.white : Colors.grey)
                  .withValues(alpha: 0.08),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'W${idx + 1}',
                      style: AppTypography.captionText
                          .copyWith(color: textColor, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: AppTypography.captionText
                      .copyWith(color: textColor, fontSize: 9),
                ),
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: weeklyData.asMap().entries.map((e) {
            final (p, c, f) = e.value;
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: p + c + f,
                  rodStackItems: [
                    BarChartRodStackItem(0, p, kProteinColor),
                    BarChartRodStackItem(p, p + c, kCarbsColor),
                    BarChartRodStackItem(p + c, p + c + f, kFatColor),
                  ],
                  width: 22,
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

// ── Meal Consistency Chart ────────────────────────────────────────────────────

class _MealConsistencyChart extends StatelessWidget {
  const _MealConsistencyChart(
      {required this.records, required this.isDark});
  final List<MealConsistencyRecord> records;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Show last 14 days as coloured dots
    final recent = records.length > 14
        ? records.sublist(records.length - 14)
        : records;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          // Header labels
          Row(
            children: [
              const SizedBox(width: 56),
              ...['B', 'L', 'D', 'S'].map((m) => Expanded(
                    child: Center(
                      child: Text(
                        m,
                        style: AppTypography.captionText.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recent.length,
              itemBuilder: (_, i) {
                final r = recent[i];
                return Row(
                  children: [
                    SizedBox(
                      width: 56,
                      child: Text(
                        DateFormat('d/M').format(r.date),
                        style: AppTypography.captionText.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    ...[r.breakfast, r.lunch, r.dinner, r.snacks]
                        .map((logged) => Expanded(
                              child: Center(
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: logged
                                        ? AppColors.primary
                                        : AppColors.error
                                            .withValues(alpha: 0.25),
                                  ),
                                ),
                              ),
                            )),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
