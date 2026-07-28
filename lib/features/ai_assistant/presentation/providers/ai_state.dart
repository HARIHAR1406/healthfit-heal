import '../../../domain/entities/ai_insight_entity.dart';
import '../../../domain/entities/conversation_entity.dart';
import '../../../domain/entities/message_entity.dart';
import '../../../domain/entities/suggested_prompt_entity.dart';

// ══════════════════════════════════════════════════════════════════════════════
// CHAT STATE
// ══════════════════════════════════════════════════════════════════════════════

sealed class ChatState {
  const ChatState();
}

final class ChatInitial extends ChatState {
  const ChatInitial();
}

final class ChatLoading extends ChatState {
  const ChatLoading();
}

/// Active chat — may have messages and optionally be streaming.
final class ChatLoaded extends ChatState {
  const ChatLoaded({
    required this.conversationId,
    required this.messages,
    required this.coachType,
    this.isStreaming = false,
    this.isTyping = false,
    this.errorMessage,
  });

  final String conversationId;
  final List<MessageEntity> messages;
  final CoachType coachType;
  final bool isStreaming;
  final bool isTyping;
  final String? errorMessage;

  bool get isEmpty => messages.isEmpty;
  bool get hasError => errorMessage != null;

  ChatLoaded copyWith({
    List<MessageEntity>? messages,
    bool? isStreaming,
    bool? isTyping,
    String? errorMessage,
  }) =>
      ChatLoaded(
        conversationId: conversationId,
        messages: messages ?? this.messages,
        coachType: coachType,
        isStreaming: isStreaming ?? this.isStreaming,
        isTyping: isTyping ?? this.isTyping,
        errorMessage: errorMessage,
      );
}

final class ChatError extends ChatState {
  const ChatError({required this.message});
  final String message;
}

// ══════════════════════════════════════════════════════════════════════════════
// CONVERSATION LIST STATE
// ══════════════════════════════════════════════════════════════════════════════

sealed class ConversationListState {
  const ConversationListState();
}

final class ConversationListLoading extends ConversationListState {
  const ConversationListLoading();
}

final class ConversationListLoaded extends ConversationListState {
  const ConversationListLoaded({
    required this.conversations,
    this.query = '',
    this.filterArchived = false,
    this.filterPinned = false,
  });

  final List<ConversationEntity> conversations;
  final String query;
  final bool filterArchived;
  final bool filterPinned;

  List<ConversationEntity> get filtered {
    var list = conversations;

    if (filterPinned) {
      list = list.where((c) => c.isPinned).toList();
    } else if (filterArchived) {
      list = list.where((c) => c.isArchived).toList();
    } else {
      list = list.where((c) => c.isActive).toList();
    }

    if (query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((c) => c.title.toLowerCase().contains(q)).toList();
    }

    return list;
  }

  ConversationListLoaded copyWith({
    List<ConversationEntity>? conversations,
    String? query,
    bool? filterArchived,
    bool? filterPinned,
  }) =>
      ConversationListLoaded(
        conversations: conversations ?? this.conversations,
        query: query ?? this.query,
        filterArchived: filterArchived ?? this.filterArchived,
        filterPinned: filterPinned ?? this.filterPinned,
      );
}

final class ConversationListError extends ConversationListState {
  const ConversationListError({required this.message});
  final String message;
}

// ══════════════════════════════════════════════════════════════════════════════
// INSIGHT STATE
// ══════════════════════════════════════════════════════════════════════════════

sealed class InsightState {
  const InsightState();
}

final class InsightLoading extends InsightState {
  const InsightLoading();
}

final class InsightLoaded extends InsightState {
  const InsightLoaded({required this.insights, this.filterType});

  final List<AIInsightEntity> insights;
  final InsightType? filterType;

  List<AIInsightEntity> get filtered => filterType == null
      ? insights
      : insights.where((i) => i.type == filterType).toList();

  int get unreadCount => insights.where((i) => !i.isRead).length;
}

final class InsightError extends InsightState {
  const InsightError({required this.message});
  final String message;
}

// ══════════════════════════════════════════════════════════════════════════════
// PROMPT LIBRARY STATE
// ══════════════════════════════════════════════════════════════════════════════

sealed class PromptLibraryState {
  const PromptLibraryState();
}

final class PromptLibraryLoading extends PromptLibraryState {
  const PromptLibraryLoading();
}

final class PromptLibraryLoaded extends PromptLibraryState {
  const PromptLibraryLoaded({
    required this.prompts,
    this.activeCategory = PromptCategory.all,
    this.query = '',
  });

  final List<SuggestedPromptEntity> prompts;
  final PromptCategory activeCategory;
  final String query;

  List<SuggestedPromptEntity> get filtered {
    var list = activeCategory == PromptCategory.all
        ? prompts
        : prompts.where((p) => p.category == activeCategory).toList();
    if (query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((p) => p.text.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  PromptLibraryLoaded copyWith({
    PromptCategory? activeCategory,
    String? query,
  }) =>
      PromptLibraryLoaded(
        prompts: prompts,
        activeCategory: activeCategory ?? this.activeCategory,
        query: query ?? this.query,
      );
}

final class PromptLibraryError extends PromptLibraryState {
  const PromptLibraryError({required this.message});
  final String message;
}

// ══════════════════════════════════════════════════════════════════════════════
// AI SETTINGS STATE
// ══════════════════════════════════════════════════════════════════════════════

enum AIProviderOption { mock, gemini, openai, vertexAi, azureOpenAi }

extension AIProviderOptionX on AIProviderOption {
  String get label => switch (this) {
        AIProviderOption.mock => 'Mock (Offline)',
        AIProviderOption.gemini => 'Google Gemini',
        AIProviderOption.openai => 'OpenAI GPT-4',
        AIProviderOption.vertexAi => 'Vertex AI',
        AIProviderOption.azureOpenAi => 'Azure OpenAI',
      };

  bool get requiresApiKey => this != AIProviderOption.mock;
}

enum ResponseLength { concise, balanced, detailed }

extension ResponseLengthX on ResponseLength {
  String get label => switch (this) {
        ResponseLength.concise => 'Concise',
        ResponseLength.balanced => 'Balanced',
        ResponseLength.detailed => 'Detailed',
      };
}

final class AISettingsState {
  const AISettingsState({
    this.provider = AIProviderOption.mock,
    this.temperature = 0.7,
    this.responseLength = ResponseLength.balanced,
    this.voiceEnabled = false,
    this.streamingEnabled = true,
    this.saveHistory = true,
    this.shareData = false,
    this.isDarkChat = true,
  });

  final AIProviderOption provider;
  final double temperature;
  final ResponseLength responseLength;
  final bool voiceEnabled;
  final bool streamingEnabled;
  final bool saveHistory;
  final bool shareData;
  final bool isDarkChat;

  AISettingsState copyWith({
    AIProviderOption? provider,
    double? temperature,
    ResponseLength? responseLength,
    bool? voiceEnabled,
    bool? streamingEnabled,
    bool? saveHistory,
    bool? shareData,
    bool? isDarkChat,
  }) =>
      AISettingsState(
        provider: provider ?? this.provider,
        temperature: temperature ?? this.temperature,
        responseLength: responseLength ?? this.responseLength,
        voiceEnabled: voiceEnabled ?? this.voiceEnabled,
        streamingEnabled: streamingEnabled ?? this.streamingEnabled,
        saveHistory: saveHistory ?? this.saveHistory,
        shareData: shareData ?? this.shareData,
        isDarkChat: isDarkChat ?? this.isDarkChat,
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// VOICE STATE (placeholder)
// ══════════════════════════════════════════════════════════════════════════════

enum VoiceStatus { idle, requesting, listening, processing, error }

final class VoiceState {
  const VoiceState({
    this.status = VoiceStatus.idle,
    this.transcript = '',
    this.errorMessage,
  });

  final VoiceStatus status;
  final String transcript;
  final String? errorMessage;

  bool get isListening => status == VoiceStatus.listening;
  bool get isProcessing => status == VoiceStatus.processing;
  bool get hasError => errorMessage != null;

  VoiceState copyWith({
    VoiceStatus? status,
    String? transcript,
    String? errorMessage,
  }) =>
      VoiceState(
        status: status ?? this.status,
        transcript: transcript ?? this.transcript,
        errorMessage: errorMessage,
      );
}
