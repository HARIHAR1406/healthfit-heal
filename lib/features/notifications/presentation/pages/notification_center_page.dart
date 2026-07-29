import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notification_notifier.dart';
import '../providers/notification_providers.dart';
import '../providers/notification_state.dart';
import '../widgets/notification_widgets.dart';

// ══════════════════════════════════════════════════════════════════════════════
// NOTIFICATION CENTER PAGE
// ══════════════════════════════════════════════════════════════════════════════

class NotificationCenterPage extends ConsumerStatefulWidget {
  const NotificationCenterPage({super.key});

  @override
  ConsumerState<NotificationCenterPage> createState() =>
      _NotificationCenterPageState();
}

class _NotificationCenterPageState
    extends ConsumerState<NotificationCenterPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  late final AnimationController _fabAnim;

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(notificationNotifierProvider) is NotificationInitial) {
        ref.read(notificationNotifierProvider.notifier).load();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(notificationNotifierProvider);
    final unread = ref.watch(unreadNotificationCountProvider);
    final catCounts = ref.watch(categoryUnreadCountsProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ───────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 130,
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => context.pop(),
            ),
            title: _isSearching
                ? _SearchField(
                    controller: _searchController,
                    onChanged: (q) => ref
                        .read(notificationNotifierProvider.notifier)
                        .setSearch(q),
                    onClose: () {
                      setState(() => _isSearching = false);
                      _searchController.clear();
                      ref
                          .read(notificationNotifierProvider.notifier)
                          .setSearch('');
                    },
                  )
                : null,
            actions: _isSearching
                ? []
                : [
                    // Search
                    IconButton(
                      icon: const Icon(Icons.search_rounded),
                      onPressed: () =>
                          setState(() => _isSearching = true),
                    ),
                    // Mark all read
                    if (unread > 0)
                      IconButton(
                        icon: const Icon(Icons.done_all_rounded),
                        tooltip: 'Mark all read',
                        onPressed: () => ref
                            .read(notificationNotifierProvider.notifier)
                            .markAllRead(),
                      ),
                    // Settings
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () =>
                          context.push(RouteNames.notificationSettings),
                    ),
                    // Clear all
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_rounded),
                      tooltip: 'Clear all',
                      onPressed: () =>
                          _showClearAllDialog(context),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
            flexibleSpace: _isSearching
                ? null
                : FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: _NotifHeader(
                        isDark: isDark, unreadCount: unread),
                  ),
          ),

          // ── Filter Chips ──────────────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterBarDelegate(
              child: Container(
                color: isDark
                    ? AppColors.backgroundDark
                    : AppColors.surfaceLight,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: state is NotificationLoaded
                    ? NotificationFilterChips(
                        activeCategory: state.activeCategory,
                        categoryCounts: catCounts,
                        onSelected: (cat) => ref
                            .read(notificationNotifierProvider.notifier)
                            .setCategory(cat),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────────
          switch (state) {
            NotificationLoading() || NotificationInitial() =>
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            NotificationError(:final message) => SliverFillRemaining(
                child: NotificationEmptyState(
                  message: message,
                  icon: Icons.error_outline_rounded,
                  action: FilledButton.icon(
                    onPressed: () => ref
                        .read(notificationNotifierProvider.notifier)
                        .load(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ),
              ),
            NotificationLoaded(:final filtered) => filtered.isEmpty
                ? const SliverFillRemaining(
                    child: NotificationEmptyState(
                      message: 'No notifications here.\nYou\'re all caught up! ✓',
                      icon: Icons.notifications_none_rounded,
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, AppSpacing.sm, AppSpacing.md, 100),
                    sliver: SliverList.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final notif = filtered[i];
                        return Semantics(
                          label: '${notif.title}. ${notif.body}. '
                              '${notif.isRead ? 'Read' : 'Unread'}. '
                              '${notif.timeLabel}.',
                          child: NotificationCard(
                            key: ValueKey(notif.id),
                            notification: notif,
                            onTap: () {
                              ref
                                  .read(notificationNotifierProvider.notifier)
                                  .markRead(notif.id);
                              if (notif.actionRoute != null) {
                                context.push(notif.actionRoute!);
                              }
                            },
                            onDismiss: () => ref
                                .read(notificationNotifierProvider.notifier)
                                .delete(notif.id),
                          ),
                        );
                      },
                    ),
                  ),
          },
        ],
      ),

      // FAB: Reminders shortcut
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.reminderManager),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.alarm_rounded, color: AppColors.white),
        label: Text(
          'Reminders',
          style:
              AppTypography.labelLarge.copyWith(color: AppColors.white),
        ),
      ),
    );
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear All Notifications?'),
        content: const Text(
            'This will permanently delete all notifications in your inbox.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(notificationNotifierProvider.notifier).clearAll();
            },
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

// ── Notification Header ────────────────────────────────────────────────────────

class _NotifHeader extends StatelessWidget {
  const _NotifHeader({required this.isDark, required this.unreadCount});
  final bool isDark;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0D1B2A), const Color(0xFF1A2A3A)]
              : [const Color(0xFFE8F4FD), const Color(0xFFF8FAFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF00B4D8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusLg),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.notifications_rounded,
                        color: AppColors.white, size: 26),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notification Center',
                        style: AppTypography.headlineSmall.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        unreadCount > 0
                            ? '$unreadCount unread notification${unreadCount > 1 ? 's' : ''}'
                            : 'All caught up! ✓',
                        style: AppTypography.bodySmall.copyWith(
                          color: unreadCount > 0
                              ? AppColors.primary
                              : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Search Field ──────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClose,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      autofocus: true,
      onChanged: onChanged,
      style: AppTypography.bodyMedium.copyWith(
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
      decoration: InputDecoration(
        hintText: 'Search notifications…',
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
        border: InputBorder.none,
        suffixIcon: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: onClose,
        ),
      ),
    );
  }
}

// ── Filter Bar Delegate ────────────────────────────────────────────────────────

class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  const _FilterBarDelegate({required this.child});
  final Widget child;

  @override
  double get maxExtent => 56;
  @override
  double get minExtent => 56;

  @override
  bool shouldRebuild(covariant _FilterBarDelegate oldDelegate) =>
      child != oldDelegate.child;

  @override
  Widget build(BuildContext _, double __, bool ___) => child;
}
