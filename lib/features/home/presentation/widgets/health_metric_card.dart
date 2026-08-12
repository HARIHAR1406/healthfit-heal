import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/health_metric_entity.dart';
import 'circular_progress_ring.dart';

/// Health metric card displayed in the horizontal overview scroll.
///
/// Tapping the card navigates to the metric's detail screen.
class HealthMetricCard extends StatelessWidget {
  const HealthMetricCard({
    required this.metric,
    super.key,
  });

  final HealthMetricEntity metric;

  // ── Metric Visual Mapping ─────────────────────────────────────────────────

  IconData get _icon => switch (metric.type) {
        HealthMetricType.bmi => Icons.monitor_weight_outlined,
        HealthMetricType.heartRate => Icons.favorite_rounded,
        HealthMetricType.steps => Icons.directions_walk_rounded,
        HealthMetricType.water => Icons.water_drop_rounded,
        HealthMetricType.sleep => Icons.bedtime_rounded,
        HealthMetricType.calories => Icons.local_fire_department_rounded,
        HealthMetricType.bloodPressure => Icons.bloodtype_rounded,
        HealthMetricType.oxygenSaturation => Icons.air_rounded,
      };

  Color get _color => switch (metric.type) {
        HealthMetricType.bmi => AppColors.chartIndigo,
        HealthMetricType.heartRate => AppColors.chartCoral,
        HealthMetricType.steps => AppColors.chartTeal,
        HealthMetricType.water => AppColors.chartSky,
        HealthMetricType.sleep => AppColors.tertiary,
        HealthMetricType.calories => AppColors.chartAmber,
        HealthMetricType.bloodPressure => AppColors.secondary,
        HealthMetricType.oxygenSaturation => AppColors.chartPink,
      };

  Color get _statusColor => switch (metric.status) {
        HealthMetricStatus.excellent => AppColors.success,
        HealthMetricStatus.normal => AppColors.primary,
        HealthMetricStatus.warning => AppColors.warning,
        HealthMetricStatus.critical => AppColors.error,
      };

  String get _statusLabel => switch (metric.status) {
        HealthMetricStatus.excellent => 'Excellent',
        HealthMetricStatus.normal => 'Normal',
        HealthMetricStatus.warning => 'Monitor',
        HealthMetricStatus.critical => 'Critical',
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: '${metric.title}: ${metric.value} ${metric.unit}. Status: $_statusLabel',
      button: true,
      child: GestureDetector(
        onTap: () => context.push(metric.route),
        child: AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: 148,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                width: AppSpacing.borderThin,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : _color.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Icon + Progress Ring ────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icon container
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _color.withOpacity(0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(_icon, color: _color, size: AppSpacing.iconMd),
                    ),

                    // Mini progress ring
                    CircularProgressRing(
                      fraction: metric.progressPercent,
                      size: 36,
                      strokeWidth: 3.5,
                      color: _color,
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // ── Title ───────────────────────────────────────────────────
                Text(
                  metric.title,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: AppSpacing.xxs),

                // ── Value + Unit ────────────────────────────────────────────
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: metric.value,
                        style: AppTypography.titleLarge.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                      if (metric.unit.isNotEmpty)
                        TextSpan(
                          text: ' ${metric.unit}',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                // ── Status Badge ────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _statusLabel,
                        style: AppTypography.overline.copyWith(
                          color: _statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                if (metric.subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    metric.subtitle!,
                    style: AppTypography.captionText.copyWith(
                      color: isDark
                          ? AppColors.textHintDark
                          : AppColors.textHintLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontally scrollable row of [HealthMetricCard] widgets.
class HealthOverviewSection extends StatelessWidget {
  const HealthOverviewSection({
    required this.metrics,
    super.key,
  });

  final List<HealthMetricEntity> metrics;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
        itemCount: metrics.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) => HealthMetricCard(metric: metrics[i]),
      ),
    );
  }
}
