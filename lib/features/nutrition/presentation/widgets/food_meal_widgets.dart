import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/food_entity.dart';
import '../../domain/entities/meal_entity.dart';
import 'nutrition_widgets.dart';

// ── Food Card ─────────────────────────────────────────────────────────────────

class FoodCard extends StatelessWidget {
  const FoodCard({
    required this.food,
    super.key,
    this.onFavoriteTap,
    this.onAddTap,
    this.showAddButton = true,
    this.compact = false,
  });

  final FoodEntity food;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onAddTap;
  final bool showAddButton;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: '${food.name} by ${food.brand}, ${food.nutritionForServings(1).calories.toStringAsFixed(0)} calories per serving',
      button: true,
      child: InkWell(
        onTap: () {
          context.push('${RouteNames.foodDetail}/${food.id}');
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Container(
          padding: compact
              ? const EdgeInsets.all(AppSpacing.sm)
              : const EdgeInsets.all(AppSpacing.md),
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
              // Category emoji icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Center(
                  child: Text(
                    food.category.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Name & brand
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      style: AppTypography.titleSmall.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${food.brand}  ·  ${food.servingSize.toStringAsFixed(0)} ${food.servingUnit}',
                      style: AppTypography.captionText.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 4),
                      _MacroRow(facts: food.nutritionForServings(1)),
                    ],
                  ],
                ),
              ),

              // Actions
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.chartCoral.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      '${food.nutritionForServings(1).calories.toStringAsFixed(0)} kcal',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.chartCoral,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onFavoriteTap != null)
                        GestureDetector(
                          onTap: onFavoriteTap,
                          child: Icon(
                            food.isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 18,
                            color: food.isFavorite
                                ? AppColors.chartCoral
                                : isDark
                                    ? AppColors.textHintDark
                                    : AppColors.textHintLight,
                          ),
                        ),
                      if (showAddButton && onAddTap != null) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: onAddTap,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: AppColors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
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

  Color get _categoryColor => switch (food.category) {
        FoodCategory.grains => AppColors.chartAmber,
        FoodCategory.protein => AppColors.chartCoral,
        FoodCategory.dairy => AppColors.chartSky,
        FoodCategory.fruits => AppColors.chartPink,
        FoodCategory.vegetables => AppColors.success,
        FoodCategory.fats => AppColors.chartIndigo,
        FoodCategory.beverages => AppColors.tertiary,
        FoodCategory.snacks => AppColors.warning,
        FoodCategory.sweets => AppColors.secondary,
        _ => AppColors.primary,
      };
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({required this.facts});
  final NutritionFacts facts;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        _MacroPill(
          label: 'P',
          value: facts.proteinG,
          color: AppColors.chartIndigo,
          isDark: isDark,
        ),
        const SizedBox(width: 4),
        _MacroPill(
          label: 'C',
          value: facts.carbsG,
          color: AppColors.chartAmber,
          isDark: isDark,
        ),
        const SizedBox(width: 4),
        _MacroPill(
          label: 'F',
          value: facts.fatG,
          color: AppColors.chartCoral,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _MacroPill extends StatelessWidget {
  const _MacroPill({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });
  final String label;
  final double value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        '$label: ${value.toStringAsFixed(0)}g',
        style: AppTypography.overline.copyWith(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Meal Card ─────────────────────────────────────────────────────────────────

class MealCard extends StatelessWidget {
  const MealCard({
    required this.meal,
    required this.isExpanded,
    required this.onToggle,
    required this.onAddFood,
    required this.onRemoveEntry,
    super.key,
  });

  final MealEntity meal;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onAddFood;
  final void Function(String entryId) onRemoveEntry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        border: Border.all(
          color: isExpanded
              ? AppColors.primary.withOpacity(0.4)
              : isDark
                  ? AppColors.dividerDark
                  : AppColors.dividerLight,
          width: isExpanded ? 1.5 : AppSpacing.borderThin,
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Text(meal.type.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.type.label,
                          style: AppTypography.titleSmall.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          meal.isEmpty
                              ? 'No foods logged'
                              : '${meal.entries.length} food${meal.entries.length == 1 ? '' : 's'}',
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
                        horizontal: AppSpacing.xs, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.chartCoral.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      '${meal.totalCalories.toStringAsFixed(0)} kcal',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.chartCoral,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ],
              ),
            ),
          ),

          // Expanded entries
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Column(
              children: [
                const Divider(height: 1),
                ...meal.entries.map(
                  (e) => _FoodEntryTile(
                    entry: e,
                    isDark: isDark,
                    onRemove: () => onRemoveEntry(e.id),
                  ),
                ),
                // Add food button
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                  child: OutlinedButton.icon(
                    onPressed: onAddFood,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add Food'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      minimumSize: const Size.fromHeight(40),
                    ),
                  ),
                ),
              ],
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _FoodEntryTile extends StatelessWidget {
  const _FoodEntryTile({
    required this.entry,
    required this.isDark,
    required this.onRemove,
  });

  final MealFoodEntry entry;
  final bool isDark;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final facts = entry.facts;

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        color: AppColors.error.withOpacity(0.15),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        child: const Icon(Icons.delete_rounded, color: AppColors.error),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        child: Row(
          children: [
            Text(entry.food.category.emoji,
                style: const TextStyle(fontSize: 16)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.food.name,
                    style: AppTypography.labelMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    '${entry.servings.toStringAsFixed(1)} × ${entry.food.servingSize.toStringAsFixed(0)} ${entry.food.servingUnit}',
                    style: AppTypography.captionText.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${facts.calories.toStringAsFixed(0)} kcal',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.chartCoral,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Goal Card ─────────────────────────────────────────────────────────────────

class GoalCard extends StatelessWidget {
  const GoalCard({
    required this.label,
    required this.current,
    required this.goal,
    required this.unit,
    required this.icon,
    required this.color,
    super.key,
  });

  final String label;
  final double current;
  final double goal;
  final String unit;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fraction = (current / goal).clamp(0.0, 1.0);

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
          Row(
            children: [
              Icon(icon, color: color, size: AppSpacing.iconSm),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: current.toStringAsFixed(0),
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: ' / ${goal.toStringAsFixed(0)} $unit',
                  style: AppTypography.captionText.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AnimatedFractionBar(fraction: fraction, color: color),
        ],
      ),
    );
  }
}

