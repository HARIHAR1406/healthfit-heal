import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/workout_session_entity.dart';
import '../providers/fitness_providers.dart';
import '../providers/fitness_state.dart';
import '../widgets/fitness_widgets.dart';

/// Live workout session screen.
///
/// Features:
///   - Elapsed timer (updates every second via WorkoutSessionNotifier)
///   - Rest countdown overlay
///   - Exercise progress list
///   - Pause / Resume / Skip / Previous / Next Set / Finish controls
///   - Haptic feedback on exercise transitions
class ActiveSessionPage extends ConsumerWidget {
  const ActiveSessionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(workoutSessionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen for session finish → auto navigate to summary
    ref.listen<SessionState>(workoutSessionProvider, (prev, next) {
      if (next is SessionFinished && context.mounted) {
        context.pushReplacement('/workouts/session/summary');
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final confirmed = await _confirmExit(context);
        if (confirmed && context.mounted) {
          ref.read(workoutSessionProvider.notifier).reset();
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
        body: switch (sessionState) {
          SessionIdle() => const Center(child: Text('No active session')),
          SessionFinished() =>
            const Center(child: CircularProgressIndicator()),
          SessionActive(:final session) => _SessionBody(
              session: session,
              isDark: isDark,
            ),
        },
      ),
    );
  }

  Future<bool> _confirmExit(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('End Workout?'),
            content: const Text(
                'Your progress will be lost. Are you sure you want to exit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Continue'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error),
                child: const Text('Exit'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

// ── Session Body ──────────────────────────────────────────────────────────────

class _SessionBody extends ConsumerWidget {
  const _SessionBody({required this.session, required this.isDark});
  final WorkoutSessionEntity session;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(workoutSessionProvider.notifier);
    final exercise = session.currentExercise;
    final isResting = session.isResting;
    final isPaused = session.isPaused;

    return Stack(
      children: [
        // ── Main Content ────────────────────────────────────────────────────
        CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: isDark
                  ? AppColors.backgroundDark
                  : AppColors.surfaceLight,
              pinned: true,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('End Workout?'),
                      content: const Text(
                          'Exit the active session? Progress will be lost.'),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context).pop(false),
                          child: const Text('Continue'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.of(context).pop(true),
                          style: FilledButton.styleFrom(
                              backgroundColor: AppColors.error),
                          child: const Text('Exit'),
                        ),
                      ],
                    ),
                  );
                  if ((confirmed ?? false) && context.mounted) {
                    ref.read(workoutSessionProvider.notifier).reset();
                    context.pop();
                  }
                },
              ),
              title: Text(
                session.workout.title,
                style: AppTypography.titleMedium.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: Center(
                    child: Text(
                      session.elapsedFormatted,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [
                          FontFeature.tabularFigures()
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Overall Progress ────────────────────────────────────────
                  _ProgressHeader(session: session, isDark: isDark),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Exercise Card ───────────────────────────────────────────
                  _ExerciseCard(
                    exercise: exercise,
                    currentSet: session.currentSet,
                    isDark: isDark,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Controls ────────────────────────────────────────────────
                  _Controls(
                    session: session,
                    isDark: isDark,
                    onPrev: () {
                      HapticFeedback.lightImpact();
                      notifier.previousExercise();
                    },
                    onNext: () {
                      HapticFeedback.mediumImpact();
                      notifier.nextExercise();
                    },
                    onPause: () {
                      HapticFeedback.selectionClick();
                      notifier.pause();
                    },
                    onResume: () {
                      HapticFeedback.selectionClick();
                      notifier.resume();
                    },
                    onNextSet: () {
                      HapticFeedback.mediumImpact();
                      notifier.nextSet();
                    },
                    onFinish: () {
                      HapticFeedback.heavyImpact();
                      notifier.finishWorkout();
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Exercise List ───────────────────────────────────────────
                  Text(
                    'Exercises',
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...session.workout.exercises.asMap().entries.map(
                        (e) => ExerciseTile(
                          index: e.key,
                          name: e.value.name,
                          sets: e.value.sets,
                          reps: e.value.reps,
                          durationSeconds: e.value.durationSeconds,
                          isCompleted: session.completedExerciseIds
                              .contains(e.value.id),
                          isCurrent:
                              e.key == session.currentExerciseIndex,
                        ),
                      ),

                  const SizedBox(height: AppSpacing.huge),
                ]),
              ),
            ),
          ],
        ),

        // ── Rest Countdown Overlay ──────────────────────────────────────────
        if (isResting)
          _RestOverlay(
            countdown: session.restCountdownSeconds!,
            isDark: isDark,
          ),

        // ── Paused Overlay ──────────────────────────────────────────────────
        if (isPaused && !isResting)
          _PausedOverlay(
            isDark: isDark,
            onResume: () => notifier.resume(),
          ),
      ],
    );
  }
}

// ── Progress Header ────────────────────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.session, required this.isDark});
  final WorkoutSessionEntity session;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exercise ${session.currentExerciseIndex + 1} of ${session.totalExercises}',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              Text(
                '${session.caloriesBurnedSoFar} kcal',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.chartCoral,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: session.overallProgress,
              minHeight: 6,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Exercise Card ─────────────────────────────────────────────────────────────

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.currentSet,
    required this.isDark,
  });
  final ExerciseEntity exercise;
  final int currentSet;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: Container(
        key: ValueKey(exercise.id),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF00A07A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Exercise name
            Text(
              exercise.name,
              textAlign: TextAlign.center,
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Target muscles
            Text(
              exercise.targetMuscles.join(' · '),
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Set / Rep / Duration display
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (exercise.sets > 1) ...[
                  _SessionStat(
                    label: 'Set',
                    value: '$currentSet/${exercise.sets}',
                  ),
                ],
                if (exercise.durationSeconds != null)
                  _SessionStat(
                    label: 'Duration',
                    value: '${exercise.durationSeconds}s',
                  )
                else if (exercise.reps > 0)
                  _SessionStat(
                    label: 'Reps',
                    value: '${exercise.reps}',
                  ),
                _SessionStat(
                  label: 'Rest',
                  value: '${exercise.restSeconds}s',
                ),
              ],
            ),

            if (exercise.instructions != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text(
                  exercise.instructions!,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.white.withOpacity(0.9),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SessionStat extends StatelessWidget {
  const _SessionStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: AppTypography.overline.copyWith(
            color: AppColors.white.withOpacity(0.75),
          ),
        ),
      ],
    );
  }
}

// ── Controls ──────────────────────────────────────────────────────────────────

class _Controls extends StatelessWidget {
  const _Controls({
    required this.session,
    required this.isDark,
    required this.onPrev,
    required this.onNext,
    required this.onPause,
    required this.onResume,
    required this.onNextSet,
    required this.onFinish,
  });

  final WorkoutSessionEntity session;
  final bool isDark;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onNextSet;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final isPaused = session.isPaused;
    final hasNext = session.hasNext;
    final hasPrev = session.hasPrevious;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Previous
        _CircleButton(
          icon: Icons.skip_previous_rounded,
          onTap: hasPrev ? onPrev : null,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          size: 52,
        ),

        // Pause / Resume
        _CircleButton(
          icon: isPaused
              ? Icons.play_arrow_rounded
              : Icons.pause_rounded,
          onTap: isPaused ? onResume : onPause,
          color: AppColors.primary,
          size: 64,
          filled: true,
        ),

        // Next Set or Finish
        !hasNext && session.currentSet >= session.currentExercise.sets
            ? _CircleButton(
                icon: Icons.flag_rounded,
                onTap: onFinish,
                color: AppColors.success,
                size: 52,
              )
            : _CircleButton(
                icon: Icons.done_rounded,
                onTap: onNextSet,
                color: AppColors.chartAmber,
                size: 52,
                tooltip: 'Complete Set',
              ),

        // Skip exercise
        _CircleButton(
          icon: Icons.skip_next_rounded,
          onTap: hasNext ? onNext : null,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          size: 52,
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.color,
    required this.size,
    this.onTap,
    this.filled = false,
    this.tooltip,
  });
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback? onTap;
  final bool filled;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final widget = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled
              ? color
              : color.withOpacity(onTap != null ? 0.12 : 0.04),
          border: filled
              ? null
              : Border.all(
                  color: color.withOpacity(onTap != null ? 0.3 : 0.1)),
        ),
        child: Icon(
          icon,
          color: filled
              ? AppColors.white
              : color.withOpacity(onTap != null ? 1.0 : 0.3),
          size: size * 0.45,
        ),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: widget);
    }
    return widget;
  }
}

// ── Rest Overlay ──────────────────────────────────────────────────────────────

class _RestOverlay extends StatelessWidget {
  const _RestOverlay({required this.countdown, required this.isDark});
  final int countdown;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundDark.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rest',
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.white.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TweenAnimationBuilder<double>(
              key: ValueKey(countdown),
              tween: Tween(begin: 1.0, end: 0.0),
              duration: const Duration(seconds: 1),
              builder: (_, value, child) => Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 8,
                      backgroundColor: AppColors.white.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.chartSky),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text(
                    '$countdown',
                    style: AppTypography.headlineLarge.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 48,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'seconds remaining',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PausedOverlay extends StatelessWidget {
  const _PausedOverlay({required this.isDark, required this.onResume});
  final bool isDark;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundDark.withOpacity(0.75),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pause_circle_filled_rounded,
                color: AppColors.white, size: 80),
            const SizedBox(height: AppSpacing.md),
            Text('Paused',
                style: AppTypography.headlineSmall
                    .copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onResume,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Resume'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl, vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

