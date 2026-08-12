import '../entities/ai_insight_entity.dart';
import '../entities/conversation_entity.dart';
import '../entities/message_entity.dart';
import '../entities/suggested_prompt_entity.dart';

/// Provider-agnostic AI repository interface.
///
/// Swap [MockAIRepository] with [GeminiRepository], [OpenAIRepository], etc.
/// Only this file and the provider registration need to change.
abstract class AIRepository {
  // ── Chat / Messaging ───────────────────────────────────────────────────────

  /// Sends a message and returns the complete AI response.
  ///
  /// [history] contains prior messages for context.
  /// [coachType] optionally primes the AI persona.
  Future<String> sendMessage(
    List<MessageEntity> history,
    String userMessage, {
    CoachType coachType,
  });

  /// Sends a message and streams the AI response token-by-token.
  ///
  /// Useful for real-time streaming UIs.
  Future<Stream<String>> sendMessageStream(
    List<MessageEntity> history,
    String userMessage, {
    CoachType coachType,
  });

  /// Generates a short conversation title from the first user message.
  Future<String> generateTitle(List<MessageEntity> messages);

  // ── Conversations ──────────────────────────────────────────────────────────

  /// Retrieves all non-deleted conversations, newest first.
  Future<List<ConversationEntity>> getConversations();

  /// Retrieves a single conversation by ID including its messages.
  Future<ConversationEntity?> getConversation(String id);

  /// Creates and persists a new conversation.
  Future<ConversationEntity> createConversation({
    String? title,
    CoachType coachType,
  });

  /// Persists updates to an existing conversation (title, status, pin, etc.).
  Future<void> updateConversation(ConversationEntity conversation);

  /// Soft-deletes a conversation.
  Future<void> deleteConversation(String id);

  /// Permanently purges all conversations.
  Future<void> clearAllConversations();

  // ── Prompts ────────────────────────────────────────────────────────────────

  /// Returns the curated list of suggested prompts.
  ///
  /// Optionally filtered by [category].
  Future<List<SuggestedPromptEntity>> getSuggestedPrompts({
    PromptCategory? category,
  });

  // ── Insights ───────────────────────────────────────────────────────────────

  /// Returns AI-generated health/fitness insight cards.
  Future<List<AIInsightEntity>> getInsights();

  /// Marks an insight as read.
  Future<void> markInsightRead(String insightId);
}

