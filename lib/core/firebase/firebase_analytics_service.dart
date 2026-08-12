import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import '../utils/app_logger.dart';
import '../../../config/env/environment.dart';

/// Firebase Analytics service wrapper for HealthFit Heal.
///
/// Provides typed analytics event tracking with environment guards.
/// All calls are no-ops in development mode to avoid polluting analytics data.
class FirebaseAnalyticsService {
  FirebaseAnalyticsService._();

  static final FirebaseAnalyticsService _instance =
      FirebaseAnalyticsService._();

  static FirebaseAnalyticsService get instance => _instance;

  FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  bool get _isActive => Environment.enableAnalytics && !kDebugMode;

  // ── Session ────────────────────────────────────────────────────────────────

  /// Sets the current user ID for analytics segmentation.
  Future<void> setUserId(String? userId) async {
    if (!_isActive) return;
    await _analytics.setUserId(id: userId);
  }

  /// Sets a custom user property (max 25 per app).
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (!_isActive) return;
    await _analytics.setUserProperty(name: name, value: value);
  }

  // ── Screen Tracking ────────────────────────────────────────────────────────

  /// Tracks a screen view event.
  Future<void> trackScreen(String screenName) async {
    if (!_isActive) return;
    await _analytics.logScreenView(screenName: screenName);
    log.trace('Analytics: screen_view → $screenName');
  }

  // ── Auth Events ────────────────────────────────────────────────────────────

  /// Tracks a successful login event.
  Future<void> trackLogin({required String method}) async {
    if (!_isActive) return;
    await _analytics.logLogin(loginMethod: method);
  }

  /// Tracks a successful registration event.
  Future<void> trackSignUp({required String method}) async {
    if (!_isActive) return;
    await _analytics.logSignUp(signUpMethod: method);
  }

  // ── Health Events ──────────────────────────────────────────────────────────

  /// Tracks when a user logs a health metric.
  Future<void> trackHealthMetricLogged({required String metricType}) async {
    if (!_isActive) return;
    await _analytics.logEvent(
      name: 'health_metric_logged',
      parameters: {'metric_type': metricType},
    );
  }

  /// Tracks Health Connect sync completion.
  Future<void> trackHealthConnectSync({
    required int recordsCount,
    required bool success,
  }) async {
    if (!_isActive) return;
    await _analytics.logEvent(
      name: 'health_connect_sync',
      parameters: {
        'records_count': recordsCount,
        'success': success,
      },
    );
  }

  // ── Fitness Events ────────────────────────────────────────────────────────

  /// Tracks workout session completion.
  Future<void> trackWorkoutCompleted({
    required String workoutType,
    required int durationMinutes,
    required int caloriesBurned,
  }) async {
    if (!_isActive) return;
    await _analytics.logEvent(
      name: 'workout_completed',
      parameters: {
        'workout_type': workoutType,
        'duration_minutes': durationMinutes,
        'calories_burned': caloriesBurned,
      },
    );
  }

  // ── Nutrition Events ───────────────────────────────────────────────────────

  /// Tracks a meal log event.
  Future<void> trackMealLogged({
    required String mealType,
    required int calories,
  }) async {
    if (!_isActive) return;
    await _analytics.logEvent(
      name: 'meal_logged',
      parameters: {
        'meal_type': mealType,
        'calories': calories,
      },
    );
  }

  // ── AI Events ─────────────────────────────────────────────────────────────

  /// Tracks AI chat message sent.
  Future<void> trackAiMessageSent({required String provider}) async {
    if (!_isActive) return;
    await _analytics.logEvent(
      name: 'ai_message_sent',
      parameters: {'provider': provider},
    );
  }

  // ── Custom Events ──────────────────────────────────────────────────────────

  /// Generic event tracker for custom events.
  Future<void> trackEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    if (!_isActive) return;
    await _analytics.logEvent(name: name, parameters: parameters);
    log.trace('Analytics: $name → $parameters');
  }

  /// Returns the [FirebaseAnalyticsObserver] for GoRouter integration.
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);
}

