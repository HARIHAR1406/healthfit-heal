import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/utils/app_logger.dart';

/// Dio interceptor that attaches the Bearer token and handles token refresh.
///
/// On every request, the stored [accessToken] is added to the
/// `Authorization` header. When a 401 is received, a single token
/// refresh attempt is made using the [refreshToken]. If that also
/// fails, the user should be redirected to the login screen.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio);

  final Dio _dio;
  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Do not attach token to auth endpoints
    if (_isAuthEndpoint(options.path)) {
      return handler.next(options);
    }

    final token = await SecureStorageService.instance.read(
      AppConstants.secureKeyAccessToken,
    );

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
    // Only attempt refresh on 401 from non-auth endpoints
    if (err.response?.statusCode != 401 ||
        _isAuthEndpoint(err.requestOptions.path) ||
        _isRefreshing) {
      return handler.next(err);
    }

    _isRefreshing = true;
    log.info('Access token expired — attempting refresh…');

    try {
      final refreshToken = await SecureStorageService.instance.read(
        AppConstants.secureKeyRefreshToken,
      );

      if (refreshToken == null || refreshToken.isEmpty) {
        log.warning('No refresh token found — clearing session.');
        await _clearSession();
        _isRefreshing = false;
        return handler.next(err);
      }

      // ── Token refresh call ──────────────────────────────────────────────
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final newAccessToken =
          (response.data?['access_token'] as String?) ?? '';
      final newRefreshToken =
          (response.data?['refresh_token'] as String?) ?? '';

      if (newAccessToken.isEmpty) {
        await _clearSession();
        _isRefreshing = false;
        return handler.next(err);
      }

      await SecureStorageService.instance.write(
        AppConstants.secureKeyAccessToken,
        newAccessToken,
      );
      if (newRefreshToken.isNotEmpty) {
        await SecureStorageService.instance.write(
          AppConstants.secureKeyRefreshToken,
          newRefreshToken,
        );
      }

      log.info('Token refreshed successfully.');

      // Retry the original request with the new token
      final retryOptions = err.requestOptions.copyWith(
        headers: {
          ...err.requestOptions.headers,
          'Authorization': 'Bearer $newAccessToken',
        },
      );

      final retryResponse = await _dio.fetch<dynamic>(retryOptions);
      _isRefreshing = false;
      return handler.resolve(retryResponse);
    } catch (e) {
      log.error('Token refresh failed.', error: e);
      await _clearSession();
      _isRefreshing = false;
      handler.next(err);
    }
  }

  Future<void> _clearSession() async {
    await SecureStorageService.instance.deleteAll();
    // TODO: Dispatch a global auth-failure event or navigate to login.
    // Example: ref.read(authNotifierProvider.notifier).signOut();
  }

  bool _isAuthEndpoint(String path) =>
      path.contains('/auth/login') ||
      path.contains('/auth/register') ||
      path.contains('/auth/refresh');
}
