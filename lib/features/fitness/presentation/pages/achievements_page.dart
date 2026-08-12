import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/achievement_entity.dart';
import '../providers/fitness_providers.dart';
import '../widgets/fitness_history_widgets.dart';

/// Achievements gallery with locked/unlocked states.
class AchievementsPage extends ConsumerWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(allAchievementsProvider);
    final unlocked = ref.watch(unlockedAchievementsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final locked =
        achievements.where((a) => !a.isUnlocked).toList();

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Achievements',
          style: AppTypography.titleLarge.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // ── Progress Summary ──────────────────────────────────────────────
          _ProgressSummaryCard(
            unlocked: unlocked.length,
            total: achievements.length,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Unlocked ─────────────────────────────────────────────────────
          if (unlocked.isNotEmpty) ...[
            Text(
              '🏆  Unlocked (${unlocked.length})',
              style: AppTypography.titleMedium.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.82,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: unlocked
                  .map(
                    (a) => AchievementBadge(
                      emoji: a.type.icon,
                      title: a.type.title,
                      description: a.type.description,
                      isUnlocked: true,
                      progressFraction: 1.0,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ── In Progress ───────────────────────────────────────────────────
          if (locked.isNotEmpty) ...[
            Text(
              '🎯  In Progress (${locked.length})',
              style: AppTypography.titleMedium.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...locked.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _InProgressTile(achievement: a, isDark: isDark),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}

// ── Progress Summary ───────────────────────────────────────────────────────────

class _ProgressSummaryCard extends StatelessWidget {
  const _ProgressSummaryCard({
    required this.unlocked,
    required this.total,
    required this.isDark,
  });
  final int unlocked;
  final int total;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? unlocked / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF6C63FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: fraction,
                  strokeWidth: 7,
                  backgroundColor: AppColors.white.withOpacity(0.2),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.white),
                  strokeCap: StrokeCap.round,
                ),
                Text(
                  '$unlocked',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$unlocked of $total Unlocked',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${((fraction) * 100).round()}% complete — keep going!',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── In-Progress Tile ──────────────────────────────────────────────────────────

class _InProgressTile extends StatelessWidget {
  const _InProgressTile({required this.achievement, required this.isDark});
  final AchievementEntity achievement;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
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
          Text(achievement.type.icon,
              style: const TextStyle(fontSize: 32)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.type.title,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  achievement.type.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                        child: LinearProgressIndicator(
                          value: achievement.progressFraction,
                          minHeight: 5,
                          backgroundColor: isDark
                              ? AppColors.dividerDark
                              : AppColors.dividerLight,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${achievement.progressCurrent}/${achievement.progressTarget}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

