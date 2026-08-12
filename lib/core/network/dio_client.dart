import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../../config/env/environment.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/app_logger.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/connectivity_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/performance_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'token_provider.dart';

/// Production-ready [Dio] HTTP client factory for HealthFit Heal.
///
/// ── Interceptor order (applied sequentially) ─────────────────────────────────
///   1. [ConnectivityInterceptor] — rejects immediately if offline
///   2. [LoggingInterceptor]     — logs requests (PII-safe in production)
///   3. [AuthInterceptor]        — attaches Bearer token + handles 401 refresh
///   4. [RetryInterceptor]       — retries on 5xx / timeouts with backoff
///   5. [PerformanceInterceptor] — records Firebase Performance metrics
///
/// ── Instances ─────────────────────────────────────────────────────────────────
///   [DioClient.authenticated]   — with token injection (most API calls)
///   [DioClient.unauthenticated] — without token (public endpoints, file uploads)
class DioClient {
  DioClient._();

  static Dio? _authenticated;
  static Dio? _unauthenticated;

  // ── Active Token Provider ──────────────────────────────────────────────────

  /// Set this before creating instances to inject the token provider.
  /// Called by [InjectionContainer] on app startup.
  static TokenProvider _tokenProvider = const NoOpTokenProvider();

  static void setTokenProvider(TokenProvider provider) {
    _tokenProvider = provider;
    // Reset instances so they pick up the new provider
    reset();
    log.info('DioClient: token provider updated → ${provider.runtimeType}');
  }

  // ── Instance Access ────────────────────────────────────────────────────────

  /// Authenticated Dio instance (attaches Bearer token, handles refresh).
  static Dio get instance => authenticated;

  /// Authenticated Dio instance.
  static Dio get authenticated {
    _authenticated ??= _create(withAuth: true);
    return _authenticated!;
  }

  /// Unauthenticated Dio instance — for public endpoints and file uploads.
  static Dio get unauthenticated {
    _unauthenticated ??= _create(withAuth: false);
    return _unauthenticated!;
  }

  /// Re-creates all instances (called on logout or token provider change).
  static void reset() {
    _authenticated = null;
    _unauthenticated = null;
    log.info('DioClient: instances reset');
  }

  // ── Factory ────────────────────────────────────────────────────────────────

  static Dio _create({required bool withAuth}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: Environment.baseUrl,
        connectTimeout: Environment.connectTimeout,
        receiveTimeout: Environment.receiveTimeout,
        sendTimeout: Environment.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Platform': 'android',
          'X-App-Version': AppConstants.appVersion,
        },
        responseType: ResponseType.json,
      ),
    );

    // ── Interceptors (order matters) ─────────────────────────────────────────
    dio.interceptors.addAll([
      ConnectivityInterceptor(Connectivity()),
      LoggingInterceptor(),
      if (withAuth) AuthInterceptor(dio, _tokenProvider),
      RetryInterceptor(dio: dio),
      if (Environment.enablePerformanceMonitoring) PerformanceInterceptor(),
    ]);

    log.info(
      'DioClient: created '
      '(auth=$withAuth, env=${Environment.name}, base=${Environment.baseUrl})',
    );
    return dio;
  }
}

/// Maps a [DioException] to a typed [AppException].
AppException mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const TimeoutException();

    case DioExceptionType.connectionError:
      // Check if this is an offline rejection from ConnectivityInterceptor
      if (e.error is NetworkException) return e.error as NetworkException;
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
        429 => const ServerException(
            message: 'Too many requests. Please try again later.',
            statusCode: 429,
            code: 'RATE_LIMITED',
          ),
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

