import 'package:dio/dio.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

import '../../../config/env/environment.dart';
import '../../utils/app_logger.dart';

/// Dio interceptor that records HTTP metrics to Firebase Performance Monitoring.
///
/// Each request creates a [HttpMetric] that records:
///   - HTTP method
///   - Request URL
///   - HTTP response code
///   - Response payload size
///
/// Only active when [Environment.enablePerformanceMonitoring] is true
/// and not in debug mode, to avoid polluting metrics with dev data.
class PerformanceInterceptor extends Interceptor {
  PerformanceInterceptor();

  final Map<String, HttpMetric> _activeMetrics = {};

  bool get _isActive =>
      Environment.enablePerformanceMonitoring && !kDebugMode;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isActive) {
      try {
        final method = _parseMethod(options.method);
        if (method != null) {
          final metric = FirebasePerformance.instance.newHttpMetric(
            options.uri.toString(),
            method,
          );
          await metric.start();
          _activeMetrics[options.hashCode.toString()] = metric;
        }
      } catch (e) {
        log.trace('PerformanceInterceptor: failed to start metric', error: e);
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    if (_isActive) {
      await _stopMetric(
        response.requestOptions,
        statusCode: response.statusCode,
        responseSize: _responseSize(response),
      );
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (_isActive) {
      await _stopMetric(
        err.requestOptions,
        statusCode: err.response?.statusCode,
      );
    }
    handler.next(err);
  }

  Future<void> _stopMetric(
    RequestOptions options, {
    int? statusCode,
    int? responseSize,
  }) async {
    final key = options.hashCode.toString();
    final metric = _activeMetrics.remove(key);
    if (metric == null) return;

    try {
      if (statusCode != null) metric.httpResponseCode = statusCode;
      if (responseSize != null) metric.responsePayloadSize = responseSize;
      await metric.stop();
    } catch (e) {
      log.trace('PerformanceInterceptor: failed to stop metric', error: e);
    }
  }

  int? _responseSize(Response<dynamic> response) {
    final contentLength = response.headers.value('content-length');
    if (contentLength != null) return int.tryParse(contentLength);
    final body = response.data;
    if (body is String) return body.length;
    return null;
  }

  HttpMethod? _parseMethod(String method) {
    return switch (method.toUpperCase()) {
      'GET' => HttpMethod.Get,
      'POST' => HttpMethod.Post,
      'PUT' => HttpMethod.Put,
      'PATCH' => HttpMethod.Patch,
      'DELETE' => HttpMethod.Delete,
      'HEAD' => HttpMethod.Head,
      'OPTIONS' => HttpMethod.Options,
      'TRACE' => HttpMethod.Trace,
      'CONNECT' => HttpMethod.Connect,
      _ => null,
    };
  }
}

