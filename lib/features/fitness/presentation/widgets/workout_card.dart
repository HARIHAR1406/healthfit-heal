import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/workout_entity.dart';

/// Gradient card for a workout in the library.
///
/// Displays category colour gradient, title, difficulty badge,
/// duration, calories, and a tap action to navigate to detail.
class WorkoutCard extends StatefulWidget {
  const WorkoutCard({
    required this.workout,
    required this.detailRoute,
    super.key,
    this.onFavouriteTap,
  });

  final WorkoutEntity workout;
  final String detailRoute;
  final VoidCallback? onFavouriteTap;

  @override
  State<WorkoutCard> createState() => _WorkoutCardState();
}

class _WorkoutCardState extends State<WorkoutCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      lowerBound: 0.96,
      upperBound: 1.0,
    )..value = 1.0;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static const List<List<Color>> _gradients = [
    [Color(0xFF00C896), Color(0xFF009870)],
    [Color(0xFFFF6B6B), Color(0xFFCC3B3B)],
    [Color(0xFF6C63FF), Color(0xFF3B36CC)],
    [Color(0xFFFF9800), Color(0xFFE65100)],
    [Color(0xFF00B4D8), Color(0xFF0077B6)],
    [Color(0xFFFF6BB5), Color(0xFFCC3B8B)],
  ];

  List<Color> get _gradient =>
      _gradients[widget.workout.imageGradientIndex % _gradients.length];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${widget.workout.title}, ${widget.workout.difficulty.label}, ${widget.workout.durationMinutes} minutes, ${widget.workout.caloriesEstimate} calories',
      button: true,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.reverse(),
        onTapUp: (_) {
          _ctrl.forward();
          context.push(detailRouteFor(widget.workout));
        },
        onTapCancel: () => _ctrl.forward(),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) =>
              Transform.scale(scale: _ctrl.value, child: child),
          child: _CardContent(
            workout: widget.workout,
            gradient: _gradient,
            onFavouriteTap: widget.onFavouriteTap,
          ),
        ),
      ),
    );
  }

  String detailRouteFor(WorkoutEntity w) =>
      widget.detailRoute.replaceFirst(':id', w.id);
}

class _CardContent extends StatelessWidget {
  const _CardContent({
    required this.workout,
    required this.gradient,
    this.onFavouriteTap,
  });

  final WorkoutEntity workout;
  final List<Color> gradient;
  final VoidCallback? onFavouriteTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _CategoryBadge(label: workout.category.label),
                const Spacer(),
                if (onFavouriteTap != null)
                  GestureDetector(
                    onTap: onFavouriteTap,
                    child: Icon(
                      workout.isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: AppColors.white,
                      size: AppSpacing.iconMd,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              workout.title,
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                _StatBadge(
                  icon: Icons.timer_outlined,
                  label: '${workout.durationMinutes} min',
                ),
                const SizedBox(width: AppSpacing.xs),
                _StatBadge(
                  icon: Icons.local_fire_department_rounded,
                  label: '${workout.caloriesEstimate} kcal',
                ),
                const SizedBox(width: AppSpacing.xs),
                _DifficultyBadge(difficulty: workout.difficulty),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: AppTypography.overline.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.white),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTypography.overline
                .copyWith(color: AppColors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});
  final WorkoutDifficulty difficulty;

  Color get _color => switch (difficulty) {
        WorkoutDifficulty.beginner => const Color(0xFF4CAF50),
        WorkoutDifficulty.intermediate => const Color(0xFFFFBF00),
        WorkoutDifficulty.advanced => const Color(0xFFEF5350),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.25),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: _color.withOpacity(0.5)),
      ),
      child: Text(
        difficulty.label,
        style: AppTypography.overline.copyWith(
          color: AppColors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
