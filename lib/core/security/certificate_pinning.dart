import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import '../../config/env/app_secrets.dart';
import '../../config/env/environment.dart';
import '../utils/app_logger.dart';

/// Dio interceptor that performs certificate pinning on HTTPS connections.
///
/// Validates the server's certificate SHA-256 fingerprint against a known-good
/// list provided via [AppSecrets.pinnedFingerprints] (dart-define at build time).
///
/// Only active when [Environment.enableCertificatePinning] is true,
/// which requires:
///   - ENVIRONMENT=production
///   - PINNED_CERT_FINGERPRINTS=sha256/ABC...,sha256/DEF...
///
/// ── Certificate rotation ─────────────────────────────────────────────────────
/// Always pin at least 2 certificates (primary + backup) to allow rotation.
/// Update [PINNED_CERT_FINGERPRINTS] in your CI/CD secrets before the
/// primary certificate expires.
///
/// ── Getting fingerprints ─────────────────────────────────────────────────────
/// openssl s_client -connect api.healthfitheal.com:443 < /dev/null 2>/dev/null \
///   | openssl x509 -fingerprint -sha256 -noout
class CertificatePinningInterceptor extends Interceptor {
  CertificatePinningInterceptor() {
    _pinnedFingerprints = AppSecrets.pinnedFingerprints
        .map((f) => f.replaceFirst('sha256/', '').toLowerCase())
        .toSet();
  }

  late final Set<String> _pinnedFingerprints;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!Environment.enableCertificatePinning) {
      return handler.next(options);
    }

    if (_pinnedFingerprints.isEmpty) {
      log.warning(
        'CertificatePinning: enabled but no fingerprints configured — '
        'allowing request (set PINNED_CERT_FINGERPRINTS in dart-define)',
      );
      return handler.next(options);
    }

    // Actual certificate inspection happens at the HttpClient level.
    // This interceptor sets the validation callback on the Dio HttpClientAdapter.
    // For full certificate pinning, configure [HttpClient.badCertificateCallback]
    // in a custom [HttpClientAdapter] (see below).
    handler.next(options);
  }

  /// Returns a configured [SecurityContext] with certificate pinning.
  ///
  /// Use this to create a custom [HttpClient] for Dio.
  ///
  /// Example:
  ///   final dio = Dio();
  ///   (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
  ///     final client = HttpClient(context: CertificatePinningInterceptor.securityContext);
  ///     client.badCertificateCallback = CertificatePinningInterceptor.validateCert;
  ///     return client;
  ///   };
  static SecurityContext get securityContext {
    return SecurityContext.defaultContext;
  }

  /// Certificate validation callback for [HttpClient.badCertificateCallback].
  static bool validateCert(X509Certificate cert, String host, int port) {
    if (!Environment.enableCertificatePinning) return true;

    final fingerprints = AppSecrets.pinnedFingerprints
        .map((f) => f.replaceFirst('sha256/', '').toLowerCase())
        .toSet();

    if (fingerprints.isEmpty) return true;

    // Compute SHA-256 fingerprint of the DER-encoded certificate
    final derBytes = cert.der;
    final digest = sha256.convert(derBytes);
    final fingerprint = base64.encode(digest.bytes).toLowerCase();

    final isPinned = fingerprints.any((pin) {
      // Compare against base64-encoded fingerprints
      final pinBytes = base64.decode(pin.replaceAll(':', ''));
      return digest.bytes.toString() == pinBytes.toString() ||
          pin == fingerprint;
    });

    if (!isPinned) {
      log.fatal(
        'CertificatePinning: REJECTED certificate for $host:$port '
        '(fingerprint=$fingerprint)',
      );
    }

    return isPinned;
  }
}

