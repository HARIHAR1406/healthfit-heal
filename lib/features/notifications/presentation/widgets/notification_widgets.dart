import 'package:flutter/material.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/reminder_entity.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 1. NOTIFICATION BADGE
// ══════════════════════════════════════════════════════════════════════════════

/// Animated red badge showing unread count. Hides when count is 0.
class NotificationBadge extends StatelessWidget {
  const NotificationBadge({
    required this.count,
    required this.child,
    super.key,
  });

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            top: -4,
            right: -4,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: child,
              ),
              child: _Badge(count: count, key: ValueKey(count)),
            ),
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count, super.key});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: AppTypography.captionText.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w800,
          fontSize: 9,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 2. NOTIFICATION CARD
// ══════════════════════════════════════════════════════════════════════════════

/// Swipe-to-dismiss notification card with read/unread state.
class NotificationCard extends StatelessWidget {
  const NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
    super.key,
  });

  final NotificationEntity notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cat = notification.category;
    final isUnread = !notification.isRead;

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.white, size: 24),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isUnread
              ? (isDark
                  ? cat.color.withOpacity(0.08)
                  : cat.color.withOpacity(0.06))
              : (isDark ? AppColors.cardDark : AppColors.white),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: isUnread
                ? cat.color.withOpacity(0.25)
                : AppColors.dividerLight.withOpacity(0.5),
            width: AppSpacing.borderThin,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category icon
                  _CategoryIcon(category: cat),
                  const SizedBox(width: AppSpacing.sm),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isUnread)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: cat.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                notification.title,
                                style: AppTypography.titleSmall.copyWith(
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                  fontWeight: isUnread
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          notification.body,
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // Category chip
                            _CategoryChip(category: cat),
                            const Spacer(),
                            // Timestamp
                            Text(
                              notification.timeLabel,
                              style: AppTypography.captionText.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        // Action label
                        if (notification.actionLabel != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            notification.actionLabel!,
                            style: AppTypography.labelSmall.copyWith(
                              color: cat.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.category});
  final NotificationCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: category.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Icon(category.icon, color: category.color, size: 22),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});
  final NotificationCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: category.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        category.label,
        style: AppTypography.captionText.copyWith(
          color: category.color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 3. NOTIFICATION FILTER CHIPS
// ══════════════════════════════════════════════════════════════════════════════

class NotificationFilterChips extends StatelessWidget {
  const NotificationFilterChips({
    required this.activeCategory,
    required this.categoryCounts,
    required this.onSelected,
    super.key,
  });

  final NotificationCategory? activeCategory;
  final Map<NotificationCategory, int> categoryCounts;
  final ValueChanged<NotificationCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          // "All" chip
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: _FilterChip(
              label: 'All',
              isSelected: activeCategory == null,
              color: AppColors.primary,
              count: null,
              isDark: isDark,
              onTap: () => onSelected(null),
            ),
          ),
          ...NotificationCategory.values.map((cat) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: _FilterChip(
                  label: cat.label,
                  isSelected: activeCategory == cat,
                  color: cat.color,
                  count: categoryCounts[cat],
                  isDark: isDark,
                  onTap: () =>
                      onSelected(activeCategory == cat ? null : cat),
                ),
              )),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.isDark,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final int? count;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? color
                : isDark
                    ? AppColors.cardDark
                    : AppColors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.3),
              width: AppSpacing.borderThin,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected
                      ? AppColors.white
                      : isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (count != null && count! > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.white.withOpacity(0.3)
                        : color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    '$count',
                    style: AppTypography.captionText.copyWith(
                      color: isSelected ? AppColors.white : color,
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 4. REMINDER CARD
// ══════════════════════════════════════════════════════════════════════════════

class ReminderCard extends StatelessWidget {
  const ReminderCard({
    required this.reminder,
    required this.onToggle,
    required this.onEditTime,
    required this.onSnooze,
    required this.onSkip,
    required this.onDelete,
    super.key,
  });

  final ReminderEntity reminder;
  final VoidCallback onToggle;
  final VoidCallback onEditTime;
  final VoidCallback onSnooze;
  final VoidCallback onSkip;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = reminder.type.color;
    final isActive = reminder.isEnabled;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isActive
              ? color.withOpacity(0.25)
              : AppColors.dividerLight,
          width: AppSpacing.borderThin,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? color.withOpacity(0.06)
                : Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main row
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Type icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isActive
                        ? color.withOpacity(0.15)
                        : AppColors.dividerLight.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    reminder.type.icon,
                    color: isActive ? color : AppColors.textSecondaryLight,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: AppTypography.titleSmall.copyWith(
                          color: isActive
                              ? (isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight)
                              : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 12, color: color.withOpacity(0.7)),
                          const SizedBox(width: 3),
                          Text(
                            reminder.timeLabel,
                            style: AppTypography.captionText.copyWith(
                              color: color.withOpacity(0.9),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '· ${reminder.activeDaysLabel}',
                            style: AppTypography.captionText.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      if (reminder.status == ReminderStatus.snoozed)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Icon(Icons.snooze_rounded,
                                  size: 11,
                                  color: AppColors.warning
                                      .withOpacity(0.8)),
                              const SizedBox(width: 3),
                              Text(
                                'Snoozed',
                                style: AppTypography.captionText.copyWith(
                                  color: AppColors.warning,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Toggle
                Switch.adaptive(
                  value: isActive,
                  onChanged: (_) => onToggle(),
                  activeColor: color,
                ),
              ],
            ),
          ),

          // Action row (only when active)
          if (isActive) ...[
            Divider(
              height: 1,
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              child: Row(
                children: [
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    label: 'Edit Time',
                    color: color,
                    onTap: onEditTime,
                  ),
                  _ActionButton(
                    icon: Icons.snooze_rounded,
                    label: 'Snooze',
                    color: AppColors.warning,
                    onTap: onSnooze,
                  ),
                  _ActionButton(
                    icon: Icons.skip_next_rounded,
                    label: 'Skip',
                    color: AppColors.info,
                    onTap: onSkip,
                  ),
                  _ActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    color: AppColors.error,
                    onTap: onDelete,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.captionText.copyWith(
                    color: color, fontWeight: FontWeight.w600, fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 5. REMINDER STATISTICS CARD
// ══════════════════════════════════════════════════════════════════════════════

class ReminderStatisticsCard extends StatelessWidget {
  const ReminderStatisticsCard({
    required this.statistics,
    required this.isDark,
    super.key,
  });

  final ReminderStatistics statistics;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final adherencePct = (statistics.adherenceRate * 100).toInt();
    final color = adherencePct >= 80
        ? AppColors.primary
        : adherencePct >= 60
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Adherence ring
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: statistics.adherenceRate),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => CircularProgressIndicator(
                        value: v,
                        strokeWidth: 7,
                        backgroundColor: color.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                    Text(
                      '$adherencePct%',
                      style: AppTypography.titleSmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('30-Day Adherence',
                        style: AppTypography.titleSmall.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _StatPill('🔥 ${statistics.currentStreak}d streak', color),
                        const SizedBox(width: AppSpacing.xs),
                        _StatPill('🏆 ${statistics.bestStreak}d best',
                            AppColors.warning),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _StatsBox(
                  label: 'Completed',
                  value: '${statistics.completed}',
                  color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              _StatsBox(
                  label: 'Missed',
                  value: '${statistics.missed}',
                  color: statistics.missed > 0 ? AppColors.error : AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              _StatsBox(
                  label: 'Skipped',
                  value: '${statistics.skipped}',
                  color: AppColors.warning),
              const SizedBox(width: AppSpacing.xs),
              _StatsBox(
                  label: 'Snoozed',
                  value: '${statistics.snoozed}',
                  color: const Color(0xFF6C63FF)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(label,
          style: AppTypography.captionText.copyWith(
              color: color, fontWeight: FontWeight.w700, fontSize: 10)),
    );
  }
}

class _StatsBox extends StatelessWidget {
  const _StatsBox(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          children: [
            Text(value,
                style: AppTypography.titleMedium.copyWith(
                    color: color, fontWeight: FontWeight.w800)),
            Text(label,
                style: AppTypography.captionText.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontSize: 9,
                ),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 6. REMINDER TIMELINE
// ══════════════════════════════════════════════════════════════════════════════

class ReminderTimeline extends StatelessWidget {
  const ReminderTimeline({required this.entries, required this.isDark, super.key});

  final List<ReminderHistoryEntry> entries;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const NotificationEmptyState(message: 'No reminder history yet.');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final entry = entries[i];
        final isLast = i == entries.length - 1;
        return _TimelineTile(entry: entry, isLast: isLast, isDark: isDark);
      },
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.entry,
    required this.isLast,
    required this.isDark,
  });

  final ReminderHistoryEntry entry;
  final bool isLast;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = entry.status.color;
    final diffLabel = _diffLabel(entry.scheduledAt);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline rail
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: isDark
                          ? AppColors.dividerDark
                          : AppColors.dividerLight,
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  left: AppSpacing.sm, bottom: isLast ? 0 : AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                      color: color.withOpacity(0.15),
                      width: AppSpacing.borderThin),
                ),
                child: Row(
                  children: [
                    Icon(entry.type.icon, color: color, size: 16),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.title,
                              style: AppTypography.labelSmall.copyWith(
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                  fontWeight: FontWeight.w600)),
                          Text(diffLabel,
                              style: AppTypography.captionText.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                                fontSize: 10,
                              )),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        entry.status.label,
                        style: AppTypography.captionText.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _diffLabel(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 7. EMPTY STATE
// ══════════════════════════════════════════════════════════════════════════════

class NotificationEmptyState extends StatelessWidget {
  const NotificationEmptyState({
    required this.message,
    this.icon = Icons.notifications_off_outlined,
    this.action,
    super.key,
  });

  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, v, child) =>
                  Transform.scale(scale: v, child: child),
              child: Icon(
                icon,
                size: 64,
                color: (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight)
                    .withOpacity(0.4),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 8. TIME PICKER TILE (Reminder Scheduler)
// ══════════════════════════════════════════════════════════════════════════════

/// A tappable tile that opens a Material time picker.
class TimePickerTile extends StatelessWidget {
  const TimePickerTile({
    required this.label,
    required this.time,
    required this.onChanged,
    required this.color,
    super.key,
  });

  final String label;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onChanged;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
          builder: (ctx, child) => MediaQuery(
            data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs, vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded, color: color, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text(label,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                )),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Text(
                timeStr,
                style: AppTypography.titleSmall.copyWith(
                    color: color, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right_rounded,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                size: 18),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 9. DAYS OF WEEK SELECTOR
// ══════════════════════════════════════════════════════════════════════════════

class DaysOfWeekSelector extends StatelessWidget {
  const DaysOfWeekSelector({
    required this.activeDays,
    required this.onChanged,
    required this.color,
    super.key,
  });

  final List<bool> activeDays;
  final ValueChanged<List<bool>> onChanged;
  final Color color;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (i) {
        final isActive = activeDays[i];
        return GestureDetector(
          onTap: () {
            final updated = List<bool>.from(activeDays);
            updated[i] = !isActive;
            onChanged(updated);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isActive ? color : color.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(
                  color: isActive ? color : color.withOpacity(0.25),
                  width: 1.5),
            ),
            child: Center(
              child: Text(
                _labels[i],
                style: AppTypography.labelSmall.copyWith(
                  color: isActive ? AppColors.white : color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
