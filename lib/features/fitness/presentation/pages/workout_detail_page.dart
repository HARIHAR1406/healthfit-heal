import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/workout_entity.dart';
import '../providers/fitness_providers.dart';
import '../widgets/fitness_widgets.dart';

/// Workout detail page — description, exercises list, start button.
class WorkoutDetailPage extends ConsumerWidget {
  const WorkoutDetailPage({required this.workoutId, super.key});
  final String workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = ref.watch(allWorkoutsProvider);
    final workout = workouts.isEmpty
        ? null
        : workouts.where((w) => w.id == workoutId).firstOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (workout == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: _gradients[workout.imageGradientIndex % _gradients.length][0],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                workout.title,
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  shadows: [
                    const Shadow(blurRadius: 8, color: Colors.black45),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _gradients[workout.imageGradientIndex % _gradients.length],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xl),
                    child: Icon(
                      Icons.fitness_center_rounded,
                      size: 100,
                      color: AppColors.white.withOpacity(0.2),
                    ),
                  ),
                ),
              ),
            ),
            foregroundColor: AppColors.white,
          ),

          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Meta Row ──────────────────────────────────────────────────
                Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    _MetaBadge(
                      icon: Icons.timer_outlined,
                      label: '${workout.durationMinutes} min',
                      isDark: isDark,
                    ),
                    _MetaBadge(
                      icon: Icons.local_fire_department_rounded,
                      label: '~${workout.caloriesEstimate} kcal',
                      isDark: isDark,
                    ),
                    _MetaBadge(
                      icon: Icons.bar_chart_rounded,
                      label: workout.difficulty.label,
                      isDark: isDark,
                    ),
                    _MetaBadge(
                      icon: Icons.sports_gymnastics_rounded,
                      label: '${workout.exercises.length} exercises',
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Description ───────────────────────────────────────────────
                if (workout.description != null) ...[
                  Text(
                    'About',
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    workout.description!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ── Target Muscles ────────────────────────────────────────────
                Text(
                  'Target Muscles',
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: workout.targetMuscles
                      .map((m) => _MuscleChip(muscle: m, isDark: isDark))
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Equipment ─────────────────────────────────────────────────
                Text(
                  'Equipment',
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: workout.equipment
                      .map((e) => Chip(
                            avatar: const Icon(Icons.sports_rounded, size: 14),
                            label: Text(e.label,
                                style: AppTypography.labelSmall),
                          ))
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Exercises ─────────────────────────────────────────────────
                Text(
                  'Exercises (${workout.exercises.length})',
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...workout.exercises.asMap().entries.map(
                      (e) => ExerciseTile(
                        index: e.key,
                        name: e.value.name,
                        sets: e.value.sets,
                        reps: e.value.reps,
                        durationSeconds: e.value.durationSeconds,
                        isCompleted: false,
                        isCurrent: false,
                      ),
                    ),

                const SizedBox(height: AppSpacing.huge),
              ]),
            ),
          ),
        ],
      ),

      // ── Start Workout FAB ───────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'start_workout_fab',
        onPressed: () {
          ref.read(workoutSessionProvider.notifier).startWorkout(workout);
          context.push(RouteNames.activeSession);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(
          'Start Workout',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  static const List<List<Color>> _gradients = [
    [Color(0xFF00C896), Color(0xFF009870)],
    [Color(0xFFFF6B6B), Color(0xFFCC3B3B)],
    [Color(0xFF6C63FF), Color(0xFF3B36CC)],
    [Color(0xFFFF9800), Color(0xFFE65100)],
    [Color(0xFF00B4D8), Color(0xFF0077B6)],
    [Color(0xFFFF6BB5), Color(0xFFCC3B8B)],
  ];
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.icon, required this.label, required this.isDark});
  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label,
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MuscleChip extends StatelessWidget {
  const _MuscleChip({required this.muscle, required this.isDark});
  final String muscle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.chartIndigo.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
            color: AppColors.chartIndigo.withOpacity(0.25)),
      ),
      child: Text(
        muscle,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.chartIndigo,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
