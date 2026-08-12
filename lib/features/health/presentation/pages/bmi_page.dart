import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/bmi_entity.dart';
import '../providers/health_providers.dart';
import '../providers/health_state.dart';
import '../widgets/bmi_gauge.dart';
import '../widgets/health_status_chip.dart';

/// BMI screen — gauge, calculator, healthy range, history.
class BmiPage extends ConsumerWidget {
  const BmiPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bmi = ref.watch(bmiProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'BMI',
          style: AppTypography.titleLarge.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: bmi == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Gauge Card ───────────────────────────────────────────────
                  _GaugeCard(bmi: bmi, isDark: isDark),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Healthy Range ────────────────────────────────────────────
                  _HealthyRangeCard(bmi: bmi, isDark: isDark),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Calculator ───────────────────────────────────────────────
                  _SectionLabel(label: 'BMI Calculator', isDark: isDark),
                  const SizedBox(height: AppSpacing.sm),
                  const _BmiCalculatorCard(),
                  const SizedBox(height: AppSpacing.lg),

                  // ── History ──────────────────────────────────────────────────
                  _SectionLabel(label: 'History', isDark: isDark),
                  const SizedBox(height: AppSpacing.sm),
                  ...bmi.history.asMap().entries.map(
                        (e) => _BmiHistoryTile(
                          entry: e.value,
                          isLast: e.key == bmi.history.length - 1,
                          isDark: isDark,
                        ),
                      ),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
    );
  }
}

// ── Gauge card ────────────────────────────────────────────────────────────────

class _GaugeCard extends StatelessWidget {
  const _GaugeCard({required this.bmi, required this.isDark});
  final BmiEntity bmi;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: AppSpacing.borderThin,
        ),
      ),
      child: Column(
        children: [
          BmiGauge(bmiValue: bmi.value, category: bmi.category, size: 260),
          const SizedBox(height: AppSpacing.md),
          HealthStatusChip.bmi(bmi.category),
          const SizedBox(height: AppSpacing.xs),
          Text(
            bmi.category.advice,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Healthy range card ────────────────────────────────────────────────────────

class _HealthyRangeCard extends StatelessWidget {
  const _HealthyRangeCard({required this.bmi, required this.isDark});
  final BmiEntity bmi;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.07),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.success,
            size: AppSpacing.iconMd,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Healthy Weight Range',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${bmi.healthyMinKg.toStringAsFixed(1)} kg – '
                  '${bmi.healthyMaxKg.toStringAsFixed(1)} kg '
                  'for ${bmi.heightCm.toStringAsFixed(0)} cm height',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
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

// ── BMI Calculator ────────────────────────────────────────────────────────────

class _BmiCalculatorCard extends ConsumerStatefulWidget {
  const _BmiCalculatorCard();

  @override
  ConsumerState<_BmiCalculatorCard> createState() =>
      _BmiCalculatorCardState();
}

class _BmiCalculatorCardState extends ConsumerState<_BmiCalculatorCard> {
  final _heightCtrl = TextEditingController(text: '170');
  final _weightCtrl = TextEditingController(text: '70');

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calcState = ref.watch(bmiCalculatorProvider);
    final notifier = ref.read(bmiCalculatorProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMetric = calcState.unit == BmiUnitSystem.metric;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: AppSpacing.borderThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Unit toggle
          Row(
            children: [
              Expanded(
                child: _UnitToggle(
                  label: 'Metric',
                  selected: isMetric,
                  onTap: () {
                    if (!isMetric) notifier.toggleUnit();
                  },
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _UnitToggle(
                  label: 'Imperial',
                  selected: !isMetric,
                  onTap: () {
                    if (isMetric) notifier.toggleUnit();
                  },
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Inputs
          if (isMetric) ...[
            _NumberSlider(
              label: 'Height',
              unit: 'cm',
              value: calcState.heightCm,
              min: 100,
              max: 220,
              onChanged: notifier.updateHeightCm,
              isDark: isDark,
            ),
            const SizedBox(height: AppSpacing.sm),
            _NumberSlider(
              label: 'Weight',
              unit: 'kg',
              value: calcState.weightKg,
              min: 30,
              max: 200,
              onChanged: notifier.updateWeightKg,
              isDark: isDark,
            ),
          ] else ...[
            _NumberSlider(
              label: 'Height (ft)',
              unit: 'ft',
              value: calcState.heightFt,
              min: 3,
              max: 8,
              divisions: 5,
              onChanged: notifier.updateHeightFt,
              isDark: isDark,
            ),
            const SizedBox(height: AppSpacing.sm),
            _NumberSlider(
              label: 'Height (in)',
              unit: 'in',
              value: calcState.heightIn,
              min: 0,
              max: 11,
              divisions: 11,
              onChanged: notifier.updateHeightIn,
              isDark: isDark,
            ),
            const SizedBox(height: AppSpacing.sm),
            _NumberSlider(
              label: 'Weight',
              unit: 'lb',
              value: calcState.weightLb,
              min: 66,
              max: 440,
              onChanged: notifier.updateWeightLb,
              isDark: isDark,
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // Calculate button
          FilledButton(
            onPressed: notifier.calculate,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.chartIndigo,
              foregroundColor: AppColors.white,
              padding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.md - 2),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
            child: Text(
              'Calculate BMI',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // Result
          if (calcState.calculatedBmi != null) ...[
            const SizedBox(height: AppSpacing.md),
            _CalcResult(bmi: calcState.calculatedBmi!, isDark: isDark),
          ],
        ],
      ),
    );
  }
}

class _CalcResult extends StatelessWidget {
  const _CalcResult({required this.bmi, required this.isDark});
  final double bmi;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cat = BmiEntity.categoryForValue(bmi);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.chartIndigo.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Your BMI: ',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          Text(
            bmi.toStringAsFixed(1),
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.chartIndigo,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          HealthStatusChip.bmi(cat),
        ],
      ),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  const _UnitToggle({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.chartIndigo.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: selected
                ? AppColors.chartIndigo
                : isDark
                    ? AppColors.dividerDark
                    : AppColors.dividerLight,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.labelMedium.copyWith(
            color: selected
                ? AppColors.chartIndigo
                : isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _NumberSlider extends StatelessWidget {
  const _NumberSlider({
    required this.label,
    required this.unit,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.isDark,
    this.divisions,
  });

  final String label;
  final String unit;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            Text(
              '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)} $unit',
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.chartIndigo,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions ?? (max - min).toInt(),
          onChanged: onChanged,
          activeColor: AppColors.chartIndigo,
          inactiveColor: AppColors.chartIndigo.withOpacity(0.2),
        ),
      ],
    );
  }
}

class _BmiHistoryTile extends StatelessWidget {
  const _BmiHistoryTile({
    required this.entry,
    required this.isLast,
    required this.isDark,
  });
  final BmiHistoryEntry entry;
  final bool isLast;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cat = BmiEntity.categoryForValue(entry.value);
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
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
          Text(
            entry.value.toStringAsFixed(1),
            style: AppTypography.titleMedium.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          HealthStatusChip.bmi(cat),
          const Spacer(),
          Text(
            '${entry.weightKg.toStringAsFixed(1)} kg',
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.titleMedium.copyWith(
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
