import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/conversation_entity.dart';
import '../providers/ai_providers.dart';
import '../providers/ai_state.dart';
import '../widgets/insight_coach_widgets.dart';

/// Chat history page with search, filter tabs (All/Pinned/Archived),
/// swipe-to-pin/delete, long-press context menu, and clear-all.
class ChatHistoryPage extends ConsumerWidget {
  const ChatHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        title: Text(
          'Chat History',
          style: AppTypography.titleLarge.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded,
                color: AppColors.error),
            onPressed: () => _confirmClearAll(context, ref),
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          _SearchBar(isDark: isDark),
          const SizedBox(height: AppSpacing.xs),

          // Filter tabs
          _FilterTabs(isDark: isDark),
          const SizedBox(height: AppSpacing.sm),

          // Conversation list
          Expanded(
            child: _ConversationList(isDark: isDark),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear All Conversations'),
        content: const Text(
            'This will permanently delete all chat history. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(conversationListProvider.notifier).clearAll();
            },
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}

// ── Search Bar ────────────────────────────────────────────────────────────────

class _SearchBar extends ConsumerWidget {
  const _SearchBar({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: TextField(
        onChanged: (q) =>
            ref.read(conversationListProvider.notifier).setQuery(q),
        style: AppTypography.bodyMedium.copyWith(
          color: isDark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
        ),
        decoration: InputDecoration(
          hintText: 'Search conversations…',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          filled: true,
          fillColor: isDark
              ? const Color(0xFF1A1F3A)
              : const Color(0xFFF0F4FF),
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(AppSpacing.radiusXl),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm, horizontal: AppSpacing.md),
        ),
      ),
    );
  }
}

// ── Filter Tabs ───────────────────────────────────────────────────────────────

class _FilterTabs extends ConsumerWidget {
  const _FilterTabs({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIdx = ref.watch(historyTabIndexProvider);

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          _TabChip(
            label: 'All',
            isActive: tabIdx == 0,
            onTap: () {
              ref.read(historyTabIndexProvider.notifier).state = 0;
              ref.read(conversationListProvider.notifier).setFilter();
            },
          ),
          const SizedBox(width: AppSpacing.xs),
          _TabChip(
            label: '📌 Pinned',
            isActive: tabIdx == 1,
            onTap: () {
              ref.read(historyTabIndexProvider.notifier).state = 1;
              ref
                  .read(conversationListProvider.notifier)
                  .setFilter(pinned: true);
            },
          ),
          const SizedBox(width: AppSpacing.xs),
          _TabChip(
            label: '📦 Archived',
            isActive: tabIdx == 2,
            onTap: () {
              ref.read(historyTabIndexProvider.notifier).state = 2;
              ref
                  .read(conversationListProvider.notifier)
                  .setFilter(archived: true);
            },
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary
              : AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isActive ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Conversation List ─────────────────────────────────────────────────────────

class _ConversationList extends ConsumerWidget {
  const _ConversationList({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversationListProvider);

    if (state is ConversationListLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ConversationListError) {
      return Center(
        child: Text(state.message,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.error)),
      );
    }

    final conversations = ref.watch(filteredConversationsProvider);

    if (conversations.isEmpty) {
      return _EmptyHistory(isDark: isDark);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      itemCount: conversations.length,
      itemBuilder: (_, i) {
        final convo = conversations[i];
        return ConversationTile(
          conversation: convo,
          isDark: isDark,
          onTap: () => context.push(
            '/ai-assistant/chat/${convo.id}',
          ),
          onPin: () => ref
              .read(conversationListProvider.notifier)
              .pinConversation(convo.id),
          onArchive: () => convo.isArchived
              ? ref
                  .read(conversationListProvider.notifier)
                  .restoreConversation(convo.id)
              : ref
                  .read(conversationListProvider.notifier)
                  .archiveConversation(convo.id),
          onDelete: () => _confirmDelete(context, ref, convo),
          onRename: () => _showRenameDialog(context, ref, convo),
        );
      },
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, ConversationEntity convo) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text('Delete "${convo.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(conversationListProvider.notifier)
                  .deleteConversation(convo.id);
            },
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(
      BuildContext context, WidgetRef ref, ConversationEntity convo) {
    final ctrl = TextEditingController(text: convo.title);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename Conversation'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final title = ctrl.text.trim();
              if (title.isNotEmpty) {
                ref
                    .read(conversationListProvider.notifier)
                    .renameConversation(convo.id, title);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ── Empty History ─────────────────────────────────────────────────────────────

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No conversations found',
            style: AppTypography.titleMedium.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Start a new chat to see your history here',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: () => context.push('/ai-assistant/chat/new'),
            icon: const Icon(Icons.add_comment_rounded),
            label: const Text('Start New Chat'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
            ),
          ),
        ],
      ),
    );
  }
}

