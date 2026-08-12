import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/env/environment.dart';
import '../../data/providers/gemini_ai_provider.dart';
import '../../data/providers/openai_ai_provider.dart';
import '../../data/repositories/mock_ai_repository.dart';
import '../../domain/entities/ai_insight_entity.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/suggested_prompt_entity.dart';
import '../../domain/repositories/ai_repository.dart';
import 'ai_notifier.dart';
import 'ai_state.dart';

// ══════════════════════════════════════════════════════════════════════════════
// AI PROVIDER SELECTION
// ══════════════════════════════════════════════════════════════════════════════

final _mockRepoProvider = Provider<MockAIRepository>((ref) {
  final repo = MockAIRepository();
  repo.seedDemoData();
  return repo;
}, name: 'mockAIRepo');

/// Environment-based AI repository provider.
///
/// Routes to the correct AI implementation based on [Environment.aiProvider]:
///   - 'gemini' → [GeminiAIProvider] (requires GEMINI_API_KEY dart-define)
///   - 'openai' → [OpenAIProvider]   (requires OPENAI_API_KEY dart-define)
///   - 'mock'   → [MockAIRepository]  (default, no keys needed)
///
/// Switch providers without changing any UI code:
///   flutter run --dart-define=AI_PROVIDER=gemini --dart-define=GEMINI_API_KEY=xyz
final aiRepositoryProvider = Provider<AIRepository>(
  (ref) => switch (Environment.aiProvider) {
    'gemini' => GeminiAIProvider(),
    'openai' => OpenAIProvider(),
    _ => ref.watch(_mockRepoProvider),
  },
  name: 'aiRepositoryProvider',
);

// ── Chat ───────────────────────────────────────────────────────────────────────

/// Active chat session provider.
///
/// Scoped per conversation — use [ChatNotifier] methods to load/send.
final chatProvider =
    StateNotifierProvider.autoDispose<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(repository: ref.watch(aiRepositoryProvider)),
  name: 'chatProvider',
);

/// Convenience: currently loaded messages.
final chatMessagesProvider = Provider.autoDispose<List<MessageEntity>>(
  (ref) {
    final state = ref.watch(chatProvider);
    return state is ChatLoaded ? state.messages : [];
  },
  name: 'chatMessagesProvider',
);

/// True while the AI is streaming a response.
final chatIsStreamingProvider = Provider.autoDispose<bool>(
  (ref) {
    final state = ref.watch(chatProvider);
    return state is ChatLoaded && state.isStreaming;
  },
  name: 'chatIsStreamingProvider',
);

/// True while the AI is "thinking" (before streaming starts).
final chatIsTypingProvider = Provider.autoDispose<bool>(
  (ref) {
    final state = ref.watch(chatProvider);
    return state is ChatLoaded && state.isTyping;
  },
  name: 'chatIsTypingProvider',
);

/// Active coach type for the current chat.
final chatCoachTypeProvider = Provider.autoDispose<CoachType>(
  (ref) {
    final state = ref.watch(chatProvider);
    return state is ChatLoaded ? state.coachType : CoachType.general;
  },
  name: 'chatCoachTypeProvider',
);

// ── Conversations ──────────────────────────────────────────────────────────────

final conversationListProvider =
    StateNotifierProvider<ConversationListNotifier, ConversationListState>(
  (ref) => ConversationListNotifier(
    repository: ref.watch(aiRepositoryProvider),
  ),
  name: 'conversationListProvider',
);

/// Filtered + sorted conversations for the history page.
final filteredConversationsProvider = Provider<List<ConversationEntity>>(
  (ref) {
    final state = ref.watch(conversationListProvider);
    return state is ConversationListLoaded ? state.filtered : [];
  },
  name: 'filteredConversationsProvider',
);

/// Pinned conversations only.
final pinnedConversationsProvider = Provider<List<ConversationEntity>>(
  (ref) {
    final state = ref.watch(conversationListProvider);
    if (state is! ConversationListLoaded) return [];
    return state.conversations
        .where((c) => c.isPinned && c.isActive)
        .toList();
  },
  name: 'pinnedConversationsProvider',
);

/// Recent conversations (5 most recent, active only).
final recentConversationsProvider = Provider<List<ConversationEntity>>(
  (ref) {
    final state = ref.watch(conversationListProvider);
    if (state is! ConversationListLoaded) return [];
    return state.conversations
        .where((c) => c.isActive)
        .take(5)
        .toList();
  },
  name: 'recentConversationsProvider',
);

// ── Insights ───────────────────────────────────────────────────────────────────

final aiInsightProvider =
    StateNotifierProvider<AIInsightNotifier, InsightState>(
  (ref) => AIInsightNotifier(repository: ref.watch(aiRepositoryProvider)),
  name: 'aiInsightProvider',
);

final insightUnreadCountProvider = Provider<int>(
  (ref) {
    final state = ref.watch(aiInsightProvider);
    return state is InsightLoaded ? state.unreadCount : 0;
  },
  name: 'insightUnreadCountProvider',
);

final filteredInsightsProvider = Provider<List<AIInsightEntity>>(
  (ref) {
    final state = ref.watch(aiInsightProvider);
    return state is InsightLoaded ? state.filtered : [];
  },
  name: 'filteredInsightsProvider',
);

/// Top 3 insight previews for the AI home page.
final insightPreviewProvider = Provider<List<AIInsightEntity>>(
  (ref) {
    final state = ref.watch(aiInsightProvider);
    if (state is! InsightLoaded) return [];
    return state.insights
        .where((i) => !i.isRead)
        .take(3)
        .toList();
  },
  name: 'insightPreviewProvider',
);

// ── Prompt Library ─────────────────────────────────────────────────────────────

final promptLibraryProvider =
    StateNotifierProvider<PromptLibraryNotifier, PromptLibraryState>(
  (ref) =>
      PromptLibraryNotifier(repository: ref.watch(aiRepositoryProvider)),
  name: 'promptLibraryProvider',
);

final filteredPromptsProvider = Provider<List<SuggestedPromptEntity>>(
  (ref) {
    final state = ref.watch(promptLibraryProvider);
    return state is PromptLibraryLoaded ? state.filtered : [];
  },
  name: 'filteredPromptsProvider',
);

/// Popular prompts for the AI home page chips.
final popularPromptsProvider = Provider<List<SuggestedPromptEntity>>(
  (ref) {
    final state = ref.watch(promptLibraryProvider);
    if (state is! PromptLibraryLoaded) return [];
    return state.prompts.where((p) => p.isPopular).take(6).toList();
  },
  name: 'popularPromptsProvider',
);

// ── AI Settings ────────────────────────────────────────────────────────────────

final aiSettingsProvider =
    StateNotifierProvider<AISettingsNotifier, AISettingsState>(
  (ref) => AISettingsNotifier(),
  name: 'aiSettingsProvider',
);

// ── Voice ──────────────────────────────────────────────────────────────────────

final voiceProvider =
    StateNotifierProvider.autoDispose<VoiceNotifier, VoiceState>(
  (ref) => VoiceNotifier(),
  name: 'voiceProvider',
);

// ── UI State ───────────────────────────────────────────────────────────────────

/// The text currently being composed in the chat input.
final chatComposerTextProvider = StateProvider.autoDispose<String>(
  (_) => '',
  name: 'chatComposerTextProvider',
);

/// Controls whether the scroll-to-bottom FAB is visible.
final showScrollToBottomProvider = StateProvider.autoDispose<bool>(
  (_) => false,
  name: 'showScrollToBottomProvider',
);

/// Active coach type selected on the AI home page.
final selectedCoachTypeProvider = StateProvider<CoachType>(
  (_) => CoachType.general,
  name: 'selectedCoachTypeProvider',
);

/// Active prompt category filter.
final activePromptCategoryProvider = StateProvider<PromptCategory>(
  (_) => PromptCategory.all,
  name: 'activePromptCategoryProvider',
);

/// Active insight filter type.
final activeInsightFilterProvider = StateProvider<InsightType?>(
  (_) => null,
  name: 'activeInsightFilterProvider',
);

/// History filter tab index (0=All, 1=Pinned, 2=Archived).
final historyTabIndexProvider = StateProvider<int>(
  (_) => 0,
  name: 'historyTabIndexProvider',
);

/// History search query.
final historySearchQueryProvider = StateProvider<String>(
  (_) => '',
  name: 'historySearchQueryProvider',
);

