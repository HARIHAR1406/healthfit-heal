import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/achievement_statistics_entity.dart';
import '../../domain/entities/comparison_data_entity.dart';
import '../../domain/entities/health_insight_entity.dart';
import '../../domain/entities/health_report_entity.dart';
import '../../domain/entities/trend_data_entity.dart';
import '../../domain/entities/report_filter.dart';

// ══════════════════════════════════════════════════════════════════════════════
// INSIGHT CARD
// ══════════════════════════════════════════════════════════════════════════════

/// Full-width card displaying a single AI-generated health insight.
/// Tap to expand detail text. Mark-read badge auto-appears on unread.
class InsightCard extends StatefulWidget {
  const InsightCard({
    required this.insight,
    required this.isDark,
    super.key,
    this.onMarkRead,
    this.onActionTap,
  });

  final HealthInsightEntity insight;
  final bool isDark;
  final VoidCallback? onMarkRead;
  final VoidCallback? onActionTap;

  @override
  State<InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<InsightCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _ctrl;
  late Animation<double> _expand;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
    _expand = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
    if (_expanded && !widget.insight.isRead) {
      widget.onMarkRead?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ins = widget.insight;
    final catColor = ins.category.color;
    final bg = widget.isDark ? const Color(0xFF1A1F3A) : Colors.white;

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: _expanded
                ? catColor.withOpacity(0.4)
                : (widget.isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.grey.withOpacity(0.1)),
            width: _expanded ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(widget.isDark ? 0.18 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category icon
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(ins.category.icon, color: catColor, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Priority + unread badge row
                        Row(
                          children: [
                            _PriorityChip(priority: ins.priority),
                            const Spacer(),
                            if (!ins.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: ins.priority.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ins.title,
                          style: AppTypography.bodyMedium.copyWith(
                            color: widget.isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ins.summary,
                          style: AppTypography.bodySmall.copyWith(
                            color: widget.isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                          maxLines: _expanded ? 10 : 2,
                          overflow: _expanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 0.5).animate(_expand),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: widget.isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),

            // ── Expanded detail ────────────────────────────────────────────
            SizeTransition(
              sizeFactor: _expand,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ins.detail,
                          style: AppTypography.bodySmall.copyWith(
                            color: widget.isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            height: 1.5,
                          ),
                        ),
                        if (ins.relatedMetricValue != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _MetricChip(
                            value: ins.relatedMetricValue!,
                            unit: ins.relatedMetricUnit ?? '',
                            delta: ins.relatedMetricDelta,
                            isDark: widget.isDark,
                          ),
                        ],
                        if (ins.confidence != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          _ConfidenceBar(
                            confidence: ins.confidence!,
                            isDark: widget.isDark,
                          ),
                        ],
                        if (ins.actionLabel != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          TextButton.icon(
                            onPressed: widget.onActionTap,
                            icon: const Icon(Icons.open_in_new_rounded,
                                size: 14),
                            label: Text(ins.actionLabel!),
                            style: TextButton.styleFrom(
                              foregroundColor: catColor,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm, vertical: 4),
                              textStyle: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});
  final InsightPriority priority;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: priority.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        priority.label,
        style: AppTypography.captionText.copyWith(
          color: priority.color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.value,
    required this.unit,
    required this.isDark,
    this.delta,
  });
  final double value;
  final String unit;
  final double? delta;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final deltaPositive = delta == null || delta! >= 0;
    final deltaColor = deltaPositive ? AppColors.secondary : AppColors.error;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.grey.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)} $unit',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ),
        if (delta != null) ...[
          const SizedBox(width: 6),
          Icon(
            deltaPositive
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 14,
            color: deltaColor,
          ),
          Text(
            '${delta!.abs().toStringAsFixed(1)} $unit',
            style: AppTypography.captionText.copyWith(color: deltaColor),
          ),
        ],
      ],
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  const _ConfidenceBar({required this.confidence, required this.isDark});
  final double confidence;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).round();
    return Row(
      children: [
        Text(
          'AI Confidence: $pct%',
          style: AppTypography.captionText.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: confidence,
              backgroundColor:
                  isDark ? Colors.white12 : Colors.grey.shade200,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 4,
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TREND CARD
// ══════════════════════════════════════════════════════════════════════════════

/// Compact card showing one metric's trend direction, change%, and sparkline.
class TrendCard extends StatelessWidget {
  const TrendCard({
    required this.trend,
    required this.isDark,
    super.key,
    this.onTap,
  });

  final TrendDataEntity trend;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dir = trend.direction;
    final dirColor = dir == TrendDirection.improving
        ? AppColors.secondary
        : dir == TrendDirection.declining
            ? AppColors.error
            : AppColors.warning;
    final dirIcon = dir == TrendDirection.improving
        ? Icons.trending_up_rounded
        : dir == TrendDirection.declining
            ? Icons.trending_down_rounded
            : Icons.trending_flat_rounded;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.grey.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(isDark ? 0.15 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Direction badge + label ─────────────────────────────────
            Row(
              children: [
                Icon(dirIcon, color: dirColor, size: 18),
                const SizedBox(width: 4),
                Text(
                  dir.label,
                  style: AppTypography.captionText.copyWith(
                    color: dirColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                if (trend.riskLevel != null)
                  _RiskBadge(risk: trend.riskLevel!),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              trend.metric.label,
              style: AppTypography.titleSmall.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  trend.currentAvg.toStringAsFixed(
                      trend.currentAvg < 10 ? 1 : 0),
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    trend.metric.unit,
                    style: AppTypography.captionText.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
                const Spacer(),
                _ChangePill(
                  changePercent: trend.changePercent,
                  direction: dir,
                ),
              ],
            ),
            if (trend.series.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 48,
                child: _SparkLine(
                  series: trend.series,
                  color: dirColor,
                  isDark: isDark,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.risk});
  final String risk;

  @override
  Widget build(BuildContext context) {
    final color = risk == 'high'
        ? AppColors.error
        : risk == 'medium'
            ? AppColors.warning
            : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '⚠ $risk risk',
        style: AppTypography.captionText.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _ChangePill extends StatelessWidget {
  const _ChangePill({required this.changePercent, required this.direction});
  final double changePercent;
  final TrendDirection direction;

  @override
  Widget build(BuildContext context) {
    final isUp = changePercent >= 0;
    final color = direction == TrendDirection.improving
        ? AppColors.secondary
        : direction == TrendDirection.declining
            ? AppColors.error
            : AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '${changePercent.abs().toStringAsFixed(1)}%',
            style: AppTypography.captionText.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SparkLine extends StatelessWidget {
  const _SparkLine({
    required this.series,
    required this.color,
    required this.isDark,
  });
  final List<DataPoint> series;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) return const SizedBox.shrink();

    final spots = series.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (series.length - 1).toDouble(),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withOpacity(0.25),
                  color.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// COMPARISON CARD
// ══════════════════════════════════════════════════════════════════════════════

/// Displays a single metric comparison between current and previous period.
class ComparisonCard extends StatelessWidget {
  const ComparisonCard({
    required this.comparison,
    required this.isDark,
    super.key,
  });

  final MetricComparison comparison;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final improved = comparison.improved;
    final dirColor =
        improved ? AppColors.secondary : AppColors.error;
    final bg = isDark ? const Color(0xFF1A1F3A) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Label + change badge ──────────────────────────────────────
          Row(
            children: [
              Text(
                comparison.label,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _ChangePill(
                changePercent: comparison.changePercent,
                direction: improved
                    ? TrendDirection.improving
                    : TrendDirection.declining,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── Current vs Previous ─────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _PeriodValue(
                  label: 'Current',
                  value: comparison.currentValue,
                  unit: comparison.unit,
                  isDark: isDark,
                  isCurrent: true,
                  improved: improved,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: dirColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  improved
                      ? Icons.arrow_forward_rounded
                      : Icons.arrow_forward_rounded,
                  size: 14,
                  color: dirColor,
                ),
              ),
              Expanded(
                child: _PeriodValue(
                  label: 'Previous',
                  value: comparison.previousValue,
                  unit: comparison.unit,
                  isDark: isDark,
                  isCurrent: false,
                  improved: improved,
                ),
              ),
            ],
          ),

          // ── Overlay mini-chart ─────────────────────────────────────
          if (comparison.currentSeries.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 40,
              child: _OverlaySparkLine(
                current: comparison.currentSeries,
                previous: comparison.previousSeries,
                isDark: isDark,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PeriodValue extends StatelessWidget {
  const _PeriodValue({
    required this.label,
    required this.value,
    required this.unit,
    required this.isDark,
    required this.isCurrent,
    required this.improved,
  });
  final String label;
  final double value;
  final String unit;
  final bool isDark;
  final bool isCurrent;
  final bool improved;

  @override
  Widget build(BuildContext context) {
    final highlight = isCurrent && improved;
    final color = highlight
        ? AppColors.secondary
        : isDark
            ? AppColors.textPrimaryDark
            : AppColors.textPrimaryLight;

    return Column(
      crossAxisAlignment:
          isCurrent ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: AppTypography.captionText.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${value.toStringAsFixed(value < 10 ? 1 : 0)} $unit',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _OverlaySparkLine extends StatelessWidget {
  const _OverlaySparkLine({
    required this.current,
    required this.previous,
    required this.isDark,
  });
  final List<DataPoint> current;
  final List<DataPoint> previous;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    LineChartBarData _bar(List<DataPoint> s, Color c, bool solid) {
      final spots = s.asMap().entries
          .map((e) => FlSpot(e.key.toDouble(), e.value.value))
          .toList();
      return LineChartBarData(
        spots: spots,
        isCurved: true,
        color: c.withOpacity(solid ? 1.0 : 0.4),
        barWidth: solid ? 2 : 1.5,
        dashArray: solid ? null : [4, 4],
        dotData: const FlDotData(show: false),
      );
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          _bar(current, AppColors.primary, true),
          _bar(previous, AppColors.secondary, false),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ACHIEVEMENT CARD
// ══════════════════════════════════════════════════════════════════════════════

/// Compact card for a single achievement entry.
class AchievementCard extends StatelessWidget {
  const AchievementCard({
    required this.achievement,
    required this.isDark,
    super.key,
  });

  final AchievementEntry achievement;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final tierColor =
        Color(achievement.tier.colorValue).withOpacity(1.0);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: achievement.isNew
              ? tierColor.withOpacity(0.4)
              : isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.grey.withOpacity(0.1),
          width: achievement.isNew ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          // ── Emoji ring ────────────────────────────────────────────────
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      tierColor.withOpacity(0.2),
                      tierColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: tierColor, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    achievement.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              if (achievement.isNew)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: tierColor,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // ── Tier pill ────────────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: tierColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              achievement.tier.label,
              style: AppTypography.captionText.copyWith(
                color: tierColor,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 4),

          Text(
            achievement.title,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// GOAL STATS CARD
// ══════════════════════════════════════════════════════════════════════════════

/// Progress card for a single goal type.
class GoalStatsCard extends StatelessWidget {
  const GoalStatsCard({
    required this.goal,
    required this.isDark,
    super.key,
  });

  final GoalStats goal;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final rate = goal.completionRate.clamp(0.0, 1.0);
    final color = goal.isOnTrack ? AppColors.secondary : AppColors.warning;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.withOpacity(0.1),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                goal.emoji,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  goal.label,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ),
              Text(
                '${(rate * 100).round()}%',
                style: AppTypography.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: rate),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                backgroundColor:
                    isDark ? Colors.white12 : Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${goal.completedCount}/${goal.targetCount}  ·  🔥 ${goal.streak} day streak',
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

// ══════════════════════════════════════════════════════════════════════════════
// FILTER BOTTOM SHEET
// ══════════════════════════════════════════════════════════════════════════════

/// Reusable analytics filter bottom sheet supporting date range selection.
class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({
    required this.currentFilter,
    required this.onApply,
    super.key,
  });

  final ActiveFilter currentFilter;
  final ValueChanged<ActiveFilter> onApply;

  static Future<void> show(
    BuildContext context, {
    required ActiveFilter currentFilter,
    required ValueChanged<ActiveFilter> onApply,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => FilterBottomSheet(
          currentFilter: currentFilter,
          onApply: onApply,
        ),
      );

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late ActiveFilter _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentFilter;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1F3A) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXxl)),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ────────────────────────────────────────────────────
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            'Select Time Range',
            style: AppTypography.titleMedium.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Filter options ────────────────────────────────────────────
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: DateFilter.values.map((f) {
              final active = _selected.filter == f;
              return ChoiceChip(
                label: Text(f.label),
                selected: active,
                onSelected: (_) => setState(
                  () => _selected = ActiveFilter(filter: f),
                ),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: active ? Colors.white : null,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Apply button ──────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onApply(_selected);
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
              child: Text(
                'Apply Filter',
                style: AppTypography.bodyMedium
                    .copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WEEKLY HEATMAP WIDGET
// ══════════════════════════════════════════════════════════════════════════════

/// A 7-column × N-row calendar heatmap (similar to GitHub contribution graph).
/// Each cell represents one day; color intensity encodes the [value].
class WeeklyHeatMap extends StatelessWidget {
  const WeeklyHeatMap({
    required this.data,
    required this.isDark,
    required this.maxValue,
    super.key,
    this.color = AppColors.primary,
    this.cellSize = 14,
    this.cellGap = 3,
  });

  /// Map of date → value (e.g., steps, calories, workout minutes).
  final Map<DateTime, double> data;
  final bool isDark;
  final double maxValue;
  final Color color;
  final double cellSize;
  final double cellGap;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data'));
    }

    // Build a 7-col grid from dates
    final sorted = data.keys.toList()..sort();
    final firstDay = sorted.first;

    // Pad to start of week (Monday)
    final startOffset = (firstDay.weekday - 1) % 7;
    final cells = <_HeatCell>[];

    // Padding cells
    for (int i = 0; i < startOffset; i++) {
      cells.add(const _HeatCell(value: null, date: null));
    }
    for (final date in sorted) {
      cells.add(_HeatCell(
        value: data[date],
        date: date,
        maxValue: maxValue,
      ));
    }

    // Pad to complete last row
    final remainder = cells.length % 7;
    if (remainder != 0) {
      for (int i = 0; i < 7 - remainder; i++) {
        cells.add(const _HeatCell(value: null, date: null));
      }
    }

    final weeks = cells.length ~/ 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Day labels ───────────────────────────────────────────────
        Row(
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) {
            return SizedBox(
              width: cellSize + cellGap,
              child: Text(
                d,
                style: AppTypography.captionText.copyWith(
                  fontSize: 9,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),

        // ── Grid ──────────────────────────────────────────────────────
        SizedBox(
          height: weeks * (cellSize + cellGap),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: cellGap,
              crossAxisSpacing: cellGap,
            ),
            itemCount: cells.length,
            itemBuilder: (_, i) {
              final cell = cells[i];
              return _HeatCellWidget(
                cell: cell,
                color: color,
                isDark: isDark,
                size: cellSize,
              );
            },
          ),
        ),

        // ── Legend ────────────────────────────────────────────────────
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              'Less',
              style: AppTypography.captionText.copyWith(fontSize: 10),
            ),
            const SizedBox(width: 4),
            ...List.generate(5, (i) {
              return Container(
                width: cellSize,
                height: cellSize,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1 + i * 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
            const SizedBox(width: 4),
            Text(
              'More',
              style: AppTypography.captionText.copyWith(fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeatCell {
  const _HeatCell({
    required this.value,
    required this.date,
    this.maxValue = 1,
  });
  final double? value;
  final DateTime? date;
  final double maxValue;
}

class _HeatCellWidget extends StatelessWidget {
  const _HeatCellWidget({
    required this.cell,
    required this.color,
    required this.isDark,
    required this.size,
  });
  final _HeatCell cell;
  final Color color;
  final bool isDark;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (cell.value == null) {
      return Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.03)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }
    final intensity =
        cell.maxValue > 0 ? (cell.value! / cell.maxValue).clamp(0.05, 1.0) : 0.0;

    return Tooltip(
      message: cell.date != null
          ? '${cell.date!.day}/${cell.date!.month}: ${cell.value!.toStringAsFixed(0)}'
          : '',
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(intensity),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CUSTOM RADAR CHART
// ══════════════════════════════════════════════════════════════════════════════

/// Pure-Flutter radar/spider chart using CustomPainter.
/// Renders [axes] labels with [values] (0.0–1.0 each).
class RadarChartWidget extends StatelessWidget {
  const RadarChartWidget({
    required this.axes,
    required this.values,
    required this.isDark,
    super.key,
    this.color = AppColors.primary,
    this.gridColor,
    this.size = 200,
  });

  final List<String> axes;
  final List<double> values;
  final bool isDark;
  final Color color;
  final Color? gridColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    assert(axes.length == values.length,
        'axes and values must have the same length');

    final gColor = gridColor ??
        (isDark
            ? Colors.white.withOpacity(0.12)
            : Colors.grey.withOpacity(0.2));

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RadarPainter(
          axes: axes,
          values: values,
          fillColor: color.withOpacity(0.2),
          strokeColor: color,
          gridColor: gColor,
          labelColor: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.axes,
    required this.values,
    required this.fillColor,
    required this.strokeColor,
    required this.gridColor,
    required this.labelColor,
  });

  final List<String> axes;
  final List<double> values;
  final Color fillColor;
  final Color strokeColor;
  final Color gridColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    final n = axes.length;
    if (n < 3) return;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = math.min(cx, cy) - 28; // leave margin for labels

    final angleStep = (2 * math.pi) / n;
    const rings = 4;

    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;

    // Draw grid rings
    for (int r = 1; r <= rings; r++) {
      final ringRadius = radius * r / rings;
      final path = Path();
      for (int i = 0; i < n; i++) {
        final angle = -math.pi / 2 + angleStep * i;
        final x = cx + ringRadius * math.cos(angle);
        final y = cy + ringRadius * math.sin(angle);
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Draw spokes
    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + angleStep * i;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + radius * math.cos(angle), cy + radius * math.sin(angle)),
        gridPaint,
      );
    }

    // Draw data polygon
    final dataPath = Path();
    for (int i = 0; i < n; i++) {
      final val = values[i].clamp(0.0, 1.0);
      final angle = -math.pi / 2 + angleStep * i;
      final r = radius * val;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      i == 0 ? dataPath.moveTo(x, y) : dataPath.lineTo(x, y);
    }
    dataPath.close();
    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, strokePaint);

    // Draw dots
    final dotPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;
    for (int i = 0; i < n; i++) {
      final val = values[i].clamp(0.0, 1.0);
      final angle = -math.pi / 2 + angleStep * i;
      final r = radius * val;
      canvas.drawCircle(
        Offset(cx + r * math.cos(angle), cy + r * math.sin(angle)),
        3.5,
        dotPaint,
      );
    }

    // Draw labels
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + angleStep * i;
      final labelRadius = radius + 18;
      final lx = cx + labelRadius * math.cos(angle);
      final ly = cy + labelRadius * math.sin(angle);

      tp.text = TextSpan(
        text: axes[i],
        style: TextStyle(
          color: labelColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
      tp.layout();
      canvas.save();
      canvas.translate(lx - tp.width / 2, ly - tp.height / 2);
      tp.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_RadarPainter oldDelegate) =>
      oldDelegate.values != values;
}

// ══════════════════════════════════════════════════════════════════════════════
// STATISTICS TILE (reusable single-value row)
// ══════════════════════════════════════════════════════════════════════════════

class StatisticsTile extends StatelessWidget {
  const StatisticsTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.isDark,
    super.key,
    this.icon,
    this.iconColor,
    this.delta,
    this.positiveIsGood = true,
  });

  final String label;
  final String value;
  final String unit;
  final bool isDark;
  final IconData? icon;
  final Color? iconColor;
  final double? delta;
  final bool positiveIsGood;

  @override
  Widget build(BuildContext context) {
    Color? deltaColor;
    if (delta != null) {
      final positive = delta! >= 0;
      deltaColor = (positive == positiveIsGood)
          ? AppColors.secondary
          : AppColors.error;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs, horizontal: AppSpacing.md),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: iconColor ?? AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          Text(
            '$value $unit',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          if (delta != null) ...[
            const SizedBox(width: 6),
            Icon(
              delta! >= 0
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 12,
              color: deltaColor,
            ),
            Text(
              delta!.abs().toStringAsFixed(1),
              style: AppTypography.captionText.copyWith(
                color: deltaColor,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
