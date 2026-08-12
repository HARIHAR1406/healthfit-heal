import 'package:flutter/material.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/progress_item_entity.dart';
import 'circular_progress_ring.dart';

/// A single progress item widget showing a labeled ring + detail.
///
/// Used in the "Today's Progress" horizontal scroll.
class ProgressItemWidget extends StatelessWidget {
  const ProgressItemWidget({required this.item, super.key});

  final ProgressItemEntity item;

  // ── Color mapping ─────────────────────────────────────────────────────────

  Color get _color => switch (item.metricType) {
        'fitness' => AppColors.tertiary,
        'calories' => AppColors.chartAmber,
        'water' => AppColors.chartSky,
        'sleep' => AppColors.chartIndigo,
        'medication' => AppColors.success,
        _ => AppColors.primary,
      };

  IconData get _icon => switch (item.metricType) {
        'fitness' => Icons.fitness_center_rounded,
        'calories' => Icons.local_fire_department_rounded,
        'water' => Icons.water_drop_rounded,
        'sleep' => Icons.bedtime_rounded,
        'medication' => Icons.medication_rounded,
        _ => Icons.circle,
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _color;

    return Semantics(
      label: '${item.title}: ${item.currentLabel} ${item.unit} of ${item.goal} ${item.unit}. ${item.percentLabel} complete.',
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: item.isGoalReached
                ? color.withOpacity(0.3)
                : isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: AppSpacing.borderNormal,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : color.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Ring
            CircularProgressRing(
              fraction: item.fraction,
              size: 72,
              strokeWidth: 6,
              color: color,
              centerWidget: Icon(
                _icon,
                color: color,
                size: AppSpacing.iconSm,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Title
            Text(
              item.title,
              style: AppTypography.labelSmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 2),

            // Value / Goal
            Text(
              '${item.currentLabel} / ${item.goal.toInt()} ${item.unit}',
              style: AppTypography.captionText.copyWith(
                color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Goal reached badge
            if (item.isGoalReached) ...[
              const SizedBox(height: AppSpacing.xxs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  '✓ Done',
                  style: AppTypography.overline.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Horizontally scrollable "Today's Progress" section.
class TodayProgressSection extends StatelessWidget {
  const TodayProgressSection({required this.items, super.key});

  final List<ProgressItemEntity> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 188,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) => ProgressItemWidget(item: items[i]),
      ),
    );
  }
}
