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

/// Google Gemini implementation of [AIRepository].
///
/// Uses the Gemini REST API via Dio — no additional Dart package required.
/// Supports both full-response and streaming modes.
///
/// ── API Reference ────────────────────────────────────────────────────────────
///   https://ai.google.dev/api/generate-content
///
/// ── Configuration (dart-define) ──────────────────────────────────────────────
///   --dart-define=AI_PROVIDER=gemini
///   --dart-define=GEMINI_API_KEY=your_key
///   --dart-define=AI_MODEL=gemini-1.5-flash   (optional, default: flash)
class GeminiAIProvider implements AIRepository {
  GeminiAIProvider({
    Dio? dio,
    String? model,
  })  : _model = model ??
            (AppSecrets.aiModel.isNotEmpty
                ? AppSecrets.aiModel
                : 'gemini-1.5-flash'),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 60),
                headers: {'Content-Type': 'application/json'},
              ),
            ),
        _mock = MockAIRepository(); // Fallback for non-chat operations

  final Dio _dio;
  final String _model;
  final MockAIRepository _mock;

  static const int _maxHistoryMessages = 20;

  // ── System Prompt ──────────────────────────────────────────────────────────

  static const String _systemPrompt = '''
You are HealthFit Heal AI Coach, an expert personal health and fitness assistant.

Your expertise includes:
- Personalized workout plans and exercise form
- Nutrition guidance and meal planning
- Sleep optimization and recovery
- Mental wellness and stress management
- Medical health data interpretation (always remind users to consult doctors for medical decisions)
- Goal setting and progress tracking

Response style:
- Be concise, friendly, and motivating
- Use bullet points and headers for structured advice
- Always encourage consulting healthcare professionals for medical concerns
- Personalize responses based on the user's health context when provided
- Never diagnose medical conditions
''';

  // ── Chat ───────────────────────────────────────────────────────────────────

  @override
  Future<String> sendMessage(
    List<MessageEntity> history,
    String userMessage, {
    CoachType coachType = CoachType.general,
  }) async {
    try {
      final contents = _buildContents(history, userMessage, coachType);

      final response = await _dio.post<Map<String, dynamic>>(
        '/models/$_model:generateContent',
        queryParameters: {'key': AppSecrets.geminiApiKey},
        data: {
          'contents': contents,
          'systemInstruction': {
            'parts': [
              {'text': _systemPrompt + _coachPrompt(coachType)},
            ],
          },
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 2048,
          },
          'safetySettings': _safetySettings,
        },
      );

      final text = _extractText(response.data);
      log.debug('Gemini: response received (${text.length} chars)');
      return text;
    } on DioException catch (e) {
      log.error('Gemini: DioException', error: e);
      throw _mapDioError(e);
    } catch (e, st) {
      log.error('Gemini: unexpected error', error: e, stackTrace: st);
      throw UnknownException(message: 'AI service error: $e');
    }
  }

  @override
  Future<Stream<String>> sendMessageStream(
    List<MessageEntity> history,
    String userMessage, {
    CoachType coachType = CoachType.general,
  }) async {
    final contents = _buildContents(history, userMessage, coachType);
    final controller = StreamController<String>();

    try {
      final response = await _dio.post<ResponseBody>(
        '/models/$_model:streamGenerateContent',
        queryParameters: {
          'key': AppSecrets.geminiApiKey,
          'alt': 'sse',
        },
        data: {
          'contents': contents,
          'systemInstruction': {
            'parts': [
              {'text': _systemPrompt + _coachPrompt(coachType)},
            ],
          },
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 2048,
          },
        },
        options: Options(responseType: ResponseType.stream),
      );

      final stream = response.data!.stream
          .cast<List<int>>()
          .transform(utf8.decoder);

      stream.listen(
        (chunk) {
          // SSE format: "data: {...json...}\n\n"
          for (final line in (chunk as String).split('\n')) {
            if (line.startsWith('data: ')) {
              try {
                final jsonStr = line.substring(6).trim();
                if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;
                final json = jsonDecode(jsonStr) as Map<String, dynamic>;
                final text = _extractText(json);
                if (text.isNotEmpty) controller.add(text);
              } catch (_) {
                // Skip malformed SSE lines
              }
            }
          }
        },
        onDone: controller.close,
        onError: (Object e) {
          log.error('Gemini: stream error', error: e);
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
        '/models/$_model:generateContent',
        queryParameters: {'key': AppSecrets.geminiApiKey},
        data: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {
                  'text': 'Generate a short 4-6 word title for this conversation. '
                      'Reply with ONLY the title, no punctuation:\n\n"$firstMessage"',
                },
              ],
            },
          ],
          'generationConfig': {'maxOutputTokens': 20, 'temperature': 0.3},
        },
      );
      return _extractText(response.data).trim();
    } catch (e) {
      log.warning('Gemini: generateTitle failed', error: e);
      return 'Health Chat';
    }
  }

  // ── Conversations / Prompts / Insights (delegated to Mock) ────────────────
  // These are local operations — no AI API call needed.

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

  List<Map<String, dynamic>> _buildContents(
    List<MessageEntity> history,
    String userMessage,
    CoachType coachType,
  ) {
    // Limit history to last N messages to stay within token limits
    final trimmedHistory = history.length > _maxHistoryMessages
        ? history.sublist(history.length - _maxHistoryMessages)
        : history;

    return [
      for (final msg in trimmedHistory)
        {
          'role': msg.role == MessageRole.user ? 'user' : 'model',
          'parts': [
            {'text': msg.content},
          ],
        },
      {
        'role': 'user',
        'parts': [
          {'text': userMessage},
        ],
      },
    ];
  }

  String _extractText(Map<String, dynamic>? data) {
    try {
      final candidates =
          (data?['candidates'] as List<dynamic>?) ?? [];
      if (candidates.isEmpty) return '';
      final content = candidates.first['content'] as Map<String, dynamic>?;
      final parts = (content?['parts'] as List<dynamic>?) ?? [];
      if (parts.isEmpty) return '';
      return (parts.first['text'] as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  String _coachPrompt(CoachType type) => switch (type) {
        CoachType.fitness =>
          '\n\nFocus on: workout plans, exercise form, fitness goals.',
        CoachType.nutrition =>
          '\n\nFocus on: meal planning, macros, healthy eating habits.',
        CoachType.lifestyle =>
          '\n\nFocus on: mental health, stress management, sleep quality.',
        CoachType.health =>
          '\n\nAlways remind users to consult their doctor. Provide general health education only.',
        CoachType.general => '',
        _ => '',
      };

  static const List<Map<String, dynamic>> _safetySettings = [
    {
      'category': 'HARM_CATEGORY_HARASSMENT',
      'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
    },
    {
      'category': 'HARM_CATEGORY_HATE_SPEECH',
      'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
    },
    {
      'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
      'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
    },
    {
      'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
      'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
    },
  ];

  AppException _mapDioError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401 || status == 403) {
      return const UnauthorizedException(message: 'Invalid Gemini API key.');
    }
    if (status == 429) {
      return const ServerException(
        message: 'Gemini rate limit reached. Please try again later.',
        statusCode: 429,
        code: 'RATE_LIMITED',
      );
    }
    if (e.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }
    return UnknownException(message: 'Gemini error: ${e.message}');
  }
}

// ── Riverpod Provider ──────────────────────────────────────────────────────────

final geminiAIProviderProvider = Provider<AIRepository>(
  (_) => GeminiAIProvider(),
  name: 'geminiAIProviderProvider',
);

