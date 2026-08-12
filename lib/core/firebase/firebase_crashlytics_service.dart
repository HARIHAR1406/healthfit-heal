import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../utils/app_logger.dart';
import '../../../config/env/environment.dart';

/// Firebase Crashlytics service wrapper for HealthFit Heal.
///
/// Provides structured error recording, user attribution, and custom keys.
/// All operations are no-ops in debug mode.
class FirebaseCrashlyticsService {
  FirebaseCrashlyticsService._();

  static final FirebaseCrashlyticsService _instance =
      FirebaseCrashlyticsService._();

  static FirebaseCrashlyticsService get instance => _instance;

  FirebaseCrashlytics get _crashlytics => FirebaseCrashlytics.instance;

  bool get _isActive => Environment.enableCrashReporting && !kDebugMode;

  // ── User Attribution ───────────────────────────────────────────────────────

  /// Sets the user ID for crash attribution.
  Future<void> setUserId(String userId) async {
    if (!_isActive) return;
    await _crashlytics.setUserIdentifier(userId);
  }

  /// Clears the user ID on logout.
  Future<void> clearUserId() async {
    if (!_isActive) return;
    await _crashlytics.setUserIdentifier('');
  }

  // ── Custom Keys ────────────────────────────────────────────────────────────

  /// Sets a custom key-value pair visible in crash reports.
  Future<void> setCustomKey(String key, Object value) async {
    if (!_isActive) return;
    await _crashlytics.setCustomKey(key, value);
  }

  // ── Breadcrumbs ────────────────────────────────────────────────────────────

  /// Adds a log message as a breadcrumb in crash reports.
  void addBreadcrumb(String message) {
    if (!_isActive) return;
    _crashlytics.log(message);
  }

  // ── Error Recording ────────────────────────────────────────────────────────

  /// Records a non-fatal error (e.g. a caught exception that was handled).
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    Iterable<Object> information = const [],
  }) async {
    if (kDebugMode) {
      log.error(
        'Crashlytics[DEBUG]: $error',
        error: error,
        stackTrace: stack,
      );
      return;
    }
    await _crashlytics.recordError(
      error,
      stack,
      reason: reason,
      fatal: fatal,
      information: information,
    );
  }

  /// Records a Flutter framework error.
  Future<void> recordFlutterError(Object error, StackTrace? stack) async {
    if (!_isActive) return;
    await _crashlytics.recordError(error, stack, fatal: false);
  }

  // ── Test ──────────────────────────────────────────────────────────────────

  /// Forces a test crash — for verifying Crashlytics setup.
  /// Call only in development builds.
  void testCrash() {
    if (!kDebugMode) return;
    _crashlytics.crash();
  }
}

