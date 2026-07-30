import 'package:dio/dio.dart';

import '../../../config/env/environment.dart';
import '../../utils/app_logger.dart';

/// Production-safe logging interceptor for Dio.
///
/// Development mode: full request + response body logged.
/// Production mode: method + URL + status code only. Request/response bodies
///   are stripped to avoid leaking PII or tokens in logs.
///
/// PII scrubbing: removes known sensitive fields from log output:
///   password, token, access_token, refresh_token, id_token, secret.
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor();

  static const Set<String> _sensitiveKeys = {
    'password',
    'token',
    'access_token',
    'refresh_token',
    'id_token',
    'client_secret',
    'secret',
    'authorization',
    'x-api-key',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (Environment.enableLogging) {
      log.debug(
        '→ [${options.method}] ${options.path}\n'
        '   Headers: ${_scrubHeaders(options.headers)}\n'
        '   Data: ${_scrubBody(options.data)}',
      );
    } else {
      log.trace('→ [${options.method}] ${options.path}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final statusCode = response.statusCode;
    final path = response.requestOptions.path;
    final method = response.requestOptions.method;

    if (Environment.enableLogging) {
      log.debug(
        '← [$statusCode] [$method] $path\n'
        '   Response: ${_scrubBody(response.data)}',
      );
    } else {
      log.trace('← [$statusCode] [$method] $path');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode ?? 0;
    final path = err.requestOptions.path;
    final method = err.requestOptions.method;

    log.warning(
      '✗ [$statusCode] [$method] $path — ${err.type.name}: ${err.message}',
    );
    handler.next(err);
  }

  Map<String, dynamic> _scrubHeaders(Map<String, dynamic> headers) {
    return {
      for (final entry in headers.entries)
        entry.key: _isSensitiveKey(entry.key) ? '***' : entry.value,
    };
  }

  dynamic _scrubBody(dynamic body) {
    if (!Environment.enableLogging) return '[REDACTED]';
    if (body is Map<String, dynamic>) {
      return {
        for (final entry in body.entries)
          entry.key: _isSensitiveKey(entry.key) ? '***' : entry.value,
      };
    }
    return body;
  }

  bool _isSensitiveKey(String key) =>
      _sensitiveKeys.contains(key.toLowerCase());
}
