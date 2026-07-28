import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../providers/ai_providers.dart';
import '../providers/ai_state.dart';
import '../widgets/ai_widgets.dart';
import '../widgets/chat_bubble.dart';

/// Full AI chat page with streaming, markdown, typing indicator,
/// regenerate, copy, bookmark, scroll-to-bottom, and voice placeholder.
class AIChatPage extends ConsumerStatefulWidget {
  const AIChatPage({
    super.key,
    this.conversationId,
    this.coachType,
    this.initialPrompt,
  });

  /// If null, a new conversation is created.
  final String? conversationId;
  final CoachType? coachType;
  final String? initialPrompt;

  @override
  ConsumerState<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends ConsumerState<AIChatPage> {
  final _scrollController = ScrollController();
  bool _showScrollFab = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initChat());
  }

  Future<void> _initChat() async {
    final notifier = ref.read(chatProvider.notifier);
    if (widget.conversationId != null) {
      await notifier.loadConversation(widget.conversationId!);
    } else {
      await notifier.startNewConversation(
        coachType: widget.coachType ?? CoachType.general,
        initialPrompt: widget.initialPrompt,
      );
    }
  }

  void _onScroll() {
    final atBottom = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 80;
    if (!atBottom != _showScrollFab) {
      setState(() => _showScrollFab = !atBottom);
    }
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;
    if (animate) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent);
    }
  }

  Future<void> _sendMessage(String text) async {
    await ref.read(chatProvider.notifier).sendMessage(text);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final coachType = chatState is ChatLoaded
        ? chatState.coachType
        : (widget.coachType ?? CoachType.general);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0D1224) : const Color(0xFFF5F7FF),
      appBar: _ChatAppBar(
        coachType: coachType,
        isDark: isDark,
        chatState: chatState,
        onClearHistory: () => _confirmClearHistory(context),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Messages list
              Expanded(
                child: _MessagesList(
                  chatState: chatState,
                  scrollController: _scrollController,
                  isDark: isDark,
                  coachType: coachType,
                  onSendSuggestion: _sendMessage,
                  onRegenerate: () =>
                      ref.read(chatProvider.notifier).regenerateLastResponse(),
                  onCopy: (msg) {
                    Clipboard.setData(
                        ClipboardData(text: msg.content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message copied!'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  onBookmark: (id) =>
                      ref.read(chatProvider.notifier).toggleBookmark(id),
                ),
              ),

              // Composer
              ChatComposer(
                onSend: _sendMessage,
                onVoice: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🎙️ Voice input coming soon!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                isDark: isDark,
                isLoading: chatState is ChatLoaded &&
                    (chatState.isStreaming || chatState.isTyping),
                initialText: '',
              ),
            ],
          ),

          // Scroll to bottom FAB
          if (_showScrollFab)
            Positioned(
              bottom: 80,
              right: AppSpacing.md,
              child: AnimatedOpacity(
                opacity: _showScrollFab ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: FloatingActionButton.small(
                  heroTag: 'scroll_to_bottom',
                  onPressed: _scrollToBottom,
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmClearHistory(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
            'This will delete all messages in this conversation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Future: clear individual conversation messages
            },
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Chat AppBar ────────────────────────────────────────────────────────────────

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ChatAppBar({
    required this.coachType,
    required this.isDark,
    required this.chatState,
    required this.onClearHistory,
  });

  final CoachType coachType;
  final bool isDark;
  final ChatState chatState;
  final VoidCallback onClearHistory;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isStreaming =
        chatState is ChatLoaded && (chatState as ChatLoaded).isStreaming;

    return AppBar(
      backgroundColor:
          isDark ? const Color(0xFF0D1224) : const Color(0xFFF5F7FF),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF9C88FF)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(coachType.emoji,
                  style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                coachType.label,
                style: AppTypography.titleSmall.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isStreaming
                    ? Text(
                        'Typing…',
                        key: const ValueKey('typing'),
                        style: AppTypography.captionText.copyWith(
                          color: const Color(0xFF6C63FF),
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : Text(
                        'AI-powered coaching',
                        key: const ValueKey('ready'),
                        style: AppTypography.captionText.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (v) {
            if (v == 'clear') onClearHistory();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'clear',
              child: ListTile(
                leading: Icon(Icons.delete_rounded, color: AppColors.error),
                title: Text('Clear History'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Messages List ─────────────────────────────────────────────────────────────

class _MessagesList extends StatelessWidget {
  const _MessagesList({
    required this.chatState,
    required this.scrollController,
    required this.isDark,
    required this.coachType,
    required this.onSendSuggestion,
    required this.onRegenerate,
    required this.onCopy,
    required this.onBookmark,
  });

  final ChatState chatState;
  final ScrollController scrollController;
  final bool isDark;
  final CoachType coachType;
  final ValueChanged<String> onSendSuggestion;
  final VoidCallback onRegenerate;
  final ValueChanged<MessageEntity> onCopy;
  final ValueChanged<String> onBookmark;

  @override
  Widget build(BuildContext context) {
    return switch (chatState) {
      ChatInitial() => const Center(
          child: CircularProgressIndicator(),
        ),
      ChatLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
      ChatError(:final message) => Center(
          child: Text(message,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.error)),
        ),
      ChatLoaded(:final messages, :final isTyping) => messages.isEmpty
          ? _EmptyState(
              coachType: coachType,
              isDark: isDark,
              onSuggestionTap: onSendSuggestion,
            )
          : ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
              itemCount: messages.length + (isTyping ? 1 : 0),
              itemBuilder: (_, i) {
                if (isTyping && i == messages.length) {
                  return TypingIndicator(isDark: isDark);
                }
                final msg = messages[i];
                return ChatBubble(
                  key: ValueKey(msg.id),
                  message: msg,
                  isDark: isDark,
                  onRegenerate:
                      msg.isAssistant ? onRegenerate : null,
                  onCopy: () => onCopy(msg),
                  onBookmark: msg.isAssistant
                      ? () => onBookmark(msg.id)
                      : null,
                );
              },
            ),
    };
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends ConsumerWidget {
  const _EmptyState({
    required this.coachType,
    required this.isDark,
    required this.onSuggestionTap,
  });

  final CoachType coachType;
  final bool isDark;
  final ValueChanged<String> onSuggestionTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prompts = ref.watch(popularPromptsProvider);

    return EmptyChatWidget(
      coachType: coachType,
      suggestions: prompts,
      onSuggestionTap: onSuggestionTap,
      isDark: isDark,
    );
  }
}
