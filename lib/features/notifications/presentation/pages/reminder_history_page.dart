import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/reminder_entity.dart';
import '../providers/notification_providers.dart';
import '../providers/reminder_notifier.dart';
import '../providers/reminder_state.dart';
import '../widgets/notification_widgets.dart';

// ══════════════════════════════════════════════════════════════════════════════
// REMINDER HISTORY PAGE
// ══════════════════════════════════════════════════════════════════════════════

class ReminderHistoryPage extends ConsumerStatefulWidget {
  const ReminderHistoryPage({super.key});

  @override
  ConsumerState<ReminderHistoryPage> createState() =>
      _ReminderHistoryPageState();
}

class _ReminderHistoryPageState extends ConsumerState<ReminderHistoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    (label: 'All', status: null as ReminderHistoryStatus?),
    (label: 'Done', status: ReminderHistoryStatus.completed),
    (label: 'Missed', status: ReminderHistoryStatus.missed),
    (label: 'Skipped', status: ReminderHistoryStatus.skipped),
    (label: 'Snoozed', status: ReminderHistoryStatus.snoozed),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(reminderHistoryNotifierProvider) is ReminderHistoryInitial) {
        ref.read(reminderHistoryNotifierProvider.notifier).load();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(reminderHistoryNotifierProvider);
    final stats = ref.watch(reminderStatisticsProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          // ── App Bar ─────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: stats != null ? 280 : 120,
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Reminder History',
              style: AppTypography.titleLarge.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w800,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _HistoryHeader(isDark: isDark, stats: stats),
            ),
          ),

          // ── Tab Bar ──────────────────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              tabBar: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                labelStyle: AppTypography.labelMedium
                    .copyWith(fontWeight: FontWeight.w700),
                onTap: (i) {
                  ref
                      .read(reminderHistoryNotifierProvider.notifier)
                      .setFilter(_tabs[i].status);
                },
                tabs: _tabs
                    .map((t) => Tab(text: t.label))
                    .toList(),
              ),
              isDark: isDark,
            ),
          ),
        ],
        body: _buildBody(state, isDark),
      ),
    );
  }

  Widget _buildBody(ReminderHistoryState state, bool isDark) {
    return switch (state) {
      ReminderHistoryLoading() || ReminderHistoryInitial() =>
        const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ReminderHistoryError(:final message) => NotificationEmptyState(
          message: message,
          icon: Icons.error_outline_rounded,
          action: FilledButton.icon(
            onPressed: () =>
                ref.read(reminderHistoryNotifierProvider.notifier).load(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ),
      ReminderHistoryLoaded(:final entries) => entries.isEmpty
          ? const NotificationEmptyState(
              message: 'No reminder history yet.\nStart logging your reminders!',
              icon: Icons.history_rounded,
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Today section
                  _HistoryGroup(
                    label: 'Today',
                    entries: entries
                        .where((e) => _isToday(e.scheduledAt))
                        .toList(),
                    isDark: isDark,
                  ),
                  // This week
                  _HistoryGroup(
                    label: 'This Week',
                    entries: entries
                        .where((e) =>
                            !_isToday(e.scheduledAt) &&
                            _isThisWeek(e.scheduledAt))
                        .toList(),
                    isDark: isDark,
                  ),
                  // Older
                  _HistoryGroup(
                    label: 'Older',
                    entries: entries
                        .where((e) => !_isThisWeek(e.scheduledAt))
                        .toList(),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
    };
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day;
  }

  bool _isThisWeek(DateTime dt) {
    final now = DateTime.now();
    return dt.isAfter(now.subtract(const Duration(days: 7)));
  }
}

// ── History Header ─────────────────────────────────────────────────────────────

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.isDark, this.stats});
  final bool isDark;
  final ReminderStatistics? stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0D1B2A), const Color(0xFF1C2A3A)]
              : [const Color(0xFFF3E5F5), const Color(0xFFF8FAFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFF6C63FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: const Icon(Icons.history_rounded,
                        color: AppColors.white, size: 28),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Reminder History',
                    style: AppTypography.headlineSmall.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (stats != null) ...[
                const SizedBox(height: AppSpacing.lg),
                ReminderStatisticsCard(statistics: stats!, isDark: isDark),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── History Group ──────────────────────────────────────────────────────────────

class _HistoryGroup extends StatelessWidget {
  const _HistoryGroup({
    required this.label,
    required this.entries,
    required this.isDark,
  });

  final String label;
  final List<ReminderHistoryEntry> entries;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(
            label.toUpperCase(),
            style: AppTypography.overline.copyWith(
              color: AppColors.primary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ReminderTimeline(entries: entries, isDark: isDark),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

// ── Tab Bar Delegate ───────────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate({required this.tabBar, required this.isDark});
  final TabBar tabBar;
  final bool isDark;

  @override
  double get maxExtent => 48;
  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) =>
      tabBar != oldDelegate.tabBar;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      child: tabBar,
    );
  }
}

