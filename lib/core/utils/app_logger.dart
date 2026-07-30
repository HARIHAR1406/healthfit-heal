import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../../config/env/environment.dart';

/// Production-safe application logger for HealthFit Heal.
///
/// ── Features ─────────────────────────────────────────────────────────────────
///   • PII/secret scrubbing — strips known sensitive key patterns from messages
///   • Environment-aware levels — trace+debug in dev, warning+ in production
///   • Crashlytics routing — errors/fatals recorded to Firebase Crashlytics
///     when in non-debug mode (Crashlytics import is lazy to avoid coupling)
///
/// ── Crashlytics integration ───────────────────────────────────────────────────
///   Enabled automatically when [Environment.enableCrashReporting] is true.
///   Crashlytics must be initialized before any error is logged (done in
///   FirebaseConfig.init → main.dart).
///
/// ── Usage ────────────────────────────────────────────────────────────────────
///   log.info('User logged in', error: null);
///   log.error('Sync failed', error: exception, stackTrace: st);
class AppLogger {
  AppLogger._();

  static final AppLogger _instance = AppLogger._();

  /// The singleton [AppLogger] instance.
  static AppLogger get instance => _instance;

  // ── Regex for PII / secrets in log messages ──────────────────────────────

  static final _piiPatterns = [
    // JWT tokens (Bearer eyJhbGc…)
    RegExp(r'Bearer\s+[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+'),
    // Email addresses
    RegExp(r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}'),
    // API keys (AIza… for Google, sk-… for OpenAI)
    RegExp(r'\bAIza[0-9A-Za-z\-_]{35}\b'),
    RegExp(r'\bsk-[A-Za-z0-9]{20,}\b'),
    // Phone numbers (loose pattern)
    RegExp(r'\+?[0-9]{10,15}'),
    // Full name patterns in JSON
    RegExp(r'"(name|full_name|displayName)"\s*:\s*"[^"]*"'),
    // Password fields in JSON
    RegExp(r'"(password|secret|token|access_token|refresh_token)"\s*:\s*"[^"]*"'),
  ];

  late final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 10,
      lineLength: 80,
      colors: !kReleaseMode,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: _resolveLevel(),
    output: MultiOutput([ConsoleOutput()]),
    filter: ProductionFilter(),
  );

  static Level _resolveLevel() {
    if (kReleaseMode) return Level.warning;
    if (kProfileMode) return Level.info;
    return Level.trace; // debug mode → everything
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Logs a trace message (verbose debugging). Never logged in production.
  void trace(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _logger.t(_scrub(message), error: error, stackTrace: stackTrace);

  /// Logs a debug message. Not logged in production.
  void debug(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _logger.d(_scrub(message), error: error, stackTrace: stackTrace);

  /// Logs an informational message.
  void info(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _logger.i(_scrub(message), error: error, stackTrace: stackTrace);

  /// Logs a warning. Logged in all environments.
  void warning(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.w(_scrub(message), error: error, stackTrace: stackTrace);
    // Route warnings to Crashlytics breadcrumbs (non-fatal)
    _recordToCrashlytics(message, error, stackTrace, fatal: false);
  }

  /// Logs an error. Logged in all environments + sent to Crashlytics.
  void error(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.e(_scrub(message), error: error, stackTrace: stackTrace);
    _recordToCrashlytics(message, error, stackTrace, fatal: false);
  }

  /// Logs a fatal/critical error. Always logged + sent to Crashlytics as fatal.
  void fatal(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.f(_scrub(message), error: error, stackTrace: stackTrace);
    _recordToCrashlytics(message, error, stackTrace, fatal: true);
  }

  // ── PII Scrubbing ──────────────────────────────────────────────────────────

  dynamic _scrub(dynamic message) {
    if (kDebugMode) return message; // No scrubbing in debug mode
    if (message is! String) return message;
    var scrubbed = message;
    for (final pattern in _piiPatterns) {
      scrubbed = scrubbed.replaceAll(pattern, '[REDACTED]');
    }
    return scrubbed;
  }

  // ── Crashlytics Integration ────────────────────────────────────────────────

  void _recordToCrashlytics(
    dynamic message,
    Object? error,
    StackTrace? stackTrace, {
    required bool fatal,
  }) {
    if (kDebugMode || !Environment.enableCrashReporting) return;

    // Lazy Crashlytics access — avoids hard dependency when Firebase not enabled
    try {
      // Dynamic access pattern prevents import cycle with firebase_config
      // CrashlyticsService.instance.recordError(error, stackTrace, fatal: fatal)
      // This is wired in InjectionContainer via a callback pattern
      _crashlyticsCallback?.call(error, stackTrace, fatal: fatal);
    } catch (_) {
      // Crashlytics recording must never crash the app
    }
  }

  // ── Crashlytics Callback (injected by DI container) ───────────────────────

  void Function(Object? error, StackTrace? stackTrace, {required bool fatal})?
      _crashlyticsCallback;

  /// Registers the Crashlytics error recording callback.
  ///
  /// Called by [InjectionContainer] after Firebase is initialized.
  void setCrashlyticsCallback(
    void Function(Object? error, StackTrace? stackTrace, {required bool fatal})
        callback,
  ) {
    _crashlyticsCallback = callback;
    log.info('AppLogger: Crashlytics callback registered');
  }
}

/// Convenience top-level logger instance.
final log = AppLogger.instance;
