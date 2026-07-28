import 'package:dio/dio.dart';

import '../../config/env/environment.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/app_logger.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Configured [Dio] HTTP client factory for HealthFit Heal.
///
/// All network calls in the app should use an instance returned
/// by [DioClient.instance]. Interceptors are applied in order:
///   1. [LoggingInterceptor] — logs requests/responses.
///   2. [AuthInterceptor]   — attaches bearer token & handles 401 refresh.
class DioClient {
  DioClient._();

  static Dio? _dio;

  /// Returns the singleton [Dio] instance, creating it on first call.
  static Dio get instance {
    _dio ??= _create();
    return _dio!;
  }

  /// Re-creates the [Dio] instance (use after logout to clear auth state).
  static void reset() => _dio = null;

  static Dio _create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: Environment.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        sendTimeout: AppConstants.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Platform': 'android',
          'X-App-Version': AppConstants.appVersion,
        },
        responseType: ResponseType.json,
      ),
    );

    // ── Interceptors (order matters) ──────────────────────────────────────
    dio.interceptors.addAll([
      LoggingInterceptor(),
      AuthInterceptor(dio),
    ]);

    log.info('DioClient created → ${Environment.baseUrl}');
    return dio;
  }
}

/// Maps a [DioException] to an [AppException].
AppException mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const TimeoutException();

    case DioExceptionType.connectionError:
      return const NetworkException();

    case DioExceptionType.badResponse:
      final statusCode = e.response?.statusCode ?? 0;
      final data = e.response?.data;
      final message = _extractMessage(data);
      final code = _extractCode(data);

      return switch (statusCode) {
        401 => const UnauthorizedException(),
        403 => const ForbiddenException(),
        404 => const NotFoundException(),
        409 => ConflictException(message: message),
        422 => ValidationException(message: message),
        _ => ServerException(
            message: message,
            statusCode: statusCode,
            code: code,
          ),
      };

    case DioExceptionType.cancel:
      return const UnknownException(message: 'Request was cancelled.');

    case DioExceptionType.badCertificate:
      return const NetworkException(
        message: 'SSL certificate verification failed.',
        code: 'SSL_ERROR',
      );

    case DioExceptionType.unknown:
      if (e.message?.contains('SocketException') == true) {
        return const NetworkException();
      }
      return UnknownException(message: e.message ?? 'Unknown network error.');
  }
}

String _extractMessage(dynamic data) {
  if (data is Map<String, dynamic>) {
    return (data['message'] as String?) ??
        (data['error'] as String?) ??
        'An error occurred.';
  }
  return 'An error occurred.';
}

String? _extractCode(dynamic data) {
  if (data is Map<String, dynamic>) {
    return data['code'] as String?;
  }
  return null;
}
