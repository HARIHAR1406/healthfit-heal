import 'package:dio/dio.dart';

import '../../../core/utils/app_logger.dart';
import '../token_provider.dart';

/// Dio interceptor that attaches Bearer tokens and handles 401 token refresh.
///
/// Uses [TokenProvider] for token retrieval — decoupled from Firebase or
/// custom backend, so this interceptor works with any auth strategy.
///
/// Flow:
///   1. onRequest  → read token from [TokenProvider], add to Authorization header
///   2. onError(401) → call [TokenProvider.refreshAccessToken()] once
///   3. If refresh succeeds → retry original request with new token
///   4. If refresh fails   → clear tokens + let the error propagate
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio, this._tokenProvider);

  final Dio _dio;
  final TokenProvider _tokenProvider;
  bool _isRefreshing = false;

  /// Auth endpoint paths that should NOT receive a token header.
  static const _authPaths = {
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
    '/auth/forgot-password',
    '/auth/google',
  };

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isAuthEndpoint(options.path)) {
      return handler.next(options);
    }

    final token = await _tokenProvider.getAccessToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401 ||
        _isAuthEndpoint(err.requestOptions.path) ||
        _isRefreshing) {
      return handler.next(err);
    }

    _isRefreshing = true;
    log.info('AuthInterceptor: 401 received — attempting token refresh…');

    try {
      final newToken = await _tokenProvider.refreshAccessToken();

      if (newToken == null || newToken.isEmpty) {
        log.warning('AuthInterceptor: refresh returned no token — clearing session');
        await _tokenProvider.clearTokens();
        _isRefreshing = false;
        return handler.next(err);
      }

      log.info('AuthInterceptor: token refreshed — retrying original request');

      // Retry the original request with the new token
      final retryOptions = err.requestOptions.copyWith(
        headers: {
          ...err.requestOptions.headers,
          'Authorization': 'Bearer $newToken',
        },
      );

      final retryResponse = await _dio.fetch<dynamic>(retryOptions);
      _isRefreshing = false;
      return handler.resolve(retryResponse);
    } catch (e) {
      log.error('AuthInterceptor: token refresh failed — clearing session', error: e);
      await _tokenProvider.clearTokens();
      _isRefreshing = false;
      handler.next(err);
    }
  }

  bool _isAuthEndpoint(String path) =>
      _authPaths.any((p) => path.contains(p));
}
