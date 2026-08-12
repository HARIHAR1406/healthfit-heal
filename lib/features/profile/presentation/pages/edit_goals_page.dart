import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/profile_entity.dart';
import '../providers/profile_notifier.dart';
import '../providers/profile_providers.dart';
import '../providers/profile_state.dart';

// ══════════════════════════════════════════════════════════════════════════════
// EDIT GOALS PAGE
// ══════════════════════════════════════════════════════════════════════════════

/// Lets the user adjust their daily & weekly health targets.
class EditGoalsPage extends ConsumerStatefulWidget {
  const EditGoalsPage({super.key});

  @override
  ConsumerState<EditGoalsPage> createState() => _EditGoalsPageState();
}

class _EditGoalsPageState extends ConsumerState<EditGoalsPage> {
  // Slider / field values — seeded from the current profile
  late double _calories;
  late double _waterMl;
  late double _steps;
  late double _workouts;
  late double _targetWeight;
  late double _sleep;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final g = ref.read(currentProfileProvider)?.goals;
    _calories = g?.dailyCaloriesTarget ?? 2000;
    _waterMl = g?.dailyWaterMlTarget ?? 2500;
    _steps = g?.dailyStepsTarget.toDouble() ?? 8000;
    _workouts = g?.weeklyWorkoutsTarget.toDouble() ?? 4;
    _targetWeight = g?.targetWeightKg ?? 70;
    _sleep = g?.sleepHoursTarget ?? 8;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final current = ref.read(currentProfileProvider);
    if (current == null) {
      setState(() => _saving = false);
      return;
    }
    final updated = current.copyWith(
      goals: HealthGoals(
        dailyCaloriesTarget: _calories,
        dailyWaterMlTarget: _waterMl,
        dailyStepsTarget: _steps.toInt(),
        weeklyWorkoutsTarget: _workouts.toInt(),
        targetWeightKg: _targetWeight,
        sleepHoursTarget: _sleep,
      ),
    );
    await ref.read(profileNotifierProvider.notifier).updateProfile(updated);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBusy = _saving ||
        ref.watch(profileNotifierProvider) is ProfileSaving;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Health Goals',
          style: AppTypography.titleLarge.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          TextButton(
            onPressed: isBusy ? null : _save,
            child: isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  )
                : Text(
                    'Save',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Hero banner
          _GoalHero(isDark: isDark),
          const SizedBox(height: AppSpacing.xl),

          // Calories
          _GoalSliderCard(
            icon: Icons.local_fire_department_rounded,
            color: AppColors.chartCoral,
            label: 'Daily Calories',
            value: _calories,
            min: 1200,
            max: 4000,
            divisions: 56,
            format: (v) => '${v.toInt()} kcal',
            onChanged: (v) => setState(() => _calories = v),
            isDark: isDark,
            description: 'Recommended: 1600–2800 kcal based on your TDEE',
          ),
          const SizedBox(height: AppSpacing.md),

          // Water
          _GoalSliderCard(
            icon: Icons.water_drop_rounded,
            color: AppColors.info,
            label: 'Daily Water',
            value: _waterMl,
            min: 1000,
            max: 5000,
            divisions: 40,
            format: (v) =>
                '${(v / 1000).toStringAsFixed(1)} L (${v.toInt()} ml)',
            onChanged: (v) => setState(() => _waterMl = v),
            isDark: isDark,
            description: 'General guideline: 2–3 L per day',
          ),
          const SizedBox(height: AppSpacing.md),

          // Steps
          _GoalSliderCard(
            icon: Icons.directions_walk_rounded,
            color: AppColors.tertiary,
            label: 'Daily Steps',
            value: _steps,
            min: 2000,
            max: 20000,
            divisions: 36,
            format: (v) => '${v.toInt()} steps',
            onChanged: (v) => setState(() => _steps = v),
            isDark: isDark,
            description: 'WHO recommends 8,000–10,000 steps/day',
          ),
          const SizedBox(height: AppSpacing.md),

          // Workouts
          _GoalSliderCard(
            icon: Icons.fitness_center_rounded,
            color: AppColors.primary,
            label: 'Weekly Workouts',
            value: _workouts,
            min: 1,
            max: 7,
            divisions: 6,
            format: (v) => '${v.toInt()} sessions/week',
            onChanged: (v) => setState(() => _workouts = v),
            isDark: isDark,
            description: 'WHO recommends 150+ minutes of moderate activity',
          ),
          const SizedBox(height: AppSpacing.md),

          // Target weight
          _GoalSliderCard(
            icon: Icons.monitor_weight_outlined,
            color: AppColors.secondary,
            label: 'Target Weight',
            value: _targetWeight,
            min: 40,
            max: 150,
            divisions: 110,
            format: (v) => '${v.toStringAsFixed(1)} kg',
            onChanged: (v) => setState(() => _targetWeight = v),
            isDark: isDark,
            description: 'Set a realistic goal within healthy BMI range',
          ),
          const SizedBox(height: AppSpacing.md),

          // Sleep
          _GoalSliderCard(
            icon: Icons.bedtime_rounded,
            color: AppColors.chartPink,
            label: 'Sleep Target',
            value: _sleep,
            min: 5,
            max: 10,
            divisions: 10,
            format: (v) => '${v.toStringAsFixed(1)} hours',
            onChanged: (v) => setState(() => _sleep = v),
            isDark: isDark,
            description: 'Adults need 7–9 hours for optimal recovery',
          ),

          const SizedBox(height: AppSpacing.massive),
        ],
      ),
    );
  }
}

// ── Goal Hero ─────────────────────────────────────────────────────────────────

class _GoalHero extends StatelessWidget {
  const _GoalHero({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF00C896)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
      ),
      child: Row(
        children: [
          const Icon(Icons.flag_rounded, color: AppColors.white, size: 40),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Health Goals',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Drag the sliders to personalise your daily targets. Changes are saved immediately.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.white.withOpacity(0.85),
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

// ── Goal Slider Card ──────────────────────────────────────────────────────────

class _GoalSliderCard extends StatelessWidget {
  const _GoalSliderCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.format,
    required this.onChanged,
    required this.isDark,
    required this.description,
  });

  final IconData icon;
  final Color color;
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double) format;
  final ValueChanged<double> onChanged;
  final bool isDark;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: AppSpacing.borderThin,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.titleSmall.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      description,
                      style: AppTypography.captionText.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Current value display
          Center(
            child: Text(
              format(value),
              style: AppTypography.titleLarge.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.15),
              thumbColor: color,
              overlayColor: color.withOpacity(0.12),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),

          // Min / Max labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  format(min),
                  style: AppTypography.captionText.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontSize: 10,
                  ),
                ),
                Text(
                  format(max),
                  style: AppTypography.captionText.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontSize: 10,
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

