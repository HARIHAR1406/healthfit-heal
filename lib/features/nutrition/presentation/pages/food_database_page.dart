import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/food_entity.dart';
import '../providers/nutrition_providers.dart';
import '../providers/nutrition_state.dart';
import '../widgets/food_meal_widgets.dart';

/// Searchable food library with category filter.
class FoodDatabasePage extends ConsumerStatefulWidget {
  const FoodDatabasePage({super.key});

  @override
  ConsumerState<FoodDatabasePage> createState() => _FoodDatabasePageState();
}

class _FoodDatabasePageState extends ConsumerState<FoodDatabasePage> {
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

  static const _categories = FoodCategory.values;

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(foodSearchProvider);
    final selectedCategory = ref.watch(foodCategoryFilterProvider);
    final query = ref.watch(foodSearchQueryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Food Database',
          style: AppTypography.titleLarge.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) {
                ref.read(foodSearchQueryProvider.notifier).state = v;
                ref.read(foodSearchProvider.notifier).search(v);
              },
              decoration: InputDecoration(
                hintText: 'Search 25+ foods…',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textHintDark
                      : AppColors.textHintLight,
                ),
                prefixIcon: Icon(Icons.search_rounded,
                    color: isDark
                        ? AppColors.textHintDark
                        : AppColors.textHintLight),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(foodSearchQueryProvider.notifier).state = '';
                          ref.read(foodSearchProvider.notifier).loadAll();
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.dividerDark
                        : AppColors.dividerLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              ),
            ),
          ),

          // Category Chips
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: _categories.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSpacing.xs),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final isSelected = selectedCategory == cat;
                return _CategoryChip(
                  category: cat,
                  isSelected: isSelected,
                  isDark: isDark,
                  onTap: () {
                    ref.read(foodCategoryFilterProvider.notifier).state = cat;
                    ref
                        .read(foodSearchProvider.notifier)
                        .filterByCategory(cat);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Food List
          Expanded(
            child: switch (searchState) {
              FoodSearchLoading() => const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary)),
              FoodSearchLoaded(:final results) when results.isEmpty =>
                _EmptyState(isDark: isDark),
              FoodSearchLoaded(:final results) => ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  itemCount: results.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (_, i) => FoodCard(
                    food: results[i],
                    onFavoriteTap: () => ref
                        .read(foodSearchProvider.notifier)
                        .toggleFavorite(results[i].id),
                    onAddTap: () =>
                        context.push('${RouteNames.foodDetail}/${results[i].id}'),
                  ),
                ),
              FoodSearchError(:final message) =>
                Center(child: Text(message)),
              _ => const SizedBox.shrink(),
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });
  final FoodCategory category;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.12)
              : isDark
                  ? AppColors.cardDark
                  : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : isDark
                    ? AppColors.dividerDark
                    : AppColors.dividerLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(
              category.label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_rounded,
              size: 64,
              color:
                  isDark ? AppColors.textHintDark : AppColors.textHintLight),
          const SizedBox(height: AppSpacing.md),
          Text('No foods found',
              style: AppTypography.titleMedium.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight)),
        ],
      ),
    );
  }
}
