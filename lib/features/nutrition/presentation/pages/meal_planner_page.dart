import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/meal_entity.dart';
import '../providers/nutrition_providers.dart';
import '../providers/nutrition_state.dart';
import '../widgets/food_meal_widgets.dart';
import '../widgets/nutrition_widgets.dart';

/// 5-meal accordion planner.
class MealPlannerPage extends ConsumerWidget {
  const MealPlannerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plannerState = ref.watch(mealPlannerProvider);
    final expandedType = ref.watch(expandedMealTypeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Meal Planner',
          style: AppTypography.titleLarge.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
            onPressed: () => context.push(RouteNames.foodDatabase),
            tooltip: 'Search Foods',
          ),
        ],
      ),
      body: switch (plannerState) {
        MealPlannerLoading() => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        MealPlannerError(:final message) =>
          Center(child: Text(message)),
        MealPlannerLoaded(:final meals, :final date) => _PlannerBody(
            meals: meals,
            date: date,
            expandedType: expandedType,
            isDark: isDark,
          ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _PlannerBody extends ConsumerWidget {
  const _PlannerBody({
    required this.meals,
    required this.date,
    required this.expandedType,
    required this.isDark,
  });

  final List<MealEntity> meals;
  final DateTime date;
  final MealType? expandedType;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalCalories = meals.fold(0.0, (s, m) => s + m.totalCalories);

    return Column(
      children: [
        // Calories Header
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.chartCoral.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(
                  color: AppColors.chartCoral.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_fire_department_rounded,
                    color: AppColors.chartCoral, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${totalCalories.toStringAsFixed(0)} kcal today',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.chartCoral,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Macro Summary
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
          child: _MacroRow(meals: meals, isDark: isDark),
        ),

        // Meal Accordion
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            itemCount: meals.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final meal = meals[i];
              return MealCard(
                meal: meal,
                isExpanded: expandedType == meal.type,
                onToggle: () {
                  final current = ref.read(expandedMealTypeProvider);
                  ref.read(expandedMealTypeProvider.notifier).state =
                      current == meal.type ? null : meal.type;
                },
                onAddFood: () => _showAddFoodSheet(context, ref, meal.type),
                onRemoveEntry: (id) => ref
                    .read(mealPlannerProvider.notifier)
                    .removeFoodFromMeal(mealType: meal.type, entryId: id),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddFoodSheet(
      BuildContext context, WidgetRef ref, MealType mealType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddFoodSheet(mealType: mealType),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({required this.meals, required this.isDark});
  final List<MealEntity> meals;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final totalP = meals.fold(0.0, (s, m) => s + m.totalProteinG);
    final totalC = meals.fold(0.0, (s, m) => s + m.totalCarbsG);
    final totalF = meals.fold(0.0, (s, m) => s + m.totalFatG);

    return Row(
      children: [
        _MacroBadge(label: 'P', value: totalP, color: AppColors.chartIndigo),
        const SizedBox(width: AppSpacing.xs),
        _MacroBadge(label: 'C', value: totalC, color: AppColors.chartAmber),
        const SizedBox(width: AppSpacing.xs),
        _MacroBadge(label: 'F', value: totalF, color: AppColors.chartCoral),
      ],
    );
  }
}

class _MacroBadge extends StatelessWidget {
  const _MacroBadge({required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        '$label: ${value.toStringAsFixed(0)}g',
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Add Food Sheet ────────────────────────────────────────────────────────────

class _AddFoodSheet extends ConsumerStatefulWidget {
  const _AddFoodSheet({required this.mealType});
  final MealType mealType;

  @override
  ConsumerState<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends ConsumerState<_AddFoodSheet> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.read(foodSearchProvider.notifier).loadAll();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(foodSearchProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.white,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXxl)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Add to ${widget.mealType.label}',
                      style: AppTypography.titleMedium.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: (v) =>
                    ref.read(foodSearchProvider.notifier).search(v),
                decoration: InputDecoration(
                  hintText: 'Search foods…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.cardDark
                      : AppColors.cardLight,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm),
                ),
              ),
            ),

            // Results
            Expanded(
              child: switch (searchState) {
                FoodSearchLoading() => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary)),
                FoodSearchLoaded(:final results) => ListView.separated(
                    controller: ctrl,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    itemCount: results.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, i) => FoodCard(
                      food: results[i],
                      compact: true,
                      showAddButton: true,
                      onAddTap: () =>
                          _showServingsDialog(context, ref, results[i]),
                      onFavoriteTap: () => ref
                          .read(foodSearchProvider.notifier)
                          .toggleFavorite(results[i].id),
                    ),
                  ),
                _ => const SizedBox.shrink(),
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showServingsDialog(BuildContext context, WidgetRef ref, FoodEntity food) {
    double servings = 1.0;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Add ${food.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Serving: ${food.servingSize.toStringAsFixed(0)} ${food.servingUnit}'),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_rounded),
                    onPressed: () {
                      if (servings > 0.5) {
                        setState(() => servings -= 0.5);
                      }
                    },
                  ),
                  Expanded(
                    child: Text(
                      '${servings.toStringAsFixed(1)} × serving',
                      textAlign: TextAlign.center,
                      style: AppTypography.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () => setState(() => servings += 0.5),
                  ),
                ],
              ),
              Text(
                '${food.nutritionForServings(servings).calories.toStringAsFixed(0)} kcal',
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.chartCoral),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                ref
                    .read(mealPlannerProvider.notifier)
                    .addFoodToMeal(
                      mealType: widget.mealType,
                      food: food,
                      servings: servings,
                    );
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

