import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/utils/app_logger.dart';

/// Maps FCM notification data payloads to GoRouter deep link paths.
///
/// When a notification is tapped, [handleDeepLink] converts the message
/// data into a GoRouter path and returns it for navigation.
///
/// ── Payload format ────────────────────────────────────────────────────────────
/// The backend should include a 'type' key in the notification data payload:
///   {
///     "type": "medication_reminder",
///     "id": "medication_id",
///     "action": "view"
///   }
class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService _instance = DeepLinkService._();
  static DeepLinkService get instance => _instance;

  // ── Notification Types ─────────────────────────────────────────────────────

  static const String _typeMedicationReminder = 'medication_reminder';
  static const String _typeHealthAlert = 'health_alert';
  static const String _typeWorkoutReminder = 'workout_reminder';
  static const String _typeWeeklyInsight = 'weekly_insight';
  static const String _typeChallengeUpdate = 'challenge_update';
  static const String _typeNutritionLog = 'nutrition_log';
  static const String _typeGoalAchieved = 'goal_achieved';
  static const String _typeAppUpdate = 'app_update';

  // ── Deep Link Routing ──────────────────────────────────────────────────────

  /// Converts a [RemoteMessage] into a GoRouter navigation path.
  ///
  /// Returns null if the message type is unknown or unhandled.
  String? handleDeepLink(RemoteMessage? message) {
    if (message == null) return null;

    final data = message.data;
    final type = data['type'] as String?;

    if (type == null) {
      log.debug('DeepLinkService: no type in notification data');
      return null;
    }

    final route = _mapToRoute(type, data);
    log.info('DeepLinkService: type=$type → route=$route');
    return route;
  }

  String? _mapToRoute(String type, Map<String, dynamic> data) {
    final id = data['id'] as String?;

    return switch (type) {
      _typeMedicationReminder => RouteNames.medication,
      _typeHealthAlert => RouteNames.healthDashboard,
      _typeWorkoutReminder => RouteNames.workouts,
      _typeWeeklyInsight => RouteNames.reportsInsights,
      _typeGoalAchieved => RouteNames.reportsAchievements,
      _typeChallengeUpdate => RouteNames.workouts,
      _typeNutritionLog => RouteNames.nutrition,
      _typeAppUpdate => RouteNames.settings,
      _ => null,
    };
  }

  // ── Notification Data Helpers ──────────────────────────────────────────────

  /// Extracts a notification title from a [RemoteMessage].
  String? extractTitle(RemoteMessage message) =>
      message.notification?.title ?? message.data['title'] as String?;

  /// Extracts a notification body from a [RemoteMessage].
  String? extractBody(RemoteMessage message) =>
      message.notification?.body ?? message.data['body'] as String?;

  /// Extracts a channel ID from the message data (Android notification channel).
  String extractChannelId(RemoteMessage message) =>
      (message.data['channel_id'] as String?) ?? 'general';
}
