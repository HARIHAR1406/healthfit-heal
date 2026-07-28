import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../providers/fitness_providers.dart';
import '../providers/fitness_state.dart';
import '../widgets/fitness_history_widgets.dart';

/// Full workout history with search and date grouping.
class WorkoutHistoryPage extends ConsumerWidget {
  const WorkoutHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(workoutHistoryNotifierProvider);
    final filtered = ref.watch(filteredHistoryProvider);
    final query = ref.watch(historySearchProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Group by date
    final grouped = <String, List<dynamic>>{};
    for (final e in filtered) {
      final key = DateFormat('EEEE, dd MMM yyyy').format(e.completedAt);
      grouped.putIfAbsent(key, () => []).add(e);
    }

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Workout History',
          style: AppTypography.titleLarge.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
            onPressed: () =>
                ref.read(workoutHistoryNotifierProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
            child: TextField(
              onChanged: (v) =>
                  ref.read(historySearchProvider.notifier).state = v,
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
                            ref.read(historySearchProvider.notifier).state = '',
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
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ),

          // ── Summary Chips ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
            child: Row(
              children: [
                _SummaryChip(
                    icon: Icons.fitness_center_rounded,
                    label: '${filtered.length} sessions',
                    color: AppColors.primary,
                    isDark: isDark),
                const SizedBox(width: AppSpacing.xs),
                _SummaryChip(
                    icon: Icons.local_fire_department_rounded,
                    label:
                        '${filtered.fold(0, (s, e) => s + (e.caloriesBurned as int))} kcal',
                    color: AppColors.chartCoral,
                    isDark: isDark),
              ],
            ),
          ),

          // ── List ───────────────────────────────────────────────────────────
          Expanded(
            child: switch (historyState) {
              HistoryLoading() => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              HistoryError(:final message) =>
                Center(child: Text(message)),
              _ => filtered.isEmpty
                  ? _EmptyState(isDark: isDark)
                  : ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      children: [
                        for (final entry in grouped.entries) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                                top: AppSpacing.sm, bottom: AppSpacing.xs),
                            child: Text(
                              entry.key,
                              style: AppTypography.labelMedium.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          ...entry.value.map(
                            (e) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.xs),
                              child: WorkoutHistoryTile(entry: e),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xxxl),
                      ],
                    ),
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: AppTypography.labelSmall
                  .copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
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
          Icon(Icons.history_rounded,
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
