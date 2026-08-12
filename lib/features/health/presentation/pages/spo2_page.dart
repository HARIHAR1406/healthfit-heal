import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../../home/presentation/widgets/circular_progress_ring.dart';
import '../../domain/entities/spo2_entity.dart';
import '../providers/health_providers.dart';
import '../widgets/add_reading_bottom_sheet.dart';
import '../widgets/health_reading_tile.dart';
import '../widgets/health_status_chip.dart';

/// SpO₂ (oxygen saturation) detail screen.
class Spo2Page extends ConsumerWidget {
  const Spo2Page({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spo2 = ref.watch(spo2Provider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'SpO₂',
          style: AppTypography.titleLarge.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded),
            color: AppColors.chartSky,
            tooltip: 'Add Reading',
            onPressed: () =>
                AddReadingBottomSheet.show(context, AddReadingType.spo2),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: spo2 == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── SpO₂ Ring Card ───────────────────────────────────────────
                  _Spo2RingCard(
                    percentage: spo2.currentPercentage,
                    status: spo2.status,
                    isDark: isDark,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Info Card ────────────────────────────────────────────────
                  _InfoCard(description: spo2.status.description, isDark: isDark),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Normal Range Banner ──────────────────────────────────────
                  _RangeBanner(isDark: isDark),
                  const SizedBox(height: AppSpacing.lg),

                  // ── History ──────────────────────────────────────────────────
                  Text(
                    'Reading History',
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXl),
                    child: Column(
                      children:
                          spo2.history.asMap().entries.map((e) {
                        final r = e.value;
                        final isFirst = e.key == 0;
                        final isLast = e.key == spo2.history.length - 1;
                        return HealthReadingTile(
                          title: '${r.percentage}%',
                          value: '',
                          timestamp: r.timestamp,
                          iconData: Icons.air_rounded,
                          iconColor: AppColors.chartSky,
                          statusWidget: HealthStatusChip.spo2(r.status),
                          isFirst: isFirst,
                          isLast: isLast,
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'spo2_fab',
        onPressed: () =>
            AddReadingBottomSheet.show(context, AddReadingType.spo2),
        backgroundColor: AppColors.chartSky,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Reading'),
      ),
    );
  }
}

class _Spo2RingCard extends StatelessWidget {
  const _Spo2RingCard({
    required this.percentage,
    required this.status,
    required this.isDark,
  });
  final int percentage;
  final Spo2Status status;
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
          CircularProgressRing(
            fraction: percentage / 100.0,
            size: 180,
            strokeWidth: 16,
            color: AppColors.chartSky,
            centerWidget: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$percentage%',
                  style: AppTypography.headlineLarge.copyWith(
                    color: AppColors.chartSky,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'SpO₂',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          HealthStatusChip.spo2(status),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.description, required this.isDark});
  final String description;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.chartSky.withOpacity(0.07),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border:
            Border.all(color: AppColors.chartSky.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.chartSky, size: AppSpacing.iconMd),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              description,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeBanner extends StatelessWidget {
  const _RangeBanner({required this.isDark});
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
          Text(
            'Normal Ranges',
            style: AppTypography.titleSmall.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _Row(label: 'Normal', range: '95–100%', color: AppColors.success, isDark: isDark),
          _Row(label: 'Monitor', range: '90–94%', color: AppColors.warning, isDark: isDark),
          _Row(label: 'Critical — Seek care', range: '< 90%', color: AppColors.error, isDark: isDark),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.range, required this.color, required this.isDark});
  final String label;
  final String range;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: AppTypography.bodySmall.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ))),
          Text(range, style: AppTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

