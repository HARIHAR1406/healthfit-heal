import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';

// ── Chart Card Wrapper ────────────────────────────────────────────────────────

class NutritionChartCard extends StatelessWidget {
  const NutritionChartCard({
    required this.title,
    required this.child,
    super.key,
    this.subtitle,
    this.trailing,
    this.height = 200,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: AppSpacing.borderThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleSmall.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }
}

// ── Calories Bar Chart ────────────────────────────────────────────────────────

class CaloriesBarChart extends StatelessWidget {
  const CaloriesBarChart({
    required this.values,
    required this.goal,
    super.key,
    this.labels,
  });

  final List<double> values;
  final double goal;
  final List<String>? labels;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BarChart(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      BarChartData(
        maxY: (goal * 1.3).ceilToDouble(),
        barGroups: values.asMap().entries.map((e) {
          final overGoal = e.value > goal;
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value,
                width: 16,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6)),
                gradient: LinearGradient(
                  colors: overGoal
                      ? [AppColors.error, AppColors.error.withOpacity(0.7)]
                      : [AppColors.chartCoral, AppColors.chartCoral.withOpacity(0.7)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ],
          );
        }).toList(),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: goal,
              color: AppColors.primary.withOpacity(0.5),
              strokeWidth: 1.5,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                labelResolver: (_) => 'Goal',
                style: AppTypography.overline.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 500,
          getDrawingHorizontalLine: (_) => FlLine(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                final labelList = labels ?? _days;
                if (i < 0 || i >= labelList.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labelList[i],
                    style: AppTypography.overline.copyWith(
                      color: isDark
                          ? AppColors.textHintDark
                          : AppColors.textHintLight,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) =>
                isDark ? AppColors.surfaceDark : AppColors.white,
            getTooltipItem: (_, __, rod, ___) => BarTooltipItem(
              '${rod.toY.toStringAsFixed(0)} kcal',
              AppTypography.labelSmall.copyWith(
                color: AppColors.chartCoral,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Macro Pie Chart ───────────────────────────────────────────────────────────

class MacroPieChart extends StatelessWidget {
  const MacroPieChart({
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    super.key,
  });

  final double proteinG;
  final double carbsG;
  final double fatG;

  @override
  Widget build(BuildContext context) {
    final total = proteinG + carbsG + fatG;
    if (total == 0) {
      return const Center(child: Text('No data'));
    }

    return Row(
      children: [
        // Pie
        Expanded(
          child: PieChart(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 36,
              sections: [
                PieChartSectionData(
                  value: proteinG,
                  color: AppColors.chartIndigo,
                  radius: 36,
                  title: '',
                ),
                PieChartSectionData(
                  value: carbsG,
                  color: AppColors.chartAmber,
                  radius: 36,
                  title: '',
                ),
                PieChartSectionData(
                  value: fatG,
                  color: AppColors.chartCoral,
                  radius: 36,
                  title: '',
                ),
              ],
            ),
          ),
        ),

        // Legend
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PieLegend(
              color: AppColors.chartIndigo,
              label: 'Protein',
              value: proteinG,
              percent: (proteinG / total * 100).round(),
            ),
            const SizedBox(height: AppSpacing.sm),
            _PieLegend(
              color: AppColors.chartAmber,
              label: 'Carbs',
              value: carbsG,
              percent: (carbsG / total * 100).round(),
            ),
            const SizedBox(height: AppSpacing.sm),
            _PieLegend(
              color: AppColors.chartCoral,
              label: 'Fat',
              value: fatG,
              percent: (fatG / total * 100).round(),
            ),
          ],
        ),
      ],
    );
  }
}

class _PieLegend extends StatelessWidget {
  const _PieLegend({
    required this.color,
    required this.label,
    required this.value,
    required this.percent,
  });
  final Color color;
  final String label;
  final double value;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.captionText.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            Text(
              '${value.toStringAsFixed(0)}g ($percent%)',
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Water Intake Bar Chart ────────────────────────────────────────────────────

class WaterIntakeChart extends StatelessWidget {
  const WaterIntakeChart({required this.values, super.key});
  final List<double> values;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BarChart(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      BarChartData(
        maxY: 3000,
        barGroups: values.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value,
                width: 16,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6)),
                gradient: LinearGradient(
                  colors: [
                    AppColors.chartSky,
                    AppColors.chartSky.withOpacity(0.6)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ],
          );
        }).toList(),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 2500,
              color: AppColors.primary.withOpacity(0.4),
              strokeWidth: 1.5,
              dashArray: [6, 4],
            ),
          ],
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 500,
          getDrawingHorizontalLine: (_) => FlLine(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= _days.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _days[i],
                    style: AppTypography.overline.copyWith(
                      color: isDark
                          ? AppColors.textHintDark
                          : AppColors.textHintLight,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) =>
                isDark ? AppColors.surfaceDark : AppColors.white,
            getTooltipItem: (_, __, rod, ___) => BarTooltipItem(
              '${(rod.toY / 1000).toStringAsFixed(1)} L',
              AppTypography.labelSmall.copyWith(
                color: AppColors.chartSky,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Weight Progress Line Chart ────────────────────────────────────────────────

class WeightProgressChart extends StatelessWidget {
  const WeightProgressChart({
    required this.values,
    required this.goalKg,
    super.key,
  });

  final List<double> values;
  final double goalKg;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final minY = (values.reduce((a, b) => a < b ? a : b) - 2).floorToDouble();
    final maxY = (values.reduce((a, b) => a > b ? a : b) + 2).ceilToDouble();

    return LineChart(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: values
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value))
                .toList(),
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppColors.primary,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 3,
                color: AppColors.primary,
                strokeWidth: 2,
                strokeColor: isDark
                    ? AppColors.backgroundDark
                    : AppColors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.2),
                  AppColors.primary.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: goalKg,
              color: AppColors.success.withOpacity(0.5),
              strokeWidth: 1.5,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                labelResolver: (_) => 'Goal ${goalKg.toStringAsFixed(1)} kg',
                style: AppTypography.overline.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, _) => Text(
                '${value.toStringAsFixed(0)} kg',
                style: AppTypography.overline.copyWith(
                  color: isDark
                      ? AppColors.textHintDark
                      : AppColors.textHintLight,
                  fontSize: 9,
                ),
              ),
            ),
          ),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                isDark ? AppColors.surfaceDark : AppColors.white,
            getTooltipItems: (spots) => spots
                .map(
                  (s) => LineTooltipItem(
                    '${s.y.toStringAsFixed(1)} kg',
                    AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

// ── Nutrition Score Bar Chart ─────────────────────────────────────────────────

class NutritionScoreChart extends StatelessWidget {
  const NutritionScoreChart({required this.scores, super.key});
  final List<int> scores;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BarChart(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      BarChartData(
        maxY: 100,
        barGroups: scores.asMap().entries.map((e) {
          final color = e.value >= 80
              ? AppColors.success
              : e.value >= 60
                  ? AppColors.chartAmber
                  : AppColors.chartCoral;
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.toDouble(),
                width: 16,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6)),
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ],
          );
        }).toList(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (_) => FlLine(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= _days.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _days[i],
                    style: AppTypography.overline.copyWith(
                      color: isDark
                          ? AppColors.textHintDark
                          : AppColors.textHintLight,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) =>
                isDark ? AppColors.surfaceDark : AppColors.white,
            getTooltipItem: (_, __, rod, ___) => BarTooltipItem(
              '${rod.toY.toStringAsFixed(0)}/100',
              AppTypography.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
