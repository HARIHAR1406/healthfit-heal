import 'package:flutter/material.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/activity_item_entity.dart';

/// A single row in the recent activity timeline.
class ActivityItemWidget extends StatelessWidget {
  const ActivityItemWidget({
    required this.item,
    required this.isLast,
    super.key,
  });

  final ActivityItemEntity item;
  final bool isLast;

  // ── Visual Mapping ────────────────────────────────────────────────────────

  IconData get _icon => switch (item.type) {
        ActivityType.workout => Icons.fitness_center_rounded,
        ActivityType.meal => Icons.restaurant_rounded,
        ActivityType.medication => Icons.medication_rounded,
        ActivityType.healthUpdate => Icons.monitor_heart_rounded,
        ActivityType.sleep => Icons.bedtime_rounded,
        ActivityType.water => Icons.water_drop_rounded,
        ActivityType.vitals => Icons.biotech_rounded,
      };

  Color get _color => switch (item.type) {
        ActivityType.workout => AppColors.tertiary,
        ActivityType.meal => AppColors.chartAmber,
        ActivityType.medication => AppColors.success,
        ActivityType.healthUpdate => AppColors.chartCoral,
        ActivityType.sleep => AppColors.chartIndigo,
        ActivityType.water => AppColors.chartSky,
        ActivityType.vitals => AppColors.chartPink,
      };

  String get _typeLabel => switch (item.type) {
        ActivityType.workout => 'Workout',
        ActivityType.meal => 'Nutrition',
        ActivityType.medication => 'Medication',
        ActivityType.healthUpdate => 'Health',
        ActivityType.sleep => 'Sleep',
        ActivityType.water => 'Hydration',
        ActivityType.vitals => 'Vitals',
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _color;

    return Semantics(
      label: '${item.title}. ${item.description}. ${item.timeAgo}',
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Timeline ──────────────────────────────────────────────────
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  // Dot
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: AppSpacing.borderNormal,
                      ),
                    ),
                    child: Icon(_icon, color: color, size: 18),
                  ),

                  // Connector line
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.dividerDark
                              : AppColors.dividerLight,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // ── Content ───────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: isLast ? 0 : AppSpacing.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + description + type chip
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            item.title,
                            style: AppTypography.titleSmall.copyWith(
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.description,
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          // Type chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusFull,
                              ),
                            ),
                            child: Text(
                              _typeLabel,
                              style: AppTypography.overline.copyWith(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right: time + value
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          item.timeAgo,
                          style: AppTypography.captionText.copyWith(
                            color: isDark
                                ? AppColors.textHintDark
                                : AppColors.textHintLight,
                          ),
                        ),
                        if (item.value != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${item.value}${item.unit != null && item.unit!.isNotEmpty ? " ${item.unit}" : ""}',
                            style: AppTypography.labelSmall.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vertical timeline of recent activity items.
class RecentActivitySection extends StatelessWidget {
  const RecentActivitySection({required this.activities, super.key});

  final List<ActivityItemEntity> activities;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: activities.asMap().entries.map((entry) {
        return ActivityItemWidget(
          item: entry.value,
          isLast: entry.key == activities.length - 1,
        );
      }).toList(),
    );
  }
}
