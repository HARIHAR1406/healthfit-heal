import 'package:dio/dio.dart';

import '../../../core/utils/app_logger.dart';

/// Dio interceptor that logs all requests, responses, and errors.
///
/// Sensitive headers (Authorization) are redacted in non-debug builds.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    log.debug(
      '→ ${options.method} ${options.uri}\n'
      '  Headers: ${_sanitiseHeaders(options.headers)}\n'
      '  Data: ${options.data}',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    log.debug(
      '← ${response.statusCode} ${response.requestOptions.uri}\n'
      '  Data: ${response.data}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    log.error(
      '✗ ${err.requestOptions.method} ${err.requestOptions.uri}\n'
      '  Type: ${err.type}\n'
      '  Response: ${err.response?.data}',
      error: err,
      stackTrace: err.stackTrace,
    );
    handler.next(err);
  }

  Map<String, dynamic> _sanitiseHeaders(Map<String, dynamic> headers) {
    // ignore: do_not_use_environment
    const isRelease = bool.fromEnvironment('dart.vm.product');
    if (isRelease) {
      final sanitised = Map<String, dynamic>.from(headers);
      if (sanitised.containsKey('Authorization')) {
        sanitised['Authorization'] = '[REDACTED]';
      }
      return sanitised;
    }
    return headers;
  }
}
