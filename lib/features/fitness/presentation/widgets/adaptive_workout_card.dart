import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/adaptive/recommended_workout.dart';
import '../../domain/entities/adaptive/workout_readiness.dart';
import '../providers/adaptive_workout_providers.dart';
import '../providers/fitness_providers.dart';

class AdaptiveWorkoutCard extends ConsumerWidget {
  const AdaptiveWorkoutCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendation = ref.watch(recommendedWorkoutProvider);
    final readiness = ref.watch(workoutReadinessProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (recommendation == null || readiness == null) {
      return const SizedBox.shrink(); // Hide if data unavailable
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header: Readiness & Effort ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: _getReadinessColor(readiness.status).withOpacity(0.1),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusLg),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: _getReadinessColor(readiness.status),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'AI Recommendation • ${_getReadinessLabel(readiness.status)}',
                    style: AppTypography.labelMedium.copyWith(
                      color: _getReadinessColor(readiness.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Body: Recommended Workout ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.workout.title,
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${recommendation.estimatedEffort} Effort • ${recommendation.workout.durationMinutes} min',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          recommendation.primaryReasoning,
                          style: AppTypography.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      ref.read(workoutSessionProvider.notifier).startWorkout(recommendation.workout);
                      context.push(RouteNames.activeSession);
                    },
                    child: const Text('Start Adaptive Workout'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getReadinessColor(ReadinessStatus status) {
    return switch (status) {
      ReadinessStatus.ready => AppColors.success,
      ReadinessStatus.moderate => AppColors.warning,
      ReadinessStatus.recover => AppColors.error,
      ReadinessStatus.insufficientData => AppColors.textSecondaryLight,
    };
  }

  String _getReadinessLabel(ReadinessStatus status) {
    return switch (status) {
      ReadinessStatus.ready => 'Ready to Train',
      ReadinessStatus.moderate => 'Moderate Recovery',
      ReadinessStatus.recover => 'Focus on Recovery',
      ReadinessStatus.insufficientData => 'Building Baseline',
    };
  }
}

