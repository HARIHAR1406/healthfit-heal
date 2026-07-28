import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';

/// Wrapper card for analytics charts.
class FitnessChartCard extends StatelessWidget {
  const FitnessChartCard({
    required this.title,
    required this.chart,
    super.key,
    this.subtitle,
    this.trailing,
    this.height = 190,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget chart;
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
          SizedBox(height: height, child: chart),
        ],
      ),
    );
  }
}

// ── Weekly Frequency Bar Chart ────────────────────────────────────────────────

class WeeklyFrequencyChart extends StatelessWidget {
  const WeeklyFrequencyChart({
    required this.values,
    super.key,
  });

  final List<double> values;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BarChart(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      BarChartData(
        maxY: 1.5,
        barGroups: values.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value,
                width: 18,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6)),
                gradient: LinearGradient(
                  colors: e.value > 0
                      ? [AppColors.primary, AppColors.primaryDark]
                      : [
                          isDark
                              ? AppColors.dividerDark
                              : AppColors.dividerLight,
                          isDark
                              ? AppColors.dividerDark
                              : AppColors.dividerLight,
                        ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ],
          );
        }).toList(),
        gridData: FlGridData(show: false),
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
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              rod.toY > 0 ? '✓' : '—',
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

// ── Calories Trend Line Chart ─────────────────────────────────────────────────

class CaloriesTrendChart extends StatelessWidget {
  const CaloriesTrendChart({
    required this.values,
    required this.color,
    super.key,
    this.labels,
  });

  final List<double> values;
  final Color color;
  final List<String>? labels;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridColor =
        isDark ? AppColors.dividerDark : AppColors.dividerLight;

    return LineChart(
      duration: const Duration(milliseconds: 600),
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
            color: color,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 100,
          getDrawingHorizontalLine: (_) => FlLine(
            color: gridColor,
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
              showTitles: labels != null,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (labels == null ||
                    i < 0 ||
                    i >= labels!.length ||
                    i % 5 != 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels![i],
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
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                isDark ? AppColors.surfaceDark : AppColors.white,
            getTooltipItems: (spots) => spots
                .map(
                  (s) => LineTooltipItem(
                    '${s.y.toStringAsFixed(0)} kcal',
                    AppTypography.labelSmall.copyWith(
                      color: color,
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

// ── Active Minutes Bar Chart ──────────────────────────────────────────────────

class ActiveMinutesChart extends StatelessWidget {
  const ActiveMinutesChart({required this.values, super.key});
  final List<double> values;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BarChart(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      BarChartData(
        maxY: 90,
        barGroups: values.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value,
                width: 14,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(5)),
                gradient: LinearGradient(
                  colors: [AppColors.tertiary, AppColors.tertiaryDark],
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
          horizontalInterval: 30,
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
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              '${rod.toY.toStringAsFixed(0)} min',
              AppTypography.labelSmall.copyWith(
                color: AppColors.tertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
