import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/blood_sugar_entity.dart';
import '../providers/health_providers.dart';
import '../widgets/add_reading_bottom_sheet.dart';
import '../widgets/health_chart_card.dart';
import '../widgets/health_reading_tile.dart';
import '../widgets/health_status_chip.dart';

/// Blood Sugar detail screen.
class BloodSugarPage extends ConsumerStatefulWidget {
  const BloodSugarPage({super.key});

  @override
  ConsumerState<BloodSugarPage> createState() => _BloodSugarPageState();
}

class _BloodSugarPageState extends ConsumerState<BloodSugarPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sugar = ref.watch(bloodSugarProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Blood Sugar',
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
            color: AppColors.chartAmber,
            tooltip: 'Add Reading',
            onPressed: () => AddReadingBottomSheet.show(
                context, AddReadingType.bloodSugar),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: sugar == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Fasting / Post-Meal Cards ────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _SugarCard(
                          label: 'Fasting',
                          value: sugar.latestFasting?.value,
                          status: sugar.latestFasting != null
                              ? BloodSugarEntity.statusForReading(
                                  sugar.latestFasting!.value,
                                  BloodSugarType.fasting,
                                )
                              : null,
                          color: AppColors.chartAmber,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _SugarCard(
                          label: 'Post-Meal',
                          value: sugar.latestPostMeal?.value,
                          status: sugar.latestPostMeal != null
                              ? BloodSugarEntity.statusForReading(
                                  sugar.latestPostMeal!.value,
                                  BloodSugarType.postMeal,
                                )
                              : null,
                          color: AppColors.chartCoral,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Trend Chart ──────────────────────────────────────────────
                  HealthChartCard(
                    title: 'Sugar Trend',
                    subtitle: 'mg/dL over recent readings',
                    height: 170,
                    chart: HealthLineChart(
                      values: sugar.trendData,
                      color: AppColors.chartAmber,
                      minY: 60,
                      maxY: 250,
                      showDots: true,
                      showTooltip: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Reference Ranges ─────────────────────────────────────────
                  _ReferenceCard(isDark: isDark),
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
                          sugar.history.asMap().entries.map((e) {
                        final r = e.value;
                        final isFirst = e.key == 0;
                        final isLast = e.key == sugar.history.length - 1;
                        return HealthReadingTile(
                          title: r.formattedValue,
                          value: '',
                          timestamp: r.timestamp,
                          subtitle: r.type.label,
                          iconData: Icons.water_drop_rounded,
                          iconColor: AppColors.chartAmber,
                          statusWidget:
                              HealthStatusChip.bloodSugar(r.status),
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
        heroTag: 'sugar_fab',
        onPressed: () =>
            AddReadingBottomSheet.show(context, AddReadingType.bloodSugar),
        backgroundColor: AppColors.chartAmber,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Reading'),
      ),
    );
  }
}

class _SugarCard extends StatelessWidget {
  const _SugarCard({
    required this.label,
    required this.value,
    required this.status,
    required this.color,
    required this.isDark,
  });
  final String label;
  final double? value;
  final BloodSugarStatus? status;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value != null
                ? '${value!.toStringAsFixed(0)} mg/dL'
                : '— mg/dL',
            style: AppTypography.titleLarge.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          if (status != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            HealthStatusChip.bloodSugar(status!),
          ],
        ],
      ),
    );
  }
}

class _ReferenceCard extends StatelessWidget {
  const _ReferenceCard({required this.isDark});
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
            'ADA Reference Ranges',
            style: AppTypography.titleSmall.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _RangeRow(label: 'Normal (Fasting)', range: '< 100 mg/dL', color: AppColors.success, isDark: isDark),
          _RangeRow(label: 'Pre-Diabetes (Fasting)', range: '100–125 mg/dL', color: AppColors.warning, isDark: isDark),
          _RangeRow(label: 'Diabetes (Fasting)', range: '≥ 126 mg/dL', color: AppColors.error, isDark: isDark),
          _RangeRow(label: 'Normal (Post-Meal)', range: '< 140 mg/dL', color: AppColors.success, isDark: isDark),
          _RangeRow(label: 'Pre-Diabetes (Post)', range: '140–199 mg/dL', color: AppColors.warning, isDark: isDark),
          _RangeRow(label: 'Diabetes (Post-Meal)', range: '≥ 200 mg/dL', color: AppColors.error, isDark: isDark),
        ],
      ),
    );
  }
}

class _RangeRow extends StatelessWidget {
  const _RangeRow({required this.label, required this.range, required this.color, required this.isDark});
  final String label;
  final String range;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            )),
          ),
          Text(range, style: AppTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

