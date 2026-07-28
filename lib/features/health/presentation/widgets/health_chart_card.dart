import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';

/// Wrapper card for fl_chart charts — title, optional subtitle, and chart body.
class HealthChartCard extends StatelessWidget {
  const HealthChartCard({
    required this.title,
    required this.chart,
    super.key,
    this.subtitle,
    this.trailing,
    this.height = 180,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget chart;
  final double height;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
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
          // Header
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

// ── Line Chart ─────────────────────────────────────────────────────────────────

/// A pre-configured smooth line chart for health trend data.
///
/// Pass `values` as a list from oldest → newest.
class HealthLineChart extends StatelessWidget {
  const HealthLineChart({
    required this.values,
    required this.color,
    super.key,
    this.secondaryValues,
    this.secondaryColor,
    this.minY,
    this.maxY,
    this.showDots = false,
    this.showTooltip = true,
    this.bottomLabels,
  });

  final List<double> values;
  final Color color;
  final List<double>? secondaryValues;
  final Color? secondaryColor;
  final double? minY;
  final double? maxY;
  final bool showDots;
  final bool showTooltip;
  final List<String>? bottomLabels;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridColor = isDark
        ? AppColors.dividerDark
        : AppColors.dividerLight;

    final bars = <LineChartBarData>[
      _buildBar(values, color),
      if (secondaryValues != null && secondaryColor != null)
        _buildBar(secondaryValues!, secondaryColor!),
    ];

    return LineChart(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      LineChartData(
        minY: minY,
        maxY: maxY,
        lineBarsData: bars,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (_) => FlLine(
            color: gridColor,
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: bottomLabels != null,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (bottomLabels == null ||
                    i < 0 ||
                    i >= bottomLabels!.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    bottomLabels![i],
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
          enabled: showTooltip,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                isDark ? AppColors.surfaceDark : AppColors.white,
            getTooltipItems: (spots) => spots
                .map(
                  (s) => LineTooltipItem(
                    s.y.toStringAsFixed(0),
                    AppTypography.labelSmall.copyWith(
                      color: s.bar.color,
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

  LineChartBarData _buildBar(List<double> data, Color c) {
    return LineChartBarData(
      spots: data.asMap().entries
          .map((e) => FlSpot(e.key.toDouble(), e.value))
          .toList(),
      isCurved: true,
      curveSmoothness: 0.35,
      color: c,
      barWidth: 2.5,
      dotData: FlDotData(show: showDots),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            c.withValues(alpha: 0.18),
            c.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

// ── Bar Chart ──────────────────────────────────────────────────────────────────

/// Weekly bar chart for heart rate daily averages.
class HealthBarChart extends StatelessWidget {
  const HealthBarChart({
    required this.values,
    required this.labels,
    required this.color,
    super.key,
    this.maxY = 120,
    this.barWidth = 14,
  });

  final List<double> values;
  final List<String> labels;
  final Color color;
  final double maxY;
  final double barWidth;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BarChart(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      BarChartData(
        maxY: maxY,
        barGroups: values.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value,
                width: barWidth,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                gradient: LinearGradient(
                  colors: [
                    color,
                    color.withValues(alpha: 0.6),
                  ],
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
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[i],
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
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toStringAsFixed(0)} bpm',
                AppTypography.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
