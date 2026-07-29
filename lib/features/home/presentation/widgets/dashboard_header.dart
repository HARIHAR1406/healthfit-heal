import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../shared/widgets/global_search_overlay.dart';
import '../providers/dashboard_providers.dart';

/// Sticky dashboard header bar.
///
/// Shows the user's greeting, current date, avatar, and notification badge.
class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final notificationCount = ref.watch(notificationCountProvider);
    final dashboardData = ref.watch(dashboardDataProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final greeting = dashboardData?.greeting ?? _computeGreeting();
    final dateStr = dashboardData?.currentDate ?? '';

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
        bottom: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: AppSpacing.borderThin,
          ),
        ),
      ),
      child: Row(
        children: [
          // ── User Avatar ──────────────────────────────────────────────────
          _UserAvatar(
            name: user?.fullName ?? 'User',
            avatarUrl: user?.avatarUrl,
          ),

          const SizedBox(width: AppSpacing.sm),

          // ── Greeting + Date ──────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$greeting, ${user?.firstName ?? 'User'}! 👋',
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (dateStr.isNotEmpty)
                  Text(
                    dateStr,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
              ],
            ),
          ),

          // ── Action Icons ─────────────────────────────────────────────────
          _SearchButton(isDark: isDark),
          const SizedBox(width: AppSpacing.xxs),
          _NotificationButton(count: notificationCount, isDark: isDark),
        ],
      ),
    );
  }

  static String _computeGreeting() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'Good Morning';
    if (h >= 12 && h < 17) return 'Good Afternoon';
    if (h >= 17 && h < 21) return 'Good Evening';
    return 'Good Night';
  }
}

// ── User Avatar ────────────────────────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.name, this.avatarUrl});

  final String name;
  final String? avatarUrl;

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'User avatar for $name',
      child: Container(
        width: AppSpacing.avatarSm + 4,
        height: AppSpacing.avatarSm + 4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: avatarUrl != null
            ? ClipOval(
                child: Image.network(
                  avatarUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _InitialsAvatar(initials: _initials),
                ),
              )
            : _InitialsAvatar(initials: _initials),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: AppTypography.labelMedium.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Action Buttons ─────────────────────────────────────────────────────────────

class _SearchButton extends StatelessWidget {
  const _SearchButton({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Search',
      button: true,
      child: IconButton(
        onPressed: () => showGlobalSearch(context),
        icon: Icon(
          Icons.search_rounded,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
        tooltip: 'Search',
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.count, required this.isDark});

  final int count;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: count > 0 ? '$count unread notifications' : 'Notifications',
      button: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: () => context.push(RouteNames.settings),
            icon: Icon(
              Icons.notifications_outlined,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            tooltip: 'Notifications',
          ),
          if (count > 0)
            Positioned(
              top: 6,
              right: 6,
              child: _NotificationBadge(count: count),
            ),
        ],
      ),
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  const _NotificationBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(
        color: AppColors.secondary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          count > 9 ? '9+' : '$count',
          style: AppTypography.overline.copyWith(
            color: AppColors.white,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
