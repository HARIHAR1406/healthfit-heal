import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/blood_pressure_entity.dart';
import '../providers/health_providers.dart';
import '../widgets/add_reading_bottom_sheet.dart';
import '../widgets/health_chart_card.dart';
import '../widgets/health_reading_tile.dart';
import '../widgets/health_status_chip.dart';

/// Blood Pressure detail screen.
class BloodPressurePage extends ConsumerWidget {
  const BloodPressurePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bp = ref.watch(bloodPressureProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Blood Pressure',
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
            color: AppColors.secondary,
            tooltip: 'Add Reading',
            onPressed: () =>
                AddReadingBottomSheet.show(context, AddReadingType.bloodPressure),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: bp == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Latest Reading Card ──────────────────────────────────────
                  _LatestCard(
                    sys: bp.latestReading.systolic,
                    dia: bp.latestReading.diastolic,
                    pulse: bp.latestReading.pulse,
                    status: bp.latestReading.status,
                    isDark: isDark,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Trend Chart ──────────────────────────────────────────────
                  HealthChartCard(
                    title: 'Trend',
                    subtitle: 'Systolic (red) / Diastolic (blue)',
                    height: 180,
                    chart: HealthLineChart(
                      values: bp.systolicTrend,
                      color: AppColors.chartCoral,
                      secondaryValues: bp.diastolicTrend,
                      secondaryColor: AppColors.chartSky,
                      minY: 50,
                      maxY: 180,
                      showTooltip: true,
                    ),
                  ),
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
                          bp.history.asMap().entries.map((e) {
                        final r = e.value;
                        final isFirst = e.key == 0;
                        final isLast = e.key == bp.history.length - 1;
                        return HealthReadingTile(
                          title: r.formatted,
                          value: r.pulse != null ? '${r.pulse} bpm' : '',
                          timestamp: r.timestamp,
                          subtitle: r.pulse != null
                              ? 'Pulse ${r.pulse} bpm'
                              : null,
                          iconData: Icons.bloodtype_rounded,
                          iconColor: AppColors.secondary,
                          statusWidget:
                              HealthStatusChip.bloodPressure(r.status),
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
        heroTag: 'bp_fab',
        onPressed: () =>
            AddReadingBottomSheet.show(context, AddReadingType.bloodPressure),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Reading'),
      ),
    );
  }
}

class _LatestCard extends StatelessWidget {
  const _LatestCard({
    required this.sys,
    required this.dia,
    required this.pulse,
    required this.status,
    required this.isDark,
  });
  final int sys;
  final int dia;
  final int? pulse;
  final BloodPressureStatus status;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, Color(0xFF00B4D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latest Reading',
            style: AppTypography.overline.copyWith(
              color: AppColors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sys',
                style: AppTypography.headlineLarge.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 52,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '/$dia',
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 8),
                child: Text(
                  'mmHg',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.white.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              HealthStatusChip.bloodPressure(status),
              if (pulse != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    '❤ $pulse bpm',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

