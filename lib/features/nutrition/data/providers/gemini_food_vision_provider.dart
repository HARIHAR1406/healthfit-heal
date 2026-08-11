import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../../core/security/api_key_manager.dart';
import '../../../../../core/utils/app_logger.dart';
import '../../../domain/entities/detected_food.dart';
import '../food_vision_service.dart';

/// Gemini 1.5 Flash Vision implementation of [FoodVisionService].
///
/// ── Provider details ──────────────────────────────────────────────────────────
/// Model: gemini-1.5-flash (via REST API)
/// Authentication: GEMINI_API_KEY via [ApiKeyManager] (dart-define, never logged)
/// Input: JPEG/PNG/WEBP bytes (inline base64)
/// Output: Structured JSON parsed to [RecognitionResult]
///
/// ── Prompt design ─────────────────────────────────────────────────────────────
/// The prompt explicitly instructs Gemini to:
///   1. Identify food items visible in the image
///   2. Estimate confidence for each food item (0.0–1.0)
///   3. Estimate quantity when clearly visible
///   4. Return ONLY structured JSON — no prose
///   5. NOT invent nutrition values
///   6. NOT fabricate food names that are not visible
///
/// ── Security ──────────────────────────────────────────────────────────────────
///   - API key: never logged, never stored, always via [ApiKeyManager]
///   - Image bytes: never logged (only byte count in debug)
///   - Raw response: never surfaced to UI (only parsed DetectedFood list)
///   - Prompt injection: input is image-only; no user text in the prompt
///
/// ── Graceful degradation ──────────────────────────────────────────────────────
///   - If the key is missing: [isAvailable] = false
///   - Network error: returns [RecognitionResult.failed]
///   - Parse error: returns [RecognitionResult.failed]
///   - Timeout: returns [RecognitionResult.failed]
///   - Rate limit: returns [RecognitionResult.failed] with rate-limit message
class GeminiFoodVisionProvider implements FoodVisionService {
  GeminiFoodVisionProvider({Dio? dio}) : _dio = dio ?? _buildDio();

  final Dio _dio;

  static const String _apiBase =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String _model = 'gemini-1.5-flash';

  @override
  String get providerName => 'Gemini Vision';

  @override
  bool get isMock => false;

  @override
  bool get isAvailable => ApiKeyManager.hasGeminiKey;

  @override
  Future<RecognitionResult> recognize(
    Uint8List imageBytes, {
    RecognitionOptions options = RecognitionOptions.defaults,
  }) async {
    if (!isAvailable) {
      log.warning(
        'GeminiFoodVisionProvider: API key not configured — '
        'cannot perform recognition',
      );
      return RecognitionResult.failed(
        reason: 'Gemini Vision API key not configured',
        providerName: providerName,
      );
    }

    final startMs = DateTime.now().millisecondsSinceEpoch;

    try {
      log.debug(
        'GeminiFoodVisionProvider: sending image '
        '(${(imageBytes.length / 1024).toStringAsFixed(0)} KB) '
        'to Gemini $\_model',
      );

      final response = await _dio
          .post<Map<String, dynamic>>(
            '$_apiBase/models/$_model:generateContent'
            '?key=${ApiKeyManager.geminiApiKey}',
            data: _buildRequestBody(imageBytes, options),
            options: Options(
              headers: {'Content-Type': 'application/json'},
              receiveTimeout: Duration(seconds: options.timeoutSeconds),
              sendTimeout: const Duration(seconds: 30),
            ),
          )
          .timeout(
            Duration(seconds: options.timeoutSeconds + 5),
            onTimeout: () => throw DioException(
              requestOptions: RequestOptions(),
              message: 'Gemini Vision request timed out',
              type: DioExceptionType.connectionTimeout,
            ),
          );

      final elapsed = DateTime.now().millisecondsSinceEpoch - startMs;
      return _parseResponse(response.data, elapsed, options);
    } on DioException catch (e) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - startMs;
      return _handleDioError(e, elapsed);
    } catch (e, st) {
      log.error(
        'GeminiFoodVisionProvider: unexpected error',
        error: e,
        stackTrace: st,
      );
      return RecognitionResult.failed(
        reason: 'Unexpected recognition error',
        providerName: providerName,
      );
    }
  }

  // ── Request builder ─────────────────────────────────────────────────────────

  Map<String, dynamic> _buildRequestBody(
    Uint8List imageBytes,
    RecognitionOptions options,
  ) {
    final base64Image = base64Encode(imageBytes);

    return {
      'contents': [
        {
          'parts': [
            {'text': _buildPrompt(options)},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Image,
              },
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.1, // Low temp for factual food identification
        'maxOutputTokens': 1024,
        'responseMimeType': 'application/json',
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_NONE',
        },
      ],
    };
  }

  String _buildPrompt(RecognitionOptions options) => '''
You are a food identification system. Analyze the image and identify all food items visible.

Return a JSON object with this exact structure:
{
  "foods": [
    {
      "name": "food name in English",
      "confidence": 0.0 to 1.0,
      "quantity": number or null,
      "unit": "grams|milliliters|pieces|cups|tablespoons|teaspoons|servings",
      "quantity_reliable": true or false,
      "serving_size_g": number or null,
      "alternatives": ["alternative name 1", "alternative name 2"]
    }
  ],
  "no_food_detected": true or false,
  "image_quality": "good|low|unacceptable"
}

Rules:
- Identify at most ${options.maxFoods} food items.
- Only include foods with confidence >= ${options.minimumConfidence}.
- If you cannot identify the food with any confidence, set confidence to 0.0.
- quantity: estimate the portion visible (e.g., 1 for 1 apple, 200 for 200g of rice).
- quantity_reliable: set to true ONLY if the quantity is clearly countable or measurable.
- serving_size_g: estimate the total grams of that food item. Set to null if not determinable.
- alternatives: up to 3 alternative food names if confidence < 0.8.
- Do NOT invent nutrition values. This is identification only.
- Do NOT add fields not listed above.
- If no food is visible, set no_food_detected to true and return an empty foods array.
''';

  // ── Response parser ─────────────────────────────────────────────────────────

  RecognitionResult _parseResponse(
    Map<String, dynamic>? responseData,
    int processingTimeMs,
    RecognitionOptions options,
  ) {
    if (responseData == null) {
      return RecognitionResult.failed(
        reason: 'Empty response from Gemini',
        providerName: providerName,
      );
    }

    try {
      final candidates =
          responseData['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        return RecognitionResult.failed(
          reason: 'No candidates in Gemini response',
          providerName: providerName,
        );
      }

      final content = candidates.first['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      final textPart = parts?.firstWhere(
        (p) => p['text'] != null,
        orElse: () => null,
      );

      if (textPart == null) {
        return RecognitionResult.failed(
          reason: 'No text part in Gemini response',
          providerName: providerName,
        );
      }

      final jsonText = textPart['text'] as String;
      final parsed = json.decode(jsonText) as Map<String, dynamic>;

      return _buildRecognitionResult(parsed, processingTimeMs);
    } catch (e) {
      log.warning(
        'GeminiFoodVisionProvider: failed to parse response — $e',
      );
      return RecognitionResult.failed(
        reason: 'Response parsing failed',
        providerName: providerName,
      );
    }
  }

  RecognitionResult _buildRecognitionResult(
    Map<String, dynamic> parsed,
    int processingTimeMs,
  ) {
    final noFoodDetected = parsed['no_food_detected'] as bool? ?? false;
    if (noFoodDetected) {
      return RecognitionResult.noFood(providerName: providerName);
    }

    final foodsJson = parsed['foods'] as List<dynamic>? ?? [];
    final foods = foodsJson
        .whereType<Map<String, dynamic>>()
        .map((f) => _parseFood(f))
        .whereType<DetectedFood>()
        .toList();

    if (foods.isEmpty) {
      return RecognitionResult.noFood(providerName: providerName);
    }

    // Determine overall status
    final hasHighConfidence = foods.any((f) => f.isHighConfidence);
    final status = hasHighConfidence
        ? OverallRecognitionStatus.success
        : OverallRecognitionStatus.partialDetection;

    log.info(
      'GeminiFoodVisionProvider: recognized ${foods.length} food(s) '
      'in ${processingTimeMs}ms',
    );

    return RecognitionResult(
      status: status,
      detectedFoods: foods,
      providerName: providerName,
      processingTimeMs: processingTimeMs,
    );
  }

  DetectedFood? _parseFood(Map<String, dynamic> f) {
    try {
      final name = f['name'] as String? ?? '';
      if (name.isEmpty) return null;

      final confidence = (f['confidence'] as num?)?.toDouble() ?? 0.0;
      final quantity = (f['quantity'] as num?)?.toDouble() ?? 1.0;
      final unitRaw = f['unit'] as String? ?? 'servings';
      final unit = parseServingUnit(unitRaw);
      final quantityReliable = f['quantity_reliable'] as bool? ?? false;
      final servingSizeG = (f['serving_size_g'] as num?)?.toDouble();
      final alts = (f['alternatives'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          [];

      final status = DetectedFood._statusFromConfidence(confidence);

      return DetectedFood(
        id: 'gemini_${name.toLowerCase().replaceAll(' ', '_')}_'
            '${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        confidenceScore: confidence,
        status: status,
        providerName: providerName,
        estimatedQuantity: quantity,
        estimatedUnit: unit,
        estimatedServingSizeG: servingSizeG,
        isQuantityReliable: quantityReliable,
        alternativeSuggestions: alts,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Error handler ───────────────────────────────────────────────────────────

  RecognitionResult _handleDioError(DioException e, int elapsed) {
    final statusCode = e.response?.statusCode;

    if (statusCode == 429) {
      log.warning('GeminiFoodVisionProvider: rate limit hit');
      return RecognitionResult.failed(
        reason: 'Rate limit exceeded',
        providerName: providerName,
      );
    }

    if (statusCode == 401 || statusCode == 403) {
      log.warning('GeminiFoodVisionProvider: authentication error ($statusCode)');
      return RecognitionResult.failed(
        reason: 'Authentication failed — check GEMINI_API_KEY',
        providerName: providerName,
      );
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      log.warning('GeminiFoodVisionProvider: timeout after ${elapsed}ms');
      return RecognitionResult.failed(
        reason: 'Recognition timed out',
        providerName: providerName,
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      log.warning('GeminiFoodVisionProvider: no network connection');
      return RecognitionResult.failed(
        reason: 'Network unavailable',
        providerName: providerName,
      );
    }

    log.error(
      'GeminiFoodVisionProvider: Dio error (${e.type}, $statusCode)',
      error: e,
    );
    return RecognitionResult.failed(
      reason: 'Recognition request failed',
      providerName: providerName,
    );
  }

  static Dio _buildDio() {
    final dio = Dio();
    dio.options.connectTimeout = const Duration(seconds: 15);
    dio.options.receiveTimeout = const Duration(seconds: 35);
    return dio;
  }
}
