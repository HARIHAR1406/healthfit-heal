import 'package:flutter/material.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/fitness_stats_entity.dart';

/// Circular activity ring card showing one metric.
class ActivityRingCard extends StatelessWidget {
  const ActivityRingCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.fraction,
    required this.color,
    super.key,
    this.icon,
  });

  final String label;
  final String value;
  final String unit;
  final double fraction;
  final Color color;
  final IconData? icon;

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
        mainAxisSize: MainAxisSize.min,
        children: [
          _Ring(fraction: fraction, color: color, icon: icon),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$value $unit',
            style: AppTypography.titleSmall.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
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

class _Ring extends StatelessWidget {
  const _Ring({
    required this.fraction,
    required this.color,
    this.icon,
  });
  final double fraction;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: fraction,
            strokeWidth: 7,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeCap: StrokeCap.round,
          ),
          if (icon != null)
            Icon(icon, color: color, size: AppSpacing.iconSm),
        ],
      ),
    );
  }
}

// ── Today Activity Summary Card ───────────────────────────────────────────────

/// Hero card showing 4 activity rings side by side.
class TodayActivityCard extends StatelessWidget {
  const TodayActivityCard({required this.activity, super.key});

  final DailyActivityEntity activity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF00A07A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  "✦  Today's Activity",
                  style: AppTypography.overline.copyWith(
                    color: AppColors.white,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${activity.workoutsCompleted} workout${activity.workoutsCompleted == 1 ? '' : 's'}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Rings Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _WhiteRing(
                label: 'Calories',
                value: '${activity.caloriesBurned}',
                unit: 'kcal',
                fraction: activity.calorieFraction,
                icon: Icons.local_fire_department_rounded,
              ),
              _WhiteRing(
                label: 'Active',
                value: '${activity.activeMinutes}',
                unit: 'min',
                fraction: activity.activeMinutesFraction,
                icon: Icons.bolt_rounded,
              ),
              _WhiteRing(
                label: 'Distance',
                value: activity.distanceKm.toStringAsFixed(1),
                unit: 'km',
                fraction: activity.distanceFraction,
                icon: Icons.directions_run_rounded,
              ),
              _WhiteRing(
                label: 'Steps',
                value: '${(activity.stepsTaken / 1000).toStringAsFixed(1)}k',
                unit: '',
                fraction: activity.stepsFraction,
                icon: Icons.footprint,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WhiteRing extends StatelessWidget {
  const _WhiteRing({
    required this.label,
    required this.value,
    required this.unit,
    required this.fraction,
    required this.icon,
  });

  final String label;
  final String value;
  final String unit;
  final double fraction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 62,
          height: 62,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: fraction,
                strokeWidth: 7,
                backgroundColor: AppColors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.white),
                strokeCap: StrokeCap.round,
              ),
              Icon(icon, color: AppColors.white, size: 20),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          unit.isNotEmpty ? '$value $unit' : value,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: AppTypography.overline.copyWith(
            color: AppColors.white.withValues(alpha: 0.8),
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

// ── Weekly Streak Card ────────────────────────────────────────────────────────

class WorkoutStreakCard extends StatelessWidget {
  const WorkoutStreakCard({
    required this.current,
    required this.longest,
    super.key,
  });

  final int current;
  final int longest;

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
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 32)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$current Day Streak',
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Personal best: $longest days',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Text(
              current > 0 ? 'Active' : 'Start!',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Exercise Tile ─────────────────────────────────────────────────────────────

class ExerciseTile extends StatelessWidget {
  const ExerciseTile({
    required this.index,
    required this.name,
    required this.sets,
    required this.reps,
    required this.durationSeconds,
    required this.isCompleted,
    required this.isCurrent,
    super.key,
  });

  final int index;
  final String name;
  final int sets;
  final int reps;
  final int? durationSeconds;
  final bool isCompleted;
  final bool isCurrent;

  String get _descriptor {
    if (durationSeconds != null) {
      return '$sets × ${durationSeconds}s';
    }
    return '$sets × $reps reps';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isCurrent
        ? AppColors.primary
        : isCompleted
            ? AppColors.success
            : isDark
                ? AppColors.dividerDark
                : AppColors.dividerLight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.primary.withValues(alpha: 0.08)
            : isDark
                ? AppColors.cardDark
                : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: accent.withValues(alpha: isCurrent ? 0.6 : 0.3),
          width: isCurrent ? 1.5 : AppSpacing.borderThin,
        ),
      ),
      child: Row(
        children: [
          // Index / Check
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? Icon(Icons.check_rounded,
                      size: 16, color: AppColors.success)
                  : Text(
                      '${index + 1}',
                      style: AppTypography.labelSmall.copyWith(
                        color: isCurrent
                            ? AppColors.primary
                            : isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Name + descriptor
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight:
                        isCurrent ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                Text(
                  _descriptor,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),

          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                'Now',
                style: AppTypography.overline.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
