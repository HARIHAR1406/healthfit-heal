import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/ai_insight_entity.dart';
import '../../../domain/entities/conversation_entity.dart';
import '../../../domain/entities/message_entity.dart';
import '../../../domain/entities/suggested_prompt_entity.dart';
import '../../../domain/repositories/ai_repository.dart';
import 'ai_state.dart';

// ══════════════════════════════════════════════════════════════════════════════
// CHAT NOTIFIER
// ══════════════════════════════════════════════════════════════════════════════

/// Manages a single active chat session.
class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier({required AIRepository repository})
      : _repo = repository,
        super(const ChatInitial());

  final AIRepository _repo;
  String? _currentConversationId;
  StreamSubscription<String>? _streamSub;

  // ── Load / Initialise ──────────────────────────────────────────────────────

  Future<void> loadConversation(String conversationId) async {
    state = const ChatLoading();
    try {
      final convo = await _repo.getConversation(conversationId);
      if (convo == null) {
        state = const ChatError(message: 'Conversation not found.');
        return;
      }
      _currentConversationId = conversationId;
      state = ChatLoaded(
        conversationId: conversationId,
        messages: List<MessageEntity>.from(convo.messages),
        coachType: convo.coachType,
      );
    } catch (e) {
      state = ChatError(message: e.toString());
    }
  }

  Future<void> startNewConversation({
    CoachType coachType = CoachType.general,
    String? initialPrompt,
  }) async {
    state = const ChatLoading();
    try {
      final convo = await _repo.createConversation(coachType: coachType);
      _currentConversationId = convo.id;
      state = ChatLoaded(
        conversationId: convo.id,
        messages: [],
        coachType: coachType,
      );
      if (initialPrompt != null && initialPrompt.isNotEmpty) {
        await sendMessage(initialPrompt);
      }
    } catch (e) {
      state = ChatError(message: e.toString());
    }
  }

  // ── Messaging ──────────────────────────────────────────────────────────────

  Future<void> sendMessage(String content) async {
    final current = state;
    if (current is! ChatLoaded) return;

    final convId = _currentConversationId ?? current.conversationId;
    final msgId = DateTime.now().millisecondsSinceEpoch.toString();
    final aiMsgId = '${msgId}_ai';

    final userMsg = MessageEntity.user(
      id: msgId,
      conversationId: convId,
      content: content,
    );

    // Append user message + typing indicator
    var messages = [...current.messages, userMsg];
    state = current.copyWith(messages: messages, isTyping: true);

    try {
      // Start streaming
      final stream = await _repo.sendMessageStream(
        messages,
        content,
        coachType: current.coachType,
      );

      // Add streaming placeholder
      final streamingMsg = MessageEntity.streamingPlaceholder(
        id: aiMsgId,
        conversationId: convId,
      );
      messages = [...messages, streamingMsg];
      state = (state as ChatLoaded).copyWith(
        messages: messages,
        isTyping: false,
        isStreaming: true,
      );

      final buffer = StringBuffer();

      _streamSub = stream.listen(
        (token) {
          buffer.write(token);
          if (state is ChatLoaded) {
            final loaded = state as ChatLoaded;
            final updatedMessages = loaded.messages.map((m) {
              if (m.id == aiMsgId) {
                return m.copyWith(content: buffer.toString());
              }
              return m;
            }).toList();
            state = loaded.copyWith(
              messages: updatedMessages,
              isStreaming: true,
            );
          }
        },
        onDone: () async {
          if (state is ChatLoaded) {
            final loaded = state as ChatLoaded;
            final finalMessages = loaded.messages.map((m) {
              if (m.id == aiMsgId) {
                return m.copyWith(
                  content: buffer.toString().trim(),
                  status: MessageStatus.delivered,
                );
              }
              if (m.id == msgId) {
                return m.copyWith(status: MessageStatus.delivered);
              }
              return m;
            }).toList();
            state = loaded.copyWith(
              messages: finalMessages,
              isStreaming: false,
            );
            // Auto-generate title on first exchange
            if (finalMessages.length == 2) {
              await _autoTitle(finalMessages);
            }
          }
        },
        onError: (_) {
          if (state is ChatLoaded) {
            final loaded = state as ChatLoaded;
            final errorMessages = loaded.messages.map((m) {
              if (m.id == aiMsgId) {
                return m.copyWith(
                  content: 'Something went wrong. Please try again.',
                  status: MessageStatus.error,
                );
              }
              return m;
            }).toList();
            state = loaded.copyWith(
              messages: errorMessages,
              isStreaming: false,
            );
          }
        },
      );
    } catch (e) {
      if (state is ChatLoaded) {
        state = (state as ChatLoaded).copyWith(
          isTyping: false,
          isStreaming: false,
          errorMessage: e.toString(),
        );
      }
    }
  }

  Future<void> regenerateLastResponse() async {
    final current = state;
    if (current is! ChatLoaded) return;
    final msgs = current.messages;
    if (msgs.length < 2) return;

    // Find last user message
    final lastUser = msgs.lastWhere((m) => m.isUser, orElse: () => msgs.last);

    // Remove last AI message
    final trimmed = msgs.where((m) => m.id != msgs.last.id).toList();
    state = current.copyWith(messages: trimmed);
    await sendMessage(lastUser.content);
  }

  void toggleBookmark(String messageId) {
    final current = state;
    if (current is! ChatLoaded) return;
    final updated = current.messages.map((m) {
      if (m.id == messageId) return m.copyWith(isBookmarked: !m.isBookmarked);
      return m;
    }).toList();
    state = current.copyWith(messages: updated);
  }

  Future<void> _autoTitle(List<MessageEntity> messages) async {
    if (_currentConversationId == null) return;
    try {
      final title = await _repo.generateTitle(messages);
      final convo = await _repo.getConversation(_currentConversationId!);
      if (convo != null) {
        await _repo.updateConversation(convo.copyWith(
          title: title,
          updatedAt: DateTime.now(),
        ));
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CONVERSATION LIST NOTIFIER
// ══════════════════════════════════════════════════════════════════════════════

class ConversationListNotifier extends StateNotifier<ConversationListState> {
  ConversationListNotifier({required AIRepository repository})
      : _repo = repository,
        super(const ConversationListLoading()) {
    load();
  }

  final AIRepository _repo;

  Future<void> load() async {
    try {
      final conversations = await _repo.getConversations();
      state = ConversationListLoaded(conversations: conversations);
    } catch (e) {
      state = ConversationListError(message: e.toString());
    }
  }

  Future<void> refresh() async => load();

  void setQuery(String query) {
    final current = state;
    if (current is ConversationListLoaded) {
      state = current.copyWith(query: query);
    }
  }

  void setFilter({bool? archived, bool? pinned}) {
    final current = state;
    if (current is ConversationListLoaded) {
      state = current.copyWith(
        filterArchived: archived ?? false,
        filterPinned: pinned ?? false,
      );
    }
  }

  Future<void> pinConversation(String id) async {
    final current = state;
    if (current is! ConversationListLoaded) return;
    final convo = current.conversations.firstWhere((c) => c.id == id);
    await _repo.updateConversation(convo.copyWith(isPinned: !convo.isPinned));
    await load();
  }

  Future<void> archiveConversation(String id) async {
    final current = state;
    if (current is! ConversationListLoaded) return;
    final convo = current.conversations.firstWhere((c) => c.id == id);
    await _repo.updateConversation(
      convo.copyWith(status: ConversationStatus.archived),
    );
    await load();
  }

  Future<void> restoreConversation(String id) async {
    final current = state;
    if (current is! ConversationListLoaded) return;
    final convo = current.conversations.firstWhere((c) => c.id == id);
    await _repo.updateConversation(
      convo.copyWith(status: ConversationStatus.active),
    );
    await load();
  }

  Future<void> renameConversation(String id, String newTitle) async {
    final current = state;
    if (current is! ConversationListLoaded) return;
    final convo = current.conversations.firstWhere((c) => c.id == id);
    await _repo.updateConversation(
      convo.copyWith(title: newTitle, updatedAt: DateTime.now()),
    );
    await load();
  }

  Future<void> deleteConversation(String id) async {
    await _repo.deleteConversation(id);
    await load();
  }

  Future<void> clearAll() async {
    await _repo.clearAllConversations();
    await load();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// INSIGHT NOTIFIER
// ══════════════════════════════════════════════════════════════════════════════

class AIInsightNotifier extends StateNotifier<InsightState> {
  AIInsightNotifier({required AIRepository repository})
      : _repo = repository,
        super(const InsightLoading()) {
    load();
  }

  final AIRepository _repo;

  Future<void> load() async {
    try {
      final insights = await _repo.getInsights();
      state = InsightLoaded(insights: insights);
    } catch (e) {
      state = InsightError(message: e.toString());
    }
  }

  Future<void> refresh() async {
    if (state is InsightLoaded) {
      final current = state as InsightLoaded;
      state = InsightLoaded(insights: current.insights);
    }
    await load();
  }

  void setFilter(InsightType? type) {
    final current = state;
    if (current is InsightLoaded) {
      state = InsightLoaded(insights: current.insights, filterType: type);
    }
  }

  Future<void> markRead(String insightId) async {
    await _repo.markInsightRead(insightId);
    final current = state;
    if (current is InsightLoaded) {
      final updated = current.insights
          .map((i) => i.id == insightId ? i.copyWith(isRead: true) : i)
          .toList();
      state = InsightLoaded(
        insights: updated,
        filterType: current.filterType,
      );
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PROMPT LIBRARY NOTIFIER
// ══════════════════════════════════════════════════════════════════════════════

class PromptLibraryNotifier extends StateNotifier<PromptLibraryState> {
  PromptLibraryNotifier({required AIRepository repository})
      : _repo = repository,
        super(const PromptLibraryLoading()) {
    load();
  }

  final AIRepository _repo;

  Future<void> load() async {
    try {
      final prompts = await _repo.getSuggestedPrompts();
      state = PromptLibraryLoaded(prompts: prompts);
    } catch (e) {
      state = PromptLibraryError(message: e.toString());
    }
  }

  void setCategory(PromptCategory category) {
    final current = state;
    if (current is PromptLibraryLoaded) {
      state = current.copyWith(activeCategory: category);
    }
  }

  void setQuery(String query) {
    final current = state;
    if (current is PromptLibraryLoaded) {
      state = current.copyWith(query: query);
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// AI SETTINGS NOTIFIER
// ══════════════════════════════════════════════════════════════════════════════

class AISettingsNotifier extends StateNotifier<AISettingsState> {
  AISettingsNotifier() : super(const AISettingsState());

  void setProvider(AIProviderOption provider) =>
      state = state.copyWith(provider: provider);
  void setTemperature(double value) =>
      state = state.copyWith(temperature: value);
  void setResponseLength(ResponseLength length) =>
      state = state.copyWith(responseLength: length);
  void toggleVoice() =>
      state = state.copyWith(voiceEnabled: !state.voiceEnabled);
  void toggleStreaming() =>
      state = state.copyWith(streamingEnabled: !state.streamingEnabled);
  void toggleSaveHistory() =>
      state = state.copyWith(saveHistory: !state.saveHistory);
  void toggleShareData() =>
      state = state.copyWith(shareData: !state.shareData);
}

// ══════════════════════════════════════════════════════════════════════════════
// VOICE NOTIFIER (placeholder — no real speech recognition)
// ══════════════════════════════════════════════════════════════════════════════

class VoiceNotifier extends StateNotifier<VoiceState> {
  VoiceNotifier() : super(const VoiceState());

  Future<void> startListening() async {
    state = state.copyWith(status: VoiceStatus.requesting);
    await Future.delayed(const Duration(milliseconds: 500));
    // Placeholder — real implementation uses speech_to_text package
    state = state.copyWith(
      status: VoiceStatus.error,
      errorMessage: 'Voice input coming soon! Tap the mic when it\'s ready.',
    );
  }

  void stopListening() {
    state = state.copyWith(status: VoiceStatus.idle, errorMessage: null);
  }

  void reset() => state = const VoiceState();
}
