import 'package:flutter/material.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/bmi_entity.dart';
import '../../domain/entities/blood_pressure_entity.dart';
import '../../domain/entities/blood_sugar_entity.dart';
import '../../domain/entities/spo2_entity.dart';

/// Compact chip showing a health status label with a colored dot.
class HealthStatusChip extends StatelessWidget {
  const HealthStatusChip({
    required this.label,
    required this.color,
    super.key,
    this.showDot = true,
  });

  final String label;
  final Color color;
  final bool showDot;

  // ── Named constructors ────────────────────────────────────────────────────

  factory HealthStatusChip.bmi(BmiCategory category) {
    return HealthStatusChip(
      label: category.label,
      color: switch (category) {
        BmiCategory.normalWeight => AppColors.success,
        BmiCategory.underweight => AppColors.chartSky,
        BmiCategory.overweight => AppColors.warning,
        BmiCategory.obese => AppColors.error,
      },
    );
  }

  factory HealthStatusChip.bloodPressure(BloodPressureStatus status) {
    return HealthStatusChip(
      label: status.label,
      color: switch (status) {
        BloodPressureStatus.normal => AppColors.success,
        BloodPressureStatus.elevated => AppColors.chartAmber,
        BloodPressureStatus.highStage1 => AppColors.warning,
        BloodPressureStatus.highStage2 => AppColors.error,
        BloodPressureStatus.hypertensiveCrisis => AppColors.error,
      },
    );
  }

  factory HealthStatusChip.bloodSugar(BloodSugarStatus status) {
    return HealthStatusChip(
      label: status.label,
      color: switch (status) {
        BloodSugarStatus.normal => AppColors.success,
        BloodSugarStatus.prediabetes => AppColors.warning,
        BloodSugarStatus.diabetes => AppColors.error,
      },
    );
  }

  factory HealthStatusChip.spo2(Spo2Status status) {
    return HealthStatusChip(
      label: status.label,
      color: switch (status) {
        Spo2Status.normal => AppColors.success,
        Spo2Status.low => AppColors.warning,
        Spo2Status.criticallyLow => AppColors.error,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
