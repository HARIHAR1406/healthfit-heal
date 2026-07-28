import 'package:flutter/material.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/meal_entity.dart';

// ── Calorie Ring Widget ───────────────────────────────────────────────────────

/// Animated circular calorie ring with remaining/consumed text.
class CalorieRingWidget extends StatelessWidget {
  const CalorieRingWidget({
    required this.consumed,
    required this.goal,
    required this.remaining,
    super.key,
    this.size = 160,
    this.strokeWidth = 14,
  });

  final double consumed;
  final double goal;
  final double remaining;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fraction = (consumed / goal).clamp(0.0, 1.0);
    final overGoal = consumed > goal;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Track
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: fraction,
              strokeWidth: strokeWidth,
              backgroundColor: overGoal
                  ? AppColors.error.withValues(alpha: 0.15)
                  : AppColors.chartCoral.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(
                overGoal ? AppColors.error : AppColors.chartCoral,
              ),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Labels
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                remaining.toStringAsFixed(0),
                style: AppTypography.headlineMedium.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'kcal left',
                style: AppTypography.captionText.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${consumed.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)}',
                style: AppTypography.overline.copyWith(
                  color: AppColors.chartCoral,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Macro Progress Bar ────────────────────────────────────────────────────────

/// Animated horizontal macro bar with label, value, and goal.
class MacroProgressBar extends StatelessWidget {
  const MacroProgressBar({
    required this.label,
    required this.value,
    required this.goal,
    required this.unit,
    required this.color,
    super.key,
  });

  final String label;
  final double value;
  final double goal;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fraction = (value / goal).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value.toStringAsFixed(0),
                    style: AppTypography.labelSmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: ' / ${goal.toStringAsFixed(0)} $unit',
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.textHintDark
                          : AppColors.textHintLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        AnimatedFractionBar(
          fraction: fraction,
          color: color,
        ),
      ],
    );
  }
}

class AnimatedFractionBar extends StatelessWidget {
  const AnimatedFractionBar({
    required this.fraction,
    required this.color,
    super.key,
    this.height = 7,
  });

  final double fraction;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      child: LinearProgressIndicator(
        value: fraction,
        minHeight: height,
        backgroundColor: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

// ── Macro Summary Card ────────────────────────────────────────────────────────

/// 4-macro row card: protein / carbs / fat + individual circles.
class MacroSummaryCard extends StatelessWidget {
  const MacroSummaryCard({
    required this.proteinG,
    required this.proteinGoalG,
    required this.carbsG,
    required this.carbsGoalG,
    required this.fatG,
    required this.fatGoalG,
    super.key,
  });

  final double proteinG;
  final double proteinGoalG;
  final double carbsG;
  final double carbsGoalG;
  final double fatG;
  final double fatGoalG;

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
          Text(
            'Macros',
            style: AppTypography.titleSmall.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MacroCircle(
                label: 'Protein',
                value: proteinG,
                goal: proteinGoalG,
                unit: 'g',
                color: AppColors.chartIndigo,
              ),
              _MacroCircle(
                label: 'Carbs',
                value: carbsG,
                goal: carbsGoalG,
                unit: 'g',
                color: AppColors.chartAmber,
              ),
              _MacroCircle(
                label: 'Fat',
                value: fatG,
                goal: fatGoalG,
                unit: 'g',
                color: AppColors.chartCoral,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroCircle extends StatelessWidget {
  const _MacroCircle({
    required this.label,
    required this.value,
    required this.goal,
    required this.unit,
    required this.color,
  });

  final String label;
  final double value;
  final double goal;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fraction = (value / goal).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 68,
          height: 68,
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
              Text(
                value.toStringAsFixed(0),
                style: AppTypography.labelMedium.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: AppTypography.captionText.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        Text(
          '${goal.toStringAsFixed(0)}$unit',
          style: AppTypography.overline.copyWith(
            color: color.withValues(alpha: 0.8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Water Progress Ring ───────────────────────────────────────────────────────

class WaterProgressWidget extends StatelessWidget {
  const WaterProgressWidget({
    required this.currentMl,
    required this.goalMl,
    super.key,
    this.size = 140,
  });

  final int currentMl;
  final int goalMl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fraction = (currentMl / goalMl).clamp(0.0, 1.0);
    final glasses = (currentMl / 250).floor();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: fraction,
            strokeWidth: 12,
            backgroundColor: AppColors.chartSky.withValues(alpha: 0.12),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.chartSky),
            strokeCap: StrokeCap.round,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💧', style: TextStyle(fontSize: 22)),
              Text(
                '${(currentMl / 1000).toStringAsFixed(1)} L',
                style: AppTypography.titleSmall.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '$glasses glasses',
                style: AppTypography.captionText.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Nutrition Score Badge ─────────────────────────────────────────────────────

class NutritionScoreBadge extends StatelessWidget {
  const NutritionScoreBadge({required this.score, super.key});
  final int score;

  Color get _color {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.chartAmber;
    return AppColors.chartCoral;
  }

  String get _label {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    return 'Needs Work';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100.0,
                  strokeWidth: 4,
                  backgroundColor:
                      _color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(_color),
                  strokeCap: StrokeCap.round,
                ),
                Text(
                  '$score',
                  style: AppTypography.overline.copyWith(
                    color: _color,
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nutrition Score',
                style: AppTypography.captionText.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              Text(
                _label,
                style: AppTypography.labelSmall.copyWith(
                  color: _color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Meal Calorie Row ──────────────────────────────────────────────────────────

class MealCalorieRow extends StatelessWidget {
  const MealCalorieRow({
    required this.mealType,
    required this.calories,
    required this.goalCalories,
    super.key,
  });

  final MealType mealType;
  final double calories;
  final double goalCalories;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fraction = (calories / goalCalories).clamp(0.0, 1.0);

    return Row(
      children: [
        Text(mealType.emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    mealType.label,
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  Text(
                    '${calories.toStringAsFixed(0)} kcal',
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedFractionBar(
                fraction: fraction,
                color: AppColors.chartCoral,
                height: 5,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
