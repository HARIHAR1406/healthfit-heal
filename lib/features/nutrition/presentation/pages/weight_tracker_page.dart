import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/nutrition_tracking_entity.dart';
import '../providers/nutrition_providers.dart';
import '../providers/nutrition_state.dart';
import '../widgets/nutrition_chart_widgets.dart';

/// Weight tracker with history, BMI, goal progress, and line chart.
class WeightTrackerPage extends ConsumerWidget {
  const WeightTrackerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weightState = ref.watch(weightTrackerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Weight Tracker',
          style: AppTypography.titleLarge.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
            onPressed: () => _showLogWeightDialog(context, ref),
            tooltip: 'Log Weight',
          ),
        ],
      ),
      body: switch (weightState) {
        WeightLoading() => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        WeightError(:final message) => Center(child: Text(message)),
        WeightLoaded(:final tracker) => _WeightBody(
            tracker: tracker,
            isDark: isDark,
          ),
        _ => const SizedBox.shrink(),
      },
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'log_weight_fab',
        onPressed: () => _showLogWeightDialog(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log Weight'),
      ),
    );
  }

  void _showLogWeightDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    final notesCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log Weight'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                suffixText: 'kg',
              ),
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final kg = double.tryParse(ctrl.text);
              if (kg != null && kg > 0) {
                ref
                    .read(weightTrackerProvider.notifier)
                    .logWeight(kg,
                        notes: notesCtrl.text.isEmpty
                            ? null
                            : notesCtrl.text);
                HapticFeedback.mediumImpact();
              }
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _WeightBody extends StatelessWidget {
  const _WeightBody({required this.tracker, required this.isDark});
  final WeightTrackerEntity tracker;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final current = tracker.currentWeightKg;
    final bmi = tracker.bmi;
    final entries = tracker.entries;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Current / Goal / BMI hero
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF6C63FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _WeightHeroStat(
                label: 'Current',
                value: current != null
                    ? '${current.toStringAsFixed(1)} kg'
                    : '—',
              ),
              Container(
                width: 1,
                height: 60,
                color: AppColors.white.withValues(alpha: 0.3),
              ),
              _WeightHeroStat(
                label: 'Goal',
                value: '${tracker.goalKg.toStringAsFixed(1)} kg',
              ),
              Container(
                width: 1,
                height: 60,
                color: AppColors.white.withValues(alpha: 0.3),
              ),
              _WeightHeroStat(
                label: 'BMI',
                value: bmi != null ? bmi.toStringAsFixed(1) : '—',
                sub: tracker.bmiCategory,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Progress to goal
        if (tracker.progressToGoal != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(
                color:
                    isDark ? AppColors.dividerDark : AppColors.dividerLight,
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
                      'Progress to Goal',
                      style: AppTypography.labelMedium.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${(tracker.progressToGoal! * 100).round()}%',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                  child: LinearProgressIndicator(
                    value: tracker.progressToGoal!,
                    minHeight: 8,
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Weight chart
        if (entries.length >= 2)
          NutritionChartCard(
            title: 'Weight Progress',
            subtitle: 'Last ${entries.length} measurements',
            height: 220,
            child: WeightProgressChart(
              values: entries
                  .map<double>((e) => e.weightKg as double)
                  .toList()
                  .reversed
                  .toList(),
              goalKg: tracker.goalKg,
            ),
          ),
        const SizedBox(height: AppSpacing.md),

        // BMI Reference
        _BmiReferenceCard(bmi: bmi, isDark: isDark),
        const SizedBox(height: AppSpacing.lg),

        // History
        Text(
          'History',
          style: AppTypography.titleMedium.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: _WeightEntryTile(entry: e, isDark: isDark),
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }
}

class _WeightHeroStat extends StatelessWidget {
  const _WeightHeroStat({required this.label, required this.value, this.sub});
  final String label;
  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: AppTypography.overline.copyWith(
            color: AppColors.white.withValues(alpha: 0.75),
          ),
        ),
        if (sub != null)
          Text(
            sub!,
            style: AppTypography.captionText.copyWith(
              color: AppColors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _BmiReferenceCard extends StatelessWidget {
  const _BmiReferenceCard({required this.bmi, required this.isDark});
  final double? bmi;
  final bool isDark;

  static const _ranges = [
    (label: 'Underweight', min: 0.0, max: 18.5, color: AppColors.chartSky),
    (label: 'Normal', min: 18.5, max: 25.0, color: AppColors.success),
    (label: 'Overweight', min: 25.0, max: 30.0, color: AppColors.chartAmber),
    (label: 'Obese', min: 30.0, max: 50.0, color: AppColors.chartCoral),
  ];

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
          Text(
            'BMI Reference',
            style: AppTypography.titleSmall.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._ranges.map((r) {
            final isCurrent = bmi != null &&
                bmi! >= r.min &&
                bmi! < r.max;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: r.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '${r.label} (${r.min == 0 ? '< ' : ''}${r.min > 0 ? '${r.min}–' : ''}${r.max < 50 ? r.max.toStringAsFixed(0) : '+'})',
                      style: AppTypography.bodySmall.copyWith(
                        color: isCurrent
                            ? r.color
                            : isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: r.color.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        'You',
                        style: AppTypography.overline.copyWith(
                          color: r.color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _WeightEntryTile extends StatelessWidget {
  const _WeightEntryTile({required this.entry, required this.isDark});
  final WeightEntry entry;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('dd MMM yyyy · hh:mm a').format(entry.measuredAt);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: AppSpacing.borderThin,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.monitor_weight_rounded,
              color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: AppTypography.captionText.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                if (entry.notes != null)
                  Text(
                    entry.notes!,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textHintDark
                          : AppColors.textHintLight,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${entry.weightKg.toStringAsFixed(1)} kg',
            style: AppTypography.titleSmall.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
