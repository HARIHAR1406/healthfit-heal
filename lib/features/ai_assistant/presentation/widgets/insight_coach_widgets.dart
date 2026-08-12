import 'package:flutter/material.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/ai_insight_entity.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/suggested_prompt_entity.dart';

// ══════════════════════════════════════════════════════════════════════════════
// INSIGHT CARD
// ══════════════════════════════════════════════════════════════════════════════

/// AI-generated insight card with gradient, trend arrow, and CTA.
class InsightCard extends StatelessWidget {
  const InsightCard({
    required this.insight,
    required this.isDark,
    super.key,
    this.onTap,
    this.onAction,
    this.onDismiss,
    this.compact = false,
  });

  final AIInsightEntity insight;
  final bool isDark;
  final VoidCallback? onTap;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = insight.type.color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(isDark ? 0.2 : 0.1),
              color.withOpacity(isDark ? 0.05 : 0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: color.withOpacity(0.25),
            width: AppSpacing.borderThin,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isDark ? 0.15 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Type icon
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(insight.type.icon, color: color, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Type label + priority
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.type.label,
                        style: AppTypography.captionText.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _PriorityBadge(priority: insight.priority),
                    ],
                  ),
                ),
                // Metric + trend
                if (insight.metricValue != null) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            insight.trend.icon,
                            size: 16,
                            color: insight.trend == InsightTrend.down
                                ? AppColors.error
                                : insight.trend == InsightTrend.up
                                    ? const Color(0xFF00C896)
                                    : Colors.grey,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${insight.metricValue}${insight.metricUnit ?? ''}',
                            style: AppTypography.titleSmall.copyWith(
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      if (insight.metric != null)
                        Text(
                          insight.metric!,
                          style: AppTypography.captionText.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                    ],
                  ),
                ],
                // Dismiss
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    onPressed: onDismiss,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Title
            Text(
              insight.title,
              style: AppTypography.titleSmall.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),

            // Body (condensed if compact)
            if (!compact) ...[
              _InsightBodyText(
                text: insight.body,
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            // Footer row
            Row(
              children: [
                Text(
                  _formatRelative(insight.timestamp),
                  style: AppTypography.captionText.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const Spacer(),
                if (insight.actionLabel != null)
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: color,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      insight.actionLabel!,
                      style: AppTypography.labelSmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatRelative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});
  final InsightPriority priority;

  @override
  Widget build(BuildContext context) {
    if (priority == InsightPriority.low) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: priority.badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority.label,
        style: AppTypography.captionText.copyWith(
          color: priority.badgeColor,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _InsightBodyText extends StatelessWidget {
  const _InsightBodyText({required this.text, required this.isDark});
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Simple bold markdown for insight body
    final spans = <InlineSpan>[];
    final boldPattern = RegExp(r'\*\*(.+?)\*\*');
    var last = 0;
    final baseStyle = AppTypography.bodySmall.copyWith(
      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      height: 1.5,
    );
    for (final match in boldPattern.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(
            text: text.substring(last, match.start), style: baseStyle));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ));
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last), style: baseStyle));
    }
    return RichText(
      text: TextSpan(
          children: spans.isEmpty
              ? [TextSpan(text: text, style: baseStyle)]
              : spans),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// COACH CARD
// ══════════════════════════════════════════════════════════════════════════════

/// Gradient colours for each CoachType. Used by [CoachCard] and [ConversationTile].
const Map<CoachType, List<Color>> coachGradients = {
  CoachType.health: [Color(0xFFFF6B6B), Color(0xFFFF9800)],
  CoachType.fitness: [Color(0xFF00C896), Color(0xFF00B4D8)],
  CoachType.nutrition: [Color(0xFFFFBF00), Color(0xFFFF9800)],
  CoachType.lifestyle: [Color(0xFF4CAF50), Color(0xFF00C896)],
  CoachType.habit: [Color(0xFF6C63FF), Color(0xFF9C88FF)],
  CoachType.general: [Color(0xFF6C63FF), Color(0xFFFF6BB5)],
};

/// Gradient card for selecting an AI coaching domain.
class CoachCard extends StatelessWidget {
  const CoachCard({
    required this.coachType,
    required this.isDark,
    required this.onTap,
    super.key,
    this.isSelected = false,
  });

  final CoachType coachType;
  final bool isDark;
  final VoidCallback onTap;
  final bool isSelected;

  static const Map<CoachType, String> _descriptions = {
    CoachType.health: 'Vitals, preventive care\n& wellness monitoring',
    CoachType.fitness: 'Workouts, strength\n& performance coaching',
    CoachType.nutrition: 'Meal plans, macros\n& dietary guidance',
    CoachType.lifestyle: 'Sleep, stress & daily\nroutine optimisation',
    CoachType.habit: 'Behaviour change &\nlasting habit formation',
    CoachType.general: 'Your all-in-one AI\nhealth companion',
  };

  @override
  Widget build(BuildContext context) {
    final colors = coachGradients[coachType] ?? coachGradients[CoachType.general]!;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? colors
                : [
                    colors[0].withOpacity(0.15),
                    colors[1].withOpacity(0.08),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: isSelected
                ? colors[0].withOpacity(0.6)
                : colors[0].withOpacity(0.25),
            width: isSelected ? 2 : AppSpacing.borderThin,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors[0].withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              coachType.emoji,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              coachType.label,
              style: AppTypography.titleSmall.copyWith(
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _descriptions[coachType] ?? '',
              style: AppTypography.bodySmall.copyWith(
                color: isSelected
                    ? Colors.white.withOpacity(0.85)
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  'Chat now',
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected
                        ? Colors.white
                        : colors[0],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: isSelected ? Colors.white : colors[0],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PROMPT CARD
// ══════════════════════════════════════════════════════════════════════════════

/// Grid card for the prompt library.
class PromptCard extends StatelessWidget {
  const PromptCard({
    required this.prompt,
    required this.onTap,
    required this.isDark,
    super.key,
  });

  final SuggestedPromptEntity prompt;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: prompt.color.withOpacity(isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: prompt.color.withOpacity(0.25),
            width: AppSpacing.borderThin,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: prompt.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(prompt.icon, color: prompt.color, size: 20),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              prompt.text,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            if (prompt.isPopular)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: prompt.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '🔥 Popular',
                  style: AppTypography.captionText.copyWith(
                    color: prompt.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CONVERSATION TILE
// ══════════════════════════════════════════════════════════════════════════════

/// Dismissible conversation list tile with swipe actions.
class ConversationTile extends StatelessWidget {
  const ConversationTile({
    required this.conversation,
    required this.onTap,
    required this.isDark,
    super.key,
    this.onPin,
    this.onArchive,
    this.onDelete,
    this.onRename,
  });

  final ConversationEntity conversation;
  final VoidCallback onTap;
  final bool isDark;
  final VoidCallback? onPin;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRename;

  @override
  Widget build(BuildContext context) {
    final colors = coachGradients[conversation.coachType] ??
        [const Color(0xFF6C63FF), const Color(0xFF9C88FF)];

    return Dismissible(
      key: ValueKey(conversation.id),
      background: _SwipeBg(
        color: AppColors.primary,
        icon: conversation.isPinned
            ? Icons.push_pin_outlined
            : Icons.push_pin_rounded,
        label: conversation.isPinned ? 'Unpin' : 'Pin',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _SwipeBg(
        color: AppColors.error,
        icon: Icons.delete_rounded,
        label: 'Delete',
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          onPin?.call();
          return false;
        } else {
          onDelete?.call();
          return false;
        }
      },
      child: GestureDetector(
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
        child: Container(
          margin: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.xs,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
            borderRadius:
                BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.grey.withOpacity(0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Coach type avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    conversation.coachType.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (conversation.isPinned) ...[
                          const Icon(Icons.push_pin_rounded,
                              size: 14,
                              color: AppColors.primary),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            conversation.title,
                            style: AppTypography.titleSmall.copyWith(
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatDate(conversation.updatedAt),
                          style: AppTypography.captionText.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      conversation.lastMessagePreview,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Coach type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors[0].withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        conversation.coachType.label,
                        style: AppTypography.captionText.copyWith(
                          color: colors[0],
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Colors.grey, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConversationContextMenu(
        conversation: conversation,
        isDark: isDark,
        onPin: onPin,
        onArchive: onArchive,
        onDelete: onDelete,
        onRename: onRename,
      ),
    );
  }
}

class _SwipeBg extends StatelessWidget {
  const _SwipeBg({
    required this.color,
    required this.icon,
    required this.label,
    required this.alignment,
  });
  final Color color;
  final IconData icon;
  final String label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
          left: AppSpacing.md, right: AppSpacing.md, bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 2),
          Text(label,
              style:
                  AppTypography.labelSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _ConversationContextMenu extends StatelessWidget {
  const _ConversationContextMenu({
    required this.conversation,
    required this.isDark,
    this.onPin,
    this.onArchive,
    this.onDelete,
    this.onRename,
  });

  final ConversationEntity conversation;
  final bool isDark;
  final VoidCallback? onPin;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRename;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A1F3A) : Colors.white;
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              conversation.title,
              style: AppTypography.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              conversation.isPinned
                  ? Icons.push_pin_outlined
                  : Icons.push_pin_rounded,
              color: AppColors.primary,
            ),
            title: Text(conversation.isPinned ? 'Unpin' : 'Pin'),
            onTap: () {
              Navigator.pop(context);
              onPin?.call();
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_rounded,
                color: AppColors.secondary),
            title: const Text('Rename'),
            onTap: () {
              Navigator.pop(context);
              onRename?.call();
            },
          ),
          ListTile(
            leading: Icon(
              conversation.isArchived
                  ? Icons.unarchive_rounded
                  : Icons.archive_rounded,
              color: Colors.orange,
            ),
            title:
                Text(conversation.isArchived ? 'Restore' : 'Archive'),
            onTap: () {
              Navigator.pop(context);
              onArchive?.call();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_rounded,
                color: AppColors.error),
            title: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
            onTap: () {
              Navigator.pop(context);
              onDelete?.call();
            },
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

