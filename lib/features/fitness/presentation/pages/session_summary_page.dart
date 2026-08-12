import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/workout_session_entity.dart';
import '../providers/fitness_providers.dart';
import '../providers/adaptive_workout_providers.dart';
import '../providers/fitness_state.dart';
import '../../domain/entities/workout_analysis_engine.dart';

/// Post-workout summary shown when a session finishes.
class SessionSummaryPage extends ConsumerWidget {
  const SessionSummaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(workoutSessionProvider);
    final session = sessionState.session;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (session == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No session data'),
              ElevatedButton(
                onPressed: () => context.go(RouteNames.workouts),
                child: const Text('Go to Fitness'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // ── Congrats Header ─────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Workout Complete!',
                      style: AppTypography.headlineSmall.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      session.workout.title,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── Stats Grid ──────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
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
                          child: _SummaryStat(
                            icon: Icons.timer_rounded,
                            label: 'Duration',
                            value: session.elapsedFormatted,
                            color: AppColors.primary,
                            isDark: isDark,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 60,
                          color: isDark
                              ? AppColors.dividerDark
                              : AppColors.dividerLight,
                        ),
                        Expanded(
                          child: _SummaryStat(
                            icon: Icons.local_fire_department_rounded,
                            label: 'Calories',
                            value: '${session.caloriesBurnedSoFar} kcal',
                            color: AppColors.chartCoral,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    Divider(
                      color: isDark
                          ? AppColors.dividerDark
                          : AppColors.dividerLight,
                      height: AppSpacing.xl,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryStat(
                            icon: Icons.sports_gymnastics_rounded,
                            label: 'Exercises',
                            value:
                                '${session.completedExerciseIds.length}/${session.totalExercises}',
                            color: AppColors.tertiary,
                            isDark: isDark,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 60,
                          color: isDark
                              ? AppColors.dividerDark
                              : AppColors.dividerLight,
                        ),
                        Expanded(
                          child: _SummaryStat(
                            icon: Icons.trending_up_rounded,
                            label: 'Completion',
                            value:
                                '${(session.overallProgress * 100).round()}%',
                            color: AppColors.success,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
              _buildAdaptiveAnalysis(context, ref, isDark),
              const Spacer(),

              // ── Actions ─────────────────────────────────────────────────────
              FilledButton.icon(
                onPressed: () {
                  ref.read(workoutSessionProvider.notifier).reset();
                  context.go(RouteNames.workouts);
                },
                icon: const Icon(Icons.home_rounded),
                label: const Text('Back to Fitness'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(workoutSessionProvider.notifier).reset();
                  ref
                      .read(workoutSessionProvider.notifier)
                      .startWorkout(session.workout);
                  context.pushReplacement(RouteNames.activeSession);
                },
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Repeat Workout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildAdaptiveAnalysis(BuildContext context, WidgetRef ref, bool isDark) {
    final analysis = ref.watch(postWorkoutAnalysisProvider);
    if (analysis == null) return const SizedBox.shrink();

    final quality = analysis['quality'] as WorkoutQuality;
    final adaptation = analysis['adaptation'] as WorkoutAdaptation;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Session Analysis',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: quality.score > 80 ? AppColors.success.withOpacity(0.2) : AppColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  'Score: ${quality.score}',
                  style: AppTypography.labelSmall.copyWith(
                    color: quality.score > 80 ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            adaptation.reasoning,
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: AppSpacing.iconMd),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: AppTypography.captionText.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

