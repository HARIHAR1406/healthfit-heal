import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../../errors/app_exception.dart';
import '../../utils/app_logger.dart';

/// Dio interceptor that checks network connectivity before every request.
///
/// If the device is offline, the request is immediately rejected with a
/// [NetworkException] — no socket attempt is made. This prevents hanging
/// requests that would otherwise wait for [connectTimeout] to expire.
///
/// A `NetworkException` with `code: 'OFFLINE'` is thrown so the sync queue
/// and UI layers can distinguish offline rejection from server errors.
class ConnectivityInterceptor extends Interceptor {
  ConnectivityInterceptor(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip connectivity check for explicitly marked requests (e.g. local calls)
    if (options.extra['skip_connectivity_check'] == true) {
      return handler.next(options);
    }

    final results = await _connectivity.checkConnectivity();
    final isOnline = results.any((r) => r != ConnectivityResult.none);

    if (!isOnline) {
      log.warning(
        'ConnectivityInterceptor: offline — rejecting '
        '${options.method} ${options.path}',
      );
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: const NetworkException(
            message: 'No internet connection.',
            code: 'OFFLINE',
          ),
          message: 'Device is offline.',
        ),
      );
    }

    handler.next(options);
  }
}

