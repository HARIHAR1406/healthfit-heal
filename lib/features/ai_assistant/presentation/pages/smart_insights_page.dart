import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/ai_insight_entity.dart';
import '../providers/ai_providers.dart';
import '../providers/ai_state.dart';
import '../widgets/insight_coach_widgets.dart';

/// Smart insights page — all AI-generated insight cards with type filter.
class SmartInsightsPage extends ConsumerWidget {
  const SmartInsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final insightState = ref.watch(aiInsightProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        title: Text(
          'Smart Insights',
          style: AppTypography.titleLarge.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
        elevation: 0,
        actions: [
          if (insightState is InsightLoaded)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXl),
                  ),
                  child: Text(
                    '${insightState.unreadCount} new',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(aiInsightProvider.notifier).refresh(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Type filter chips
          _InsightTypeFilter(isDark: isDark),
          const SizedBox(height: AppSpacing.xs),

          // Content
          Expanded(
            child: switch (insightState) {
              InsightLoading() =>
                const Center(child: CircularProgressIndicator()),
              InsightError(:final message) => Center(
                  child: Text(message,
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.error)),
                ),
              InsightLoaded() => _InsightList(isDark: isDark),
            },
          ),
        ],
      ),
    );
  }
}

// ── Type Filter ───────────────────────────────────────────────────────────────

class _InsightTypeFilter extends ConsumerWidget {
  const _InsightTypeFilter({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilter = ref.watch(activeInsightFilterProvider);
    final types = [null, ...InsightType.values];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: types.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppSpacing.xs),
        itemBuilder: (_, i) {
          final type = types[i];
          final isActive = type == activeFilter;
          final color =
              type != null ? type.color : const Color(0xFF6C63FF);

          return GestureDetector(
            onTap: () {
              ref.read(activeInsightFilterProvider.notifier).state =
                  type;
              ref.read(aiInsightProvider.notifier).setFilter(type);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: isActive
                    ? color.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusXl),
                border: Border.all(
                  color: isActive
                      ? color
                      : Colors.grey.withOpacity(0.3),
                  width: isActive ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (type != null) ...[
                    Icon(type.icon, color: color, size: 14),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    type?.label ?? 'All',
                    style: AppTypography.labelSmall.copyWith(
                      color: isActive ? color : null,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Insight List ──────────────────────────────────────────────────────────────

class _InsightList extends ConsumerWidget {
  const _InsightList({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(filteredInsightsProvider);

    if (insights.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insights_rounded,
              size: 64,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No insights found',
              style: AppTypography.titleMedium.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: insights.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) {
        final insight = insights[i];
        return InsightCard(
          insight: insight,
          isDark: isDark,
          onTap: () =>
              ref.read(aiInsightProvider.notifier).markRead(insight.id),
          onDismiss: () =>
              ref.read(aiInsightProvider.notifier).markRead(insight.id),
          onAction: () {
            ref.read(aiInsightProvider.notifier).markRead(insight.id);
            // Navigate to related route when available
          },
        );
      },
    );
  }
}
