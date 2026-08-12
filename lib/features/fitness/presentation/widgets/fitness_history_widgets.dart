import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/fitness_stats_entity.dart';

/// A compact history entry tile.
class WorkoutHistoryTile extends StatelessWidget {
  const WorkoutHistoryTile({
    required this.entry,
    super.key,
    this.onTap,
  });

  final WorkoutHistoryEntry entry;
  final VoidCallback? onTap;

  Color get _categoryColor => switch (entry.category) {
        'Strength' => AppColors.chartIndigo,
        'Cardio' => AppColors.chartCoral,
        'HIIT' => AppColors.secondary,
        'Yoga' => AppColors.chartAmber,
        'Running' => AppColors.primary,
        'Cycling' => AppColors.chartSky,
        'Stretching' => AppColors.chartPink,
        _ => AppColors.tertiary,
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('dd MMM · hh:mm a').format(entry.completedAt);

    return Semantics(
      label:
          '${entry.workoutTitle}, ${entry.durationMinutes} minutes, ${entry.caloriesBurned} calories, $dateStr',
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color:
                  isDark ? AppColors.dividerDark : AppColors.dividerLight,
              width: AppSpacing.borderThin,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _categoryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  Icons.fitness_center_rounded,
                  color: _categoryColor,
                  size: AppSpacing.iconMd,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.workoutTitle,
                      style: AppTypography.titleSmall.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Stats
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_rounded,
                          size: 12,
                          color: isDark
                              ? AppColors.textHintDark
                              : AppColors.textHintLight),
                      const SizedBox(width: 3),
                      Text(
                        '${entry.durationMinutes} min',
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 10)),
                      const SizedBox(width: 2),
                      Text(
                        '${entry.caloriesBurned} kcal',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.chartCoral,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stat Tile ─────────────────────────────────────────────────────────────────

class FitnessStatTile extends StatelessWidget {
  const FitnessStatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    super.key,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: AppSpacing.borderThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: color, size: AppSpacing.iconSm),
          ),
          const SizedBox(height: AppSpacing.sm),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: AppTypography.headlineSmall.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Text(
            label,
            style: AppTypography.captionText.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Achievement Badge ─────────────────────────────────────────────────────────

class AchievementBadge extends StatelessWidget {
  const AchievementBadge({
    required this.emoji,
    required this.title,
    required this.description,
    required this.isUnlocked,
    required this.progressFraction,
    super.key,
  });

  final String emoji;
  final String title;
  final String description;
  final bool isUnlocked;
  final double progressFraction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: '$title: ${isUnlocked ? "Unlocked" : "${(progressFraction * 100).round()}% complete"}',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: isUnlocked
                ? AppColors.primary.withOpacity(0.4)
                : isDark
                    ? AppColors.dividerDark
                    : AppColors.dividerLight,
            width: isUnlocked ? 1.5 : AppSpacing.borderThin,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji in circle
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? AppColors.primary.withOpacity(0.1)
                    : (isDark ? AppColors.dividerDark : AppColors.dividerLight)
                        .withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: ColorFiltered(
                  colorFilter: isUnlocked
                      ? const ColorFilter.mode(
                          Colors.transparent, BlendMode.multiply)
                      : const ColorFilter.matrix([
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0,      0,      0,      1, 0,
                        ]),
                  child: Text(emoji, style: const TextStyle(fontSize: 26)),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.labelMedium.copyWith(
                color: isUnlocked
                    ? (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight)
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
                fontWeight:
                    isUnlocked ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (!isUnlocked) ...[
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                child: LinearProgressIndicator(
                  value: progressFraction,
                  minHeight: 4,
                  backgroundColor:
                      isDark ? AppColors.dividerDark : AppColors.dividerLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary),
                ),
              ),
            ],
            if (isUnlocked)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    '✓ Unlocked',
                    style: AppTypography.overline.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

