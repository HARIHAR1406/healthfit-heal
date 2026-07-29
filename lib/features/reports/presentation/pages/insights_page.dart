import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/route_names.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/health_insight_entity.dart';
import '../providers/analytics_notifier.dart';
import '../providers/analytics_providers.dart';
import '../providers/analytics_state.dart';
import '../providers/reports_providers.dart';
import '../widgets/analytics_widgets.dart';

// ══════════════════════════════════════════════════════════════════════════════
// AI HEALTH INSIGHTS PAGE
// ══════════════════════════════════════════════════════════════════════════════

/// Full insights page — daily / weekly / monthly AI insights, risk alerts,
/// recommendations, and achievements with live filter controls.
class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});

  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  final _tabDefs = const [
    _Tab('All', null),
    _Tab('Daily', InsightType.daily),
    _Tab('Weekly', InsightType.weekly),
    _Tab('Monthly', InsightType.monthly),
    _Tab('Alerts', InsightType.riskAlert),
    _Tab('Goals', InsightType.achievement),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _tabDefs.length, vsync: this);
    _tabs.addListener(_onTabChanged);
    _loadInsights();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _loadInsights() {
    final filter = ref.read(analyticsFilterProvider);
    ref.read(insightNotifierProvider.notifier).load(filter);
  }

  void _onTabChanged() {
    if (!_tabs.indexIsChanging) {
      final type = _tabDefs[_tabs.index].type;
      ref.read(insightNotifierProvider.notifier).setTypeFilter(type);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(insightNotifierProvider);
    final unreadCount = ref.watch(unreadInsightCountProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          // ── App Bar ────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            snap: true,
            pinned: true,
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
            surfaceTintColor: Colors.transparent,
            leading: const BackButton(),
            actions: [
              // Mark all read
              if (unreadCount > 0)
                TextButton(
                  onPressed: () =>
                      ref.read(insightNotifierProvider.notifier).markAllRead(),
                  child: Text(
                    'Mark All Read',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              // Filter
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                tooltip: 'Filter',
                onPressed: () => FilterBottomSheet.show(
                  context,
                  currentFilter: ref.read(analyticsFilterProvider),
                  onApply: (f) {
                    ref.read(analyticsFilterProvider.notifier).state = f;
                    _loadInsights();
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                  left: AppSpacing.xxl, bottom: AppSpacing.md + 48),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Health Insights',
                    style: AppTypography.titleLarge.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (unreadCount > 0)
                    Text(
                      '$unreadCount unread',
                      style: AppTypography.captionText.copyWith(
                          color: AppColors.primary),
                    ),
                ],
              ),
            ),
            bottom: TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              indicatorColor: AppColors.primary,
              labelStyle: AppTypography.bodySmall
                  .copyWith(fontWeight: FontWeight.w700),
              unselectedLabelStyle: AppTypography.bodySmall,
              tabs: _tabDefs
                  .map((t) => Tab(
                        text: t.label,
                        icon: t.type == InsightType.riskAlert
                            ? const Icon(Icons.warning_amber_rounded, size: 14)
                            : null,
                        iconMargin: EdgeInsets.zero,
                      ))
                  .toList(),
            ),
          ),
        ],
        body: _buildBody(state, isDark),
      ),
    );
  }

  Widget _buildBody(InsightsState state, bool isDark) {
    if (state is InsightsInitial || state is InsightsLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (state is InsightsError) {
      return _ErrorView(message: state.message, onRetry: _loadInsights);
    }

    final loaded = state as InsightsLoaded;
    final insights = loaded.filtered;

    if (insights.isEmpty) {
      return _EmptyInsights(isDark: isDark);
    }

    return CustomScrollView(
      slivers: [
        // ── Summary banner ───────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _InsightsSummaryBanner(
              report: loaded.report,
              isDark: isDark,
            ),
          ),
        ),

        // ── Insights list ────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverList.builder(
            itemCount: insights.length,
            itemBuilder: (_, i) {
              final ins = insights[i];
              return Semantics(
                label: '${ins.priority.label} insight: ${ins.title}',
                child: InsightCard(
                  key: ValueKey(ins.id),
                  insight: ins,
                  isDark: isDark,
                  onMarkRead: () =>
                      ref.read(insightNotifierProvider.notifier).markRead(ins.id),
                ),
              );
            },
          ),
        ),

        const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.massive)),
      ],
    );
  }
}

// ── Summary Banner ────────────────────────────────────────────────────────────

class _InsightsSummaryBanner extends StatelessWidget {
  const _InsightsSummaryBanner({
    required this.report,
    required this.isDark,
  });
  final InsightsReport report;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2A4A), Color(0xFF0A1628)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BannerStat(
            value: report.totalInsights.toString(),
            label: 'Total',
            emoji: '🧠',
          ),
          _BannerStat(
            value: report.unreadCount.toString(),
            label: 'Unread',
            emoji: '🔵',
          ),
          _BannerStat(
            value: report.criticalCount.toString(),
            label: 'Alerts',
            emoji: '⚠️',
          ),
          _BannerStat(
            value: report.positiveCount.toString(),
            label: 'Positive',
            emoji: '✅',
          ),
        ],
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  const _BannerStat({
    required this.value,
    required this.label,
    required this.emoji,
  });
  final String value;
  final String label;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: AppTypography.captionText.copyWith(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _EmptyInsights extends StatelessWidget {
  const _EmptyInsights({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🧠', style: TextStyle(fontSize: 56)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No insights for this filter',
            style: AppTypography.titleSmall.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Try changing the time range or category filter.',
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Tab definition ─────────────────────────────────────────────────────────

class _Tab {
  const _Tab(this.label, this.type);
  final String label;
  final InsightType? type;
}

// ── Shared error view ──────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              color: AppColors.error.withValues(alpha: 0.5), size: 48),
          const SizedBox(height: AppSpacing.sm),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
