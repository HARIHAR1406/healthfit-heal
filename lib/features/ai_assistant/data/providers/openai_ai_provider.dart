import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../config/env/app_secrets.dart';
import '../../domain/entities/ai_insight_entity.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/suggested_prompt_entity.dart';
import '../../domain/repositories/ai_repository.dart';
import '../repositories/mock_ai_repository.dart';

/// OpenAI Chat Completions implementation of [AIRepository].
///
/// Uses the OpenAI Chat Completions API via Dio with optional streaming.
///
/// ── API Reference ────────────────────────────────────────────────────────────
///   https://platform.openai.com/docs/api-reference/chat
///
/// ── Configuration (dart-define) ──────────────────────────────────────────────
///   --dart-define=AI_PROVIDER=openai
///   --dart-define=OPENAI_API_KEY=sk-your_key
///   --dart-define=AI_MODEL=gpt-4o-mini   (optional, default: gpt-4o-mini)
class OpenAIProvider implements AIRepository {
  OpenAIProvider({
    Dio? dio,
    String? model,
  })  : _model = model ??
            (AppSecrets.aiModel.isNotEmpty
                ? AppSecrets.aiModel
                : 'gpt-4o-mini'),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://api.openai.com/v1',
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 60),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer ${AppSecrets.openAiApiKey}',
                },
              ),
            ),
        _mock = MockAIRepository();

  final Dio _dio;
  final String _model;
  final MockAIRepository _mock;

  static const int _maxHistoryMessages = 20;

  // ── System Message ─────────────────────────────────────────────────────────

  static const Map<String, String> _systemMessage = {
    'role': 'system',
    'content': '''
You are HealthFit Heal AI Coach, an expert personal health and fitness assistant.

Your expertise includes personalized workout plans, nutrition guidance, sleep optimization, 
mental wellness, health data interpretation, and goal tracking.

Always be concise, friendly, and motivating. Use markdown formatting for structured advice.
For medical concerns, always encourage consulting healthcare professionals.
Never diagnose medical conditions.
''',
  };

  // ── Chat ───────────────────────────────────────────────────────────────────

  @override
  Future<String> sendMessage(
    List<MessageEntity> history,
    String userMessage, {
    CoachType coachType = CoachType.general,
  }) async {
    try {
      final messages = _buildMessages(history, userMessage, coachType);

      final response = await _dio.post<Map<String, dynamic>>(
        '/chat/completions',
        data: {
          'model': _model,
          'messages': messages,
          'max_tokens': 2048,
          'temperature': 0.7,
          'stream': false,
        },
      );

      final text = _extractText(response.data);
      log.debug('OpenAI: response received (${text.length} chars)');
      return text;
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e, st) {
      throw UnknownException(message: 'AI service error: $e', stackTrace: st);
    }
  }

  @override
  Future<Stream<String>> sendMessageStream(
    List<MessageEntity> history,
    String userMessage, {
    CoachType coachType = CoachType.general,
  }) async {
    final messages = _buildMessages(history, userMessage, coachType);
    final controller = StreamController<String>();

    try {
      final response = await _dio.post<ResponseBody>(
        '/chat/completions',
        data: {
          'model': _model,
          'messages': messages,
          'max_tokens': 2048,
          'temperature': 0.7,
          'stream': true,
        },
        options: Options(responseType: ResponseType.stream),
      );

      response.data!.stream.transform(utf8.decoder).listen(
        (chunk) {
          for (final line in chunk.split('\n')) {
            if (!line.startsWith('data: ')) continue;
            final data = line.substring(6).trim();
            if (data == '[DONE]') {
              controller.close();
              return;
            }
            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              final delta = json['choices']?[0]?['delta']?['content'] as String?;
              if (delta != null && delta.isNotEmpty) {
                controller.add(delta);
              }
            } catch (_) {
              // Skip malformed SSE lines
            }
          }
        },
        onDone: () {
          if (!controller.isClosed) controller.close();
        },
        onError: (Object e) {
          controller.addError(e);
          controller.close();
        },
        cancelOnError: true,
      );
    } catch (e) {
      controller.addError(e);
      controller.close();
    }

    return controller.stream;
  }

  @override
  Future<String> generateTitle(List<MessageEntity> messages) async {
    if (messages.isEmpty) return 'New Chat';
    try {
      final firstMessage = messages
          .firstWhere(
            (m) => m.role == MessageRole.user,
            orElse: () => messages.first,
          )
          .content;

      final response = await _dio.post<Map<String, dynamic>>(
        '/chat/completions',
        data: {
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': 'Generate a short 4-6 word title for this conversation. '
                  'Reply with ONLY the title, no punctuation:\n"$firstMessage"',
            },
          ],
          'max_tokens': 20,
          'temperature': 0.3,
        },
      );
      return _extractText(response.data).trim();
    } catch (e) {
      log.warning('OpenAI: generateTitle failed', error: e);
      return 'Health Chat';
    }
  }

  // ── Conversations / Prompts / Insights ────────────────────────────────────

  @override
  Future<List<ConversationEntity>> getConversations() =>
      _mock.getConversations();

  @override
  Future<ConversationEntity?> getConversation(String id) =>
      _mock.getConversation(id);

  @override
  Future<ConversationEntity> createConversation({
    String? title,
    CoachType coachType = CoachType.general,
  }) =>
      _mock.createConversation(title: title, coachType: coachType);

  @override
  Future<void> updateConversation(ConversationEntity conversation) =>
      _mock.updateConversation(conversation);

  @override
  Future<void> deleteConversation(String id) => _mock.deleteConversation(id);

  @override
  Future<void> clearAllConversations() => _mock.clearAllConversations();

  @override
  Future<List<SuggestedPromptEntity>> getSuggestedPrompts({
    PromptCategory? category,
  }) =>
      _mock.getSuggestedPrompts(category: category);

  @override
  Future<List<AIInsightEntity>> getInsights() => _mock.getInsights();

  @override
  Future<void> markInsightRead(String insightId) =>
      _mock.markInsightRead(insightId);

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _buildMessages(
    List<MessageEntity> history,
    String userMessage,
    CoachType coachType,
  ) {
    final systemContent = _systemMessage['content']! + _coachAddendum(coachType);

    final trimmedHistory = history.length > _maxHistoryMessages
        ? history.sublist(history.length - _maxHistoryMessages)
        : history;

    return [
      {'role': 'system', 'content': systemContent},
      for (final msg in trimmedHistory)
        {
          'role': msg.role == MessageRole.user ? 'user' : 'assistant',
          'content': msg.content,
        },
      {'role': 'user', 'content': userMessage},
    ];
  }

  String _extractText(Map<String, dynamic>? data) {
    try {
      final choices = (data?['choices'] as List<dynamic>?) ?? [];
      if (choices.isEmpty) return '';
      return (choices.first['message']?['content'] as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  String _coachAddendum(CoachType type) => switch (type) {
        CoachType.fitness => ' Focus on workout plans and exercise.',
        CoachType.nutrition => ' Focus on nutrition and meal planning.',
        CoachType.wellness => ' Focus on mental wellness and sleep.',
        CoachType.medical =>
          ' Always recommend consulting a doctor. General health education only.',
        _ => '',
      };

  AppException _mapDioError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data as Map<String, dynamic>?;
    final errorMsg =
        (data?['error'] as Map<String, dynamic>?)?['message'] as String?;

    if (status == 401) {
      return const UnauthorizedException(message: 'Invalid OpenAI API key.');
    }
    if (status == 429) {
      return const ServerException(
        message: 'OpenAI rate limit reached. Please try again later.',
        statusCode: 429,
        code: 'RATE_LIMITED',
      );
    }
    if (status == 400) {
      return ValidationException(message: errorMsg ?? 'Bad request to OpenAI.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }
    return UnknownException(message: errorMsg ?? 'OpenAI error: ${e.message}');
  }
}

// ── Riverpod Provider ──────────────────────────────────────────────────────────

final openAIProviderProvider = Provider<AIRepository>(
  (_) => OpenAIProvider(),
  name: 'openAIProviderProvider',
);
