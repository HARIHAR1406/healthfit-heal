import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/food_entity.dart';
import '../providers/nutrition_providers.dart';

/// Full nutrition facts + serving calculator for a single food item.
class FoodDetailPage extends ConsumerStatefulWidget {
  const FoodDetailPage({required this.foodId, super.key});
  final String foodId;

  @override
  ConsumerState<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends ConsumerState<FoodDetailPage> {
  double _servings = 1.0;
  FoodEntity? _food;

  @override
  void initState() {
    super.initState();
    _loadFood();
  }

  Future<void> _loadFood() async {
    final repo = ref.read(nutritionRepositoryProvider);
    final food = await repo.getFoodById(widget.foodId);
    if (mounted) setState(() => _food = food);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_food == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final food = _food!;
    final facts = food.nutritionForServings(_servings);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      body: CustomScrollView(
        slivers: [
          // Hero App Bar
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: _categoryColor(food),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                food.name,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _categoryColor(food),
                      _categoryColor(food).withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(food.category.emoji,
                      style: const TextStyle(fontSize: 72)),
                ),
              ),
            ),
            foregroundColor: AppColors.white,
          ),

          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Brand + Category row
                Row(
                  children: [
                    _BadgeChip(
                        label: food.brand,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
                    const SizedBox(width: AppSpacing.xs),
                    _BadgeChip(
                        label: food.category.label,
                        color: _categoryColor(food)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Serving Calculator ─────────────────────────────────────────
                _SectionTitle(title: 'Serving Size', isDark: isDark),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    border: Border.all(
                      color: isDark
                          ? AppColors.dividerDark
                          : AppColors.dividerLight,
                      width: AppSpacing.borderThin,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _servings,
                              min: 0.5,
                              max: 5.0,
                              divisions: 18,
                              activeColor: AppColors.primary,
                              onChanged: (v) =>
                                  setState(() => _servings = v),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd),
                            ),
                            child: Text(
                              '${_servings.toStringAsFixed(1)}×',
                              style: AppTypography.titleSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '= ${(_servings * food.servingSize).toStringAsFixed(0)} ${food.servingUnit.split(' ').first}  |  ${facts.calories.toStringAsFixed(0)} kcal',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Nutrition Facts ────────────────────────────────────────────
                _SectionTitle(title: 'Nutrition Facts', isDark: isDark),
                const SizedBox(height: AppSpacing.sm),
                _NutritionFactsPanel(facts: facts, isDark: isDark),
                const SizedBox(height: AppSpacing.lg),

                // ── Vitamins & Minerals ────────────────────────────────────────
                _SectionTitle(title: 'Vitamins & Minerals', isDark: isDark),
                const SizedBox(height: AppSpacing.sm),
                _VitaminPanel(facts: facts, isDark: isDark),
                const SizedBox(height: AppSpacing.lg),

                // ── Ingredients ────────────────────────────────────────────────
                if (food.ingredients != null) ...[
                  _SectionTitle(title: 'Ingredients', isDark: isDark),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusXl),
                      border: Border.all(
                          color: isDark
                              ? AppColors.dividerDark
                              : AppColors.dividerLight),
                    ),
                    child: Text(
                      food.ingredients!,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.huge),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(FoodEntity f) => switch (f.category) {
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

// ── Nutrition Facts Panel ─────────────────────────────────────────────────────

class _NutritionFactsPanel extends StatelessWidget {
  const _NutritionFactsPanel({required this.facts, required this.isDark});
  final NutritionFacts facts;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: AppSpacing.borderThin,
        ),
      ),
      child: Column(
        children: [
          _FactRow(
            label: 'Calories',
            value: '${facts.calories.toStringAsFixed(0)} kcal',
            bold: true,
            isDark: isDark,
          ),
          _Divider(isDark: isDark),
          _FactRow(
              label: 'Total Fat',
              value: '${facts.fatG.toStringAsFixed(1)} g',
              isDark: isDark),
          _FactRow(
              label: '  Saturated Fat',
              value:
                  '${facts.saturatedFatG.toStringAsFixed(1)} g',
              indent: true,
              isDark: isDark),
          _Divider(isDark: isDark),
          _FactRow(
              label: 'Cholesterol',
              value:
                  '${facts.cholesterolMg.toStringAsFixed(0)} mg',
              isDark: isDark),
          _Divider(isDark: isDark),
          _FactRow(
              label: 'Sodium',
              value: '${facts.sodiumMg.toStringAsFixed(0)} mg',
              isDark: isDark),
          _Divider(isDark: isDark),
          _FactRow(
              label: 'Total Carbohydrates',
              value: '${facts.carbsG.toStringAsFixed(1)} g',
              isDark: isDark),
          _FactRow(
              label: '  Dietary Fiber',
              value: '${facts.fiberG.toStringAsFixed(1)} g',
              indent: true,
              isDark: isDark),
          _FactRow(
              label: '  Sugars',
              value: '${facts.sugarG.toStringAsFixed(1)} g',
              indent: true,
              isDark: isDark),
          _Divider(isDark: isDark),
          _FactRow(
              label: 'Protein',
              value: '${facts.proteinG.toStringAsFixed(1)} g',
              isDark: isDark,
              last: true),
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.bold = false,
    this.indent = false,
    this.last = false,
  });
  final String label;
  final String value;
  final bool isDark;
  final bool bold;
  final bool indent;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          indent ? AppSpacing.xl : AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          last ? AppSpacing.md : AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: (bold ? AppTypography.titleSmall : AppTypography.bodySmall)
                .copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: (bold ? AppTypography.titleSmall : AppTypography.bodySmall)
                .copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
      indent: AppSpacing.md,
      endIndent: AppSpacing.md,
    );
  }
}

class _VitaminPanel extends StatelessWidget {
  const _VitaminPanel({required this.facts, required this.isDark});
  final NutritionFacts facts;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final items = [
      _VitaminItem(label: 'Vitamin C', dv: facts.vitaminC),
      _VitaminItem(label: 'Vitamin D', dv: facts.vitaminD),
      _VitaminItem(label: 'Calcium', dv: facts.calcium),
      _VitaminItem(label: 'Iron', dv: facts.iron),
    ];

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
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    item.label,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                    child: LinearProgressIndicator(
                      value: (item.dv / 100).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: isDark
                          ? AppColors.dividerDark
                          : AppColors.dividerLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.success),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${item.dv.toStringAsFixed(0)}%',
                    textAlign: TextAlign.end,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _VitaminItem {
  const _VitaminItem({required this.label, required this.dv});
  final String label;
  final double dv;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.isDark});
  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.titleMedium.copyWith(
        color:
            isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
