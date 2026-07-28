import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/conversation_entity.dart';
import '../providers/ai_providers.dart';
import '../providers/ai_state.dart';
import '../widgets/ai_widgets.dart';
import '../widgets/insight_coach_widgets.dart';

/// AI Assistant home screen.
///
/// Sections:
/// 1. Welcome hero with animated AI avatar
/// 2. Quick-action grid (Chat, Coach, Insights, Prompts, History)
/// 3. Smart insight preview cards (top 3 unread)
/// 4. Suggested prompt chips by category
/// 5. Recent conversations
class AIHomePage extends ConsumerWidget {
  const AIHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: isDark
                ? AppColors.backgroundDark
                : AppColors.surfaceLight,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroHeader(isDark: isDark),
            ),
            title: Text(
              'AI Health Coach',
              style: AppTypography.titleLarge.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_rounded),
                onPressed: () => context.push(RouteNames.aiSettings),
                tooltip: 'AI Settings',
              ),
              IconButton(
                icon: const Icon(Icons.history_rounded),
                onPressed: () => context.push(RouteNames.chatHistory),
                tooltip: 'Chat History',
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Quick Actions ──────────────────────────────────────────
                _QuickActionsGrid(isDark: isDark),
                const SizedBox(height: AppSpacing.lg),

                // ── Smart Insights Preview ─────────────────────────────────
                _SectionHeader(
                  title: '✨ Smart Insights',
                  action: 'View All',
                  onAction: () => context.push(RouteNames.smartInsights),
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.sm),
                _InsightPreviewList(isDark: isDark),
                const SizedBox(height: AppSpacing.lg),

                // ── Suggested Prompts ──────────────────────────────────────
                _SectionHeader(
                  title: '💡 Try Asking…',
                  action: 'Prompt Library',
                  onAction: () => context.push(RouteNames.promptLibrary),
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.sm),
                _SuggestedPromptsSection(isDark: isDark),
                const SizedBox(height: AppSpacing.lg),

                // ── Recent Conversations ───────────────────────────────────
                _SectionHeader(
                  title: '🕐 Recent Chats',
                  action: 'See All',
                  onAction: () => context.push(RouteNames.chatHistory),
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.sm),
                _RecentConversationsList(isDark: isDark),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'ai_home_fab',
        onPressed: () => context.push(RouteNames.aiChatNew),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_rounded),
        label: Text(
          'New Chat',
          style: AppTypography.labelLarge
              .copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ── Hero Header ───────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A1040), const Color(0xFF0D1224)]
              : [const Color(0xFFEEEBFF), const Color(0xFFF5F7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const AIAvatar(size: 72),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Hello! 👋',
                      style: AppTypography.headlineSmall.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'I\'m your personal AI Health Coach. How can I help you today?',
                      style: AppTypography.bodyMedium.copyWith(
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
        ),
      ),
    );
  }
}

// ── Quick Actions Grid ────────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.chat_bubble_rounded,
        label: 'New Chat',
        color: const Color(0xFF6C63FF),
        onTap: () => context.push(RouteNames.aiChatNew),
      ),
      _QuickAction(
        icon: Icons.psychology_rounded,
        label: 'AI Coach',
        color: const Color(0xFF00C896),
        onTap: () => context.push(RouteNames.aiCoach),
      ),
      _QuickAction(
        icon: Icons.insights_rounded,
        label: 'Insights',
        color: const Color(0xFFFF6B6B),
        onTap: () => context.push(RouteNames.smartInsights),
      ),
      _QuickAction(
        icon: Icons.auto_awesome_rounded,
        label: 'Prompts',
        color: const Color(0xFFFFBF00),
        onTap: () => context.push(RouteNames.promptLibrary),
      ),
      _QuickAction(
        icon: Icons.history_rounded,
        label: 'History',
        color: const Color(0xFF00B4D8),
        onTap: () => context.push(RouteNames.chatHistory),
      ),
      _QuickAction(
        icon: Icons.mic_rounded,
        label: 'Voice',
        color: const Color(0xFFFF6BB5),
        onTap: () => _showVoiceComingSoon(context),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.1,
        children: actions.map((a) => _QuickActionCard(action: a, isDark: isDark)).toList(),
      ),
    );
  }

  void _showVoiceComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎙️ Voice input coming soon!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action, required this.isDark});
  final _QuickAction action;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: action.color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: action.color.withValues(alpha: 0.25),
            width: AppSpacing.borderThin,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, color: action.color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              action.label,
              style: AppTypography.labelSmall.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Insight Preview ───────────────────────────────────────────────────────────

class _InsightPreviewList extends ConsumerWidget {
  const _InsightPreviewList({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(insightPreviewProvider);

    if (insights.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Text(
          'No new insights. Check back later!',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: insights.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final insight = insights[i];
          return SizedBox(
            width: 280,
            child: InsightCard(
              insight: insight,
              isDark: isDark,
              compact: true,
              onTap: () {
                ref
                    .read(aiInsightProvider.notifier)
                    .markRead(insight.id);
                context.push(RouteNames.smartInsights);
              },
            ),
          );
        },
      ),
    );
  }
}

// ── Suggested Prompts ─────────────────────────────────────────────────────────

class _SuggestedPromptsSection extends ConsumerWidget {
  const _SuggestedPromptsSection({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prompts = ref.watch(popularPromptsProvider);

    if (prompts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: prompts.map((p) {
          return SuggestionChip(
            prompt: p,
            onTap: () {
              context.push(RouteNames.aiChatNew,
                  extra: {'initialPrompt': p.text});
            },
          );
        }).toList(),
      ),
    );
  }
}

// ── Recent Conversations ──────────────────────────────────────────────────────

class _RecentConversationsList extends ConsumerWidget {
  const _RecentConversationsList({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentConversationsProvider);

    if (recent.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1A1F3A)
                : const Color(0xFFF5F7FF),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'No conversations yet. Start chatting!',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: recent.map((convo) {
        return ConversationTile(
          conversation: convo,
          isDark: isDark,
          onTap: () => context.push(
            RouteNames.aiChat.replaceAll(':id', convo.id),
          ),
          onPin: () => ref
              .read(conversationListProvider.notifier)
              .pinConversation(convo.id),
          onDelete: () => ref
              .read(conversationListProvider.notifier)
              .deleteConversation(convo.id),
        );
      }).toList(),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.isDark,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
              ),
              child: Text(
                action!,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
