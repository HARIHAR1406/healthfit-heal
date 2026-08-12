import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/utils/app_logger.dart';

/// Firebase Cloud Messaging handler — must be a top-level function.
///
/// Registered with [FirebaseMessaging.onBackgroundMessage] so it runs
/// even when the app is terminated. Must NOT access Flutter widgets.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase must be initialized before any Firebase call in background
  // (handled by WorkManager / isolate setup)
  log.info(
    'FCM [background]: '
    'title=${message.notification?.title} '
    'data=${message.data}',
  );
  // TODO: Process background message (e.g. update badge count via WorkManager)
}

/// Firebase Cloud Messaging service for HealthFit Heal.
///
/// Manages:
///   - FCM token lifecycle (obtain, refresh, upload to backend)
///   - Foreground message handling → show local notification
///   - Background/terminated message handling
///   - Topic subscriptions for broadcast push
class FcmService {
  FcmService._();

  static final FcmService _instance = FcmService._();
  static FcmService get instance => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  String? _currentToken;
  String? get currentToken => _currentToken;

  // ── Initialize ─────────────────────────────────────────────────────────────

  /// Initializes FCM and sets up message handlers.
  ///
  /// Call this after Firebase.initializeApp() in main().
  Future<void> initialize({
    required Future<void> Function(RemoteMessage) onForegroundMessage,
    required void Function(RemoteMessage?) onMessageOpenedApp,
  }) async {
    // Register background handler (must be top-level function)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission on Android 13+ / iOS
    await _requestPermission();

    // Get the FCM token
    await _fetchToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_onTokenRefresh);

    // Foreground messages (app is open)
    FirebaseMessaging.onMessage.listen(onForegroundMessage);

    // Notification tapped while app in background (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpenedApp);

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    onMessageOpenedApp(initialMessage);

    log.info('FcmService: initialized (token=$_currentToken)');
  }

  // ── Permission ─────────────────────────────────────────────────────────────

  Future<void> _requestPermission() async {
    if (kIsWeb) return; // Not applicable for web

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    log.info(
      'FcmService: notification permission — '
      '${settings.authorizationStatus.name}',
    );
  }

  // ── Token ──────────────────────────────────────────────────────────────────

  Future<void> _fetchToken() async {
    try {
      _currentToken = await _messaging.getToken();
      log.debug('FcmService: token obtained (${_currentToken?.substring(0, 10)}...)');
    } catch (e) {
      log.error('FcmService: failed to get token', error: e);
    }
  }

  void _onTokenRefresh(String newToken) {
    _currentToken = newToken;
    log.info('FcmService: token refreshed');
    // Token manager will detect this and upload to backend
  }

  /// Returns the current FCM registration token.
  Future<String?> getToken() async {
    _currentToken ??= await _messaging.getToken();
    return _currentToken;
  }

  // ── Topics ────────────────────────────────────────────────────────────────

  /// Subscribes to a FCM topic for broadcast push notifications.
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    log.info('FcmService: subscribed to topic "$topic"');
  }

  /// Unsubscribes from a FCM topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    log.info('FcmService: unsubscribed from topic "$topic"');
  }

  // ── Predefined Topics ─────────────────────────────────────────────────────

  static const String topicHealthAlerts = 'health_alerts';
  static const String topicWorkoutReminders = 'workout_reminders';
  static const String topicMedicationReminders = 'medication_reminders';
  static const String topicWeeklyInsights = 'weekly_insights';
  static const String topicPromotions = 'promotions';

  Future<void> subscribeToHealthTopics() async {
    await Future.wait([
      subscribeToTopic(topicHealthAlerts),
      subscribeToTopic(topicWorkoutReminders),
      subscribeToTopic(topicMedicationReminders),
    ]);
  }
}

