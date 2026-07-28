import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../providers/health_providers.dart';
import '../providers/health_state.dart';
import '../widgets/health_action_tile.dart';
import '../widgets/health_status_chip.dart';

/// Home screen of the Health Module.
///
/// Displays:
///   - Health Score hero card
///   - Today's quick-access metric tiles
///   - Medical records overview
class HealthDashboardPage extends ConsumerStatefulWidget {
  const HealthDashboardPage({super.key});

  @override
  ConsumerState<HealthDashboardPage> createState() =>
      _HealthDashboardPageState();
}

class _HealthDashboardPageState extends ConsumerState<HealthDashboardPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(healthNotifierProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(healthNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      body: switch (state) {
        HealthLoading() => const AppLoadingIndicator(size: 52),
        HealthInitial() => const AppLoadingIndicator(size: 52),
        HealthError(:final message) => AppErrorWidget(
            message: message,
            onRetry: () =>
                ref.read(healthNotifierProvider.notifier).load(),
          ),
        _ => _Body(
            isDark: isDark,
            onRefresh: () =>
                ref.read(healthNotifierProvider.notifier).refresh(),
          ),
      },
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends ConsumerWidget {
  const _Body({required this.isDark, required this.onRefresh});
  final bool isDark;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(healthDataProvider);
    if (data == null) return const AppLoadingIndicator(size: 52);

    final isRefreshing = ref.watch(healthNotifierProvider) is HealthRefreshing;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.secondary,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // App Bar
          SliverAppBar(
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
            floating: true,
            snap: true,
            elevation: 0,
            title: Text(
              'Health',
              style: AppTypography.titleLarge.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.history_rounded,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                tooltip: 'Health History',
                onPressed: () => context.push(RouteNames.healthHistory),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (isRefreshing) _RefreshBanner(),

                // ── Health Score Card ────────────────────────────────────────
                _HealthScoreCard(
                  score: data.healthScore,
                  status: data.healthStatus,
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Quick Access ─────────────────────────────────────────────
                _SectionTitle(title: 'Quick Access', isDark: isDark),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 138,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      HealthActionTile(
                        icon: Icons.monitor_weight_outlined,
                        label: 'BMI',
                        color: AppColors.chartIndigo,
                        route: RouteNames.bmi,
                        value: data.bmi.formatted,
                        unit: 'kg/m²',
                        statusWidget: HealthStatusChip.bmi(data.bmi.category),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      HealthActionTile(
                        icon: Icons.favorite_rounded,
                        label: 'Heart Rate',
                        color: AppColors.chartCoral,
                        route: RouteNames.heartRate,
                        value: '${data.heartRate.currentBpm}',
                        unit: 'bpm',
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      HealthActionTile(
                        icon: Icons.bloodtype_rounded,
                        label: 'Blood Pressure',
                        color: AppColors.secondary,
                        route: RouteNames.bloodPressure,
                        value: data.bloodPressure.latestReading.formatted,
                        unit: 'mmHg',
                        statusWidget: HealthStatusChip.bloodPressure(
                          data.bloodPressure.latestReading.status,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      HealthActionTile(
                        icon: Icons.water_drop_rounded,
                        label: 'Blood Sugar',
                        color: AppColors.chartAmber,
                        route: RouteNames.bloodSugar,
                        value:
                            '${data.bloodSugar.latestFasting?.value.toStringAsFixed(0) ?? '—'}',
                        unit: 'mg/dL',
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      HealthActionTile(
                        icon: Icons.air_rounded,
                        label: 'SpO₂',
                        color: AppColors.chartSky,
                        route: RouteNames.spo2,
                        value: '${data.spo2.currentPercentage}',
                        unit: '%',
                        statusWidget:
                            HealthStatusChip.spo2(data.spo2.status),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Today's Status ───────────────────────────────────────────
                _SectionTitle(title: "Today's Status", isDark: isDark),
                const SizedBox(height: AppSpacing.sm),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 1.6,
                  children: [
                    _MiniStatCard(
                      icon: Icons.favorite_rounded,
                      label: 'Heart Rate',
                      value: '${data.heartRate.currentBpm} bpm',
                      color: AppColors.chartCoral,
                      isDark: isDark,
                    ),
                    _MiniStatCard(
                      icon: Icons.bloodtype_rounded,
                      label: 'Blood Pressure',
                      value: data.bloodPressure.latestReading.formatted,
                      color: AppColors.secondary,
                      isDark: isDark,
                    ),
                    _MiniStatCard(
                      icon: Icons.water_drop_rounded,
                      label: 'Blood Sugar',
                      value:
                          '${data.bloodSugar.latestFasting?.value.toStringAsFixed(0) ?? '—'} mg/dL',
                      color: AppColors.chartAmber,
                      isDark: isDark,
                    ),
                    _MiniStatCard(
                      icon: Icons.air_rounded,
                      label: 'SpO₂',
                      value: '${data.spo2.currentPercentage}%',
                      color: AppColors.chartSky,
                      isDark: isDark,
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Medical Overview ─────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child:
                          _SectionTitle(title: 'Medical Overview', isDark: isDark),
                    ),
                    TextButton(
                      onPressed: () => context.push(RouteNames.medicalRecords),
                      child: Text(
                        'See All',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ...data.recentRecords.take(3).map(
                      (r) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: MedicalRecordTile(record: r),
                      ),
                    ),

                const SizedBox(height: AppSpacing.xxxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Health Score Card ─────────────────────────────────────────────────────────

class _HealthScoreCard extends StatelessWidget {
  const _HealthScoreCard({
    required this.score,
    required this.status,
    required this.isDark,
  });

  final int score;
  final String status;
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
            color: AppColors.secondary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    '✦  Health Score',
                    style: AppTypography.overline.copyWith(
                      color: AppColors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '$score / 100',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  status,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Progress bar
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                  child: LinearProgressIndicator(
                    value: score / 100.0,
                    backgroundColor:
                        AppColors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.white),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Icon(
            Icons.health_and_safety_rounded,
            size: 72,
            color: AppColors.white.withValues(alpha: 0.25),
          ),
        ],
      ),
    );
  }
}

// ── Mini Stat Card ────────────────────────────────────────────────────────────

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
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
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: color, size: AppSpacing.iconSm),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
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
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.isDark});
  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.titleMedium.copyWith(
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _RefreshBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Refreshing…',
            style: AppTypography.bodySmall.copyWith(color: AppColors.secondary),
          ),
        ],
      ),
    );
  }
}
