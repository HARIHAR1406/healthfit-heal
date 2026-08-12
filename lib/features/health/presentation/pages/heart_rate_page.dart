import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../providers/health_providers.dart';
import '../widgets/health_chart_card.dart';
import '../widgets/health_reading_tile.dart';

/// Heart Rate detail screen — current BPM, weekly bar chart, history.
class HeartRatePage extends ConsumerWidget {
  const HeartRatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hr = ref.watch(heartRateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Heart Rate',
          style: AppTypography.titleLarge.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: hr == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Current BPM Card ─────────────────────────────────────────
                  _CurrentBpmCard(bpm: hr.currentBpm, isDark: isDark),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Averages Row ─────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _AvgCard(
                          label: 'Daily Avg',
                          value: '${hr.dailyAvg} bpm',
                          icon: Icons.today_rounded,
                          color: AppColors.chartCoral,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _AvgCard(
                          label: 'Weekly Avg',
                          value: '${hr.weeklyAvg} bpm',
                          icon: Icons.calendar_view_week_rounded,
                          color: AppColors.chartPink,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Weekly Bar Chart ─────────────────────────────────────────
                  HealthChartCard(
                    title: 'Weekly Average',
                    subtitle: 'Daily heart rate averages (bpm)',
                    height: 200,
                    chart: HealthBarChart(
                      values: hr.weeklyData.map((d) => d.avgBpm).toList(),
                      labels:
                          hr.weeklyData.map((d) => d.dayLabel).toList(),
                      color: AppColors.chartCoral,
                      maxY: 120,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Sensor placeholder ───────────────────────────────────────
                  _SensorCard(isDark: isDark),
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
                          hr.history.take(10).toList().asMap().entries.map(
                        (e) {
                          final reading = e.value;
                          final isFirst = e.key == 0;
                          final isLast = e.key ==
                              (hr.history.take(10).length - 1);
                          return HealthReadingTile(
                            title: '${reading.bpm} bpm',
                            value: '',
                            timestamp: reading.timestamp,
                            subtitle: reading.context.name,
                            iconData: Icons.favorite_rounded,
                            iconColor: AppColors.chartCoral,
                            isFirst: isFirst,
                            isLast: isLast,
                          );
                        },
                      ).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
    );
  }
}

// ── Current BPM Card ──────────────────────────────────────────────────────────

class _CurrentBpmCard extends StatelessWidget {
  const _CurrentBpmCard({required this.bpm, required this.isDark});
  final int bpm;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFFF6B6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        boxShadow: [
          BoxShadow(
            color: AppColors.chartCoral.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.favorite_rounded,
            color: AppColors.white,
            size: 60,
          ),
          const SizedBox(width: AppSpacing.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.white.withOpacity(0.8),
                ),
              ),
              Text(
                '$bpm',
                style: AppTypography.headlineLarge.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 52,
                ),
              ),
              Text(
                'beats per minute',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvgCard extends StatelessWidget {
  const _AvgCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
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
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: color, size: AppSpacing.iconSm),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.captionText.copyWith(
                  color: isDark
                      ? AppColors.textHintDark
                      : AppColors.textHintLight,
                ),
              ),
              Text(
                value,
                style: AppTypography.titleSmall.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  const _SensorCard({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.chartCoral.withOpacity(0.07),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border:
            Border.all(color: AppColors.chartCoral.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.watch_rounded,
              color: AppColors.chartCoral, size: AppSpacing.iconLg),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connect a Wearable',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.chartCoral,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Pair your smartwatch for real-time continuous heart rate monitoring.',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    height: 1.4,
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
