import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/route_names.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/workout_entity.dart';
import '../providers/fitness_providers.dart';
import '../providers/fitness_state.dart';
import '../widgets/workout_card.dart';

/// Browse and filter all workouts.
class WorkoutLibraryPage extends ConsumerStatefulWidget {
  const WorkoutLibraryPage({super.key, this.initialCategory});
  final String? initialCategory;

  @override
  ConsumerState<WorkoutLibraryPage> createState() =>
      _WorkoutLibraryPageState();
}

class _WorkoutLibraryPageState
    extends ConsumerState<WorkoutLibraryPage> {
  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      final cat = _categoryFromString(widget.initialCategory!);
      if (cat != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(selectedCategoryProvider.notifier).state = cat;
          ref
              .read(workoutLibraryProvider.notifier)
              .filterByCategory(cat);
        });
      }
    }
  }

  static const _categories = [
    null, // All
    WorkoutCategory.strength,
    WorkoutCategory.cardio,
    WorkoutCategory.hiit,
    WorkoutCategory.yoga,
    WorkoutCategory.running,
    WorkoutCategory.cycling,
    WorkoutCategory.walking,
    WorkoutCategory.stretching,
    WorkoutCategory.homeWorkout,
  ];

  WorkoutCategory? _categoryFromString(String s) {
    for (final c in WorkoutCategory.values) {
      if (c.name == s) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final libraryState = ref.watch(workoutLibraryProvider);
    final selected = ref.watch(selectedCategoryProvider);
    final filtered = ref.watch(filteredWorkoutsProvider);
    final query = ref.watch(workoutSearchProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Workout Library',
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
          // ── Search ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
            child: TextField(
              onChanged: (v) =>
                  ref.read(workoutSearchProvider.notifier).state = v,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              decoration: InputDecoration(
                hintText: 'Search workouts…',
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
                        onPressed: () =>
                            ref.read(workoutSearchProvider.notifier).state = '',
                      )
                    : null,
                filled: true,
                fillColor:
                    isDark ? AppColors.cardDark : AppColors.cardLight,
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
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              ),
            ),
          ),

          // ── Category Filter Chips ──────────────────────────────────────────
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: _categories.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final isSelected = selected == cat;
                final label = cat?.label ?? 'All';

                return _CategoryChip(
                  label: label,
                  isSelected: isSelected,
                  isDark: isDark,
                  onTap: () {
                    ref.read(selectedCategoryProvider.notifier).state = cat;
                    ref
                        .read(workoutLibraryProvider.notifier)
                        .filterByCategory(cat);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── Workout Grid ───────────────────────────────────────────────────
          Expanded(
            child: switch (libraryState) {
              WorkoutLibraryLoading() => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              WorkoutLibraryError(:final message) => Center(
                  child: Text(message)),
              _ => filtered.isEmpty
                  ? _EmptyState(isDark: isDark)
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) => WorkoutCard(
                        workout: filtered[i],
                        detailRoute: RouteNames.workoutDetail,
                        onFavouriteTap: () => ref
                            .read(workoutLibraryProvider.notifier)
                            .toggleFavourite(filtered[i].id),
                      ),
                    ),
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });
  final String label;
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
              ? AppColors.primary.withValues(alpha: 0.12)
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
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected
                ? AppColors.primary
                : isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
            fontWeight:
                isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
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
          Icon(Icons.fitness_center_rounded,
              size: 64,
              color:
                  isDark ? AppColors.textHintDark : AppColors.textHintLight),
          const SizedBox(height: AppSpacing.md),
          Text('No workouts found',
              style: AppTypography.titleMedium.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight)),
        ],
      ),
    );
  }
}
