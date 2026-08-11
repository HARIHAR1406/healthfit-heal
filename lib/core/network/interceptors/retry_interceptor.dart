import 'dart:math' as math;

import 'package:dio/dio.dart';

import '../../utils/app_logger.dart';
import '../../../config/env/environment.dart';

/// Dio interceptor that retries failed requests with exponential backoff.
///
/// Retry policy:
///   - Maximum [maxRetries] attempts (default: from [Environment.maxRetries])
///   - Exponential backoff: [baseDelayMs] * 2^(attempt - 1) + jitter
///   - Retryable conditions: connection timeout, server errors (5xx), 429 Too Many Requests
///   - Non-retryable: 4xx (except 429), cancel, bad certificate
///
/// Request headers:
///   - `X-Retry-Count: n` is set on retried requests for server-side observability
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required Dio dio,
    int? maxRetries,
    int baseDelayMs = 1000,
  })  : _dio = dio,
        _maxRetries = maxRetries ?? Environment.maxRetries,
        _baseDelayMs = baseDelayMs;

  final Dio _dio;
  final int _maxRetries;
  final int _baseDelayMs;

  static const String _retryCountKey = 'retry_count';
  final _random = math.Random();

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = err.requestOptions;
    final retryCount = (requestOptions.extra[_retryCountKey] as int?) ?? 0;

    if (!_shouldRetry(err) || retryCount >= _maxRetries) {
      return handler.next(err);
    }

    final nextRetryCount = retryCount + 1;
    final delay = _computeDelay(nextRetryCount);

    log.warning(
      'RetryInterceptor: attempt $nextRetryCount/$_maxRetries '
      'for ${requestOptions.method} ${requestOptions.path} '
      '(delay=${delay}ms, reason=${err.type.name})',
    );

    await Future<void>.delayed(Duration(milliseconds: delay));

    // Update retry count and marker header
    requestOptions.extra[_retryCountKey] = nextRetryCount;
    requestOptions.headers['X-Retry-Count'] = nextRetryCount.toString();

    try {
      final response = await _dio.fetch<dynamic>(requestOptions);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }

  bool _shouldRetry(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final code = err.response?.statusCode ?? 0;
        return code >= 500 || code == 429;
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return false;
    }
  }

  /// Exponential backoff with ±25% jitter to avoid thundering herd.
  int _computeDelay(int attempt) {
    final exponential = _baseDelayMs * math.pow(2, attempt - 1).toInt();
    final capped = math.min(exponential, 30000); // cap at 30s
    final jitter = (_random.nextDouble() * 0.5 - 0.25) * capped;
    return (capped + jitter).round();
  }
}
