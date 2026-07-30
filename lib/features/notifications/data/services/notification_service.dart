import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/reminder_entity.dart';

/// Production notification service using [flutter_local_notifications].
///
/// Handles:
///   - Immediate notifications (FCM foreground display)
///   - Scheduled one-shot notifications
///   - Daily repeating notifications (medication reminders)
///   - Weekly repeating notifications
///   - Notification channel management (Android 8+)
///   - Notification tap → GoRouter navigation via payload
///
/// ── Required AndroidManifest.xml entries ────────────────────────────────────
///   <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
///   <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
///   <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
///   <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" ... />
///
/// ── Notification Channels ────────────────────────────────────────────────────
///   medication    — Medication reminders (high importance)
///   workout       — Workout reminders (default importance)
///   health_alert  — Health alerts (urgent, heads-up)
///   weekly_report — Weekly insights (low importance)
///   general       — System/general notifications
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Navigation callback — injected by router after initialization.
  void Function(String? payload)? _onNotificationTap;

  // ── Channel Definitions ────────────────────────────────────────────────────

  static const _channelMedication = AndroidNotificationChannel(
    'medication',
    'Medication Reminders',
    description: 'Reminders to take your medications on time.',
    importance: Importance.high,
    enableVibration: true,
    playSound: true,
  );

  static const _channelWorkout = AndroidNotificationChannel(
    'workout',
    'Workout Reminders',
    description: 'Your daily workout schedule reminders.',
    importance: Importance.defaultImportance,
    enableVibration: false,
    playSound: true,
  );

  static const _channelHealthAlert = AndroidNotificationChannel(
    'health_alert',
    'Health Alerts',
    description: 'Critical health metric alerts from your wearable.',
    importance: Importance.max,
    enableVibration: true,
    playSound: true,
  );

  static const _channelWeeklyReport = AndroidNotificationChannel(
    'weekly_report',
    'Weekly Insights',
    description: 'Your weekly health and fitness summary.',
    importance: Importance.low,
    enableVibration: false,
    playSound: false,
  );

  static const _channelGeneral = AndroidNotificationChannel(
    'general',
    'General Notifications',
    description: 'General app notifications and updates.',
    importance: Importance.defaultImportance,
    enableVibration: false,
    playSound: true,
  );

  // ── Initialize ─────────────────────────────────────────────────────────────

  /// Initializes the notification plugin and creates Android channels.
  ///
  /// [onTap] — called when user taps a notification. The payload is
  ///           the GoRouter path to navigate to.
  Future<void> initialize({
    void Function(String? payload)? onTap,
  }) async {
    if (_initialized) return;
    _onNotificationTap = onTap;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        log.info(
          'NotificationService: tapped — payload=${response.payload}',
        );
        _onNotificationTap?.call(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: _backgroundNotificationHandler,
    );

    // Create Android notification channels
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await Future.wait([
        androidPlugin.createNotificationChannel(_channelMedication),
        androidPlugin.createNotificationChannel(_channelWorkout),
        androidPlugin.createNotificationChannel(_channelHealthAlert),
        androidPlugin.createNotificationChannel(_channelWeeklyReport),
        androidPlugin.createNotificationChannel(_channelGeneral),
      ]);
      log.info('NotificationService: Android channels created');
    }

    _initialized = true;
    log.info('NotificationService: initialized');
  }

  // ── Permissions ────────────────────────────────────────────────────────────

  /// Requests notification permission (Android 13+ / POST_NOTIFICATIONS).
  /// Returns true if granted.
  Future<bool> requestPermission() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final granted =
          await androidPlugin.requestNotificationsPermission() ?? false;
      log.info('NotificationService: permission granted=$granted');
      return granted;
    }
    return true;
  }

  // ── Show Immediate ─────────────────────────────────────────────────────────

  /// Shows an immediate local notification.
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationCategory category = NotificationCategory.system,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId(category),
          _channelName(category),
          importance: _mapPriority(priority),
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: _channelColor(category),
          enableVibration: priority != NotificationPriority.low,
        ),
      ),
      payload: payload,
    );
    log.debug('NotificationService.show [$id] "$title"');
  }

  // ── Schedule One-Shot ──────────────────────────────────────────────────────

  /// Schedules a notification at [scheduledAt].
  Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    String? payload,
    NotificationCategory category = NotificationCategory.system,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      TZDateTime.from(scheduledAt, local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId(category),
          _channelName(category),
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: _channelColor(category),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
    log.debug(
      'NotificationService.scheduleOnce [$id] at ${scheduledAt.toIso8601String()}',
    );
  }

  // ── Schedule Daily ─────────────────────────────────────────────────────────

  /// Schedules a daily repeating notification at [hour]:[minute].
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
    NotificationCategory category = NotificationCategory.system,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId(category),
          _channelName(category),
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
    log.debug('NotificationService.scheduleDaily [$id] at $hour:$minute');
  }

  // ── Schedule Weekly ────────────────────────────────────────────────────────

  /// Schedules a weekly notification on [weekday] (1=Mon … 7=Sun).
  Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required int hour,
    required int minute,
    String? payload,
    NotificationCategory category = NotificationCategory.system,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfDayAndTime(weekday, hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId(category),
          _channelName(category),
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: payload,
    );
    log.debug(
      'NotificationService.scheduleWeekly [$id] weekday=$weekday $hour:$minute',
    );
  }

  // ── Cancel ────────────────────────────────────────────────────────────────

  /// Cancels a specific notification by ID.
  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
    log.debug('NotificationService.cancel [$id]');
  }

  /// Cancels all pending notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    log.info('NotificationService: all notifications cancelled');
  }

  // ── Badge ─────────────────────────────────────────────────────────────────

  /// Sets the app badge count (Android — requires plugin support).
  Future<void> setBadge(int count) async {
    log.debug('NotificationService.setBadge [$count]');
    // Badge support requires flutter_app_badger or similar.
    // Left as a no-op — implement per-device if required.
  }

  Future<void> clearBadge() => setBadge(0);

  // ── Helpers ────────────────────────────────────────────────────────────────

  TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = TZDateTime.now(local);
    var scheduled = TZDateTime(local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  TZDateTime _nextInstanceOfDayAndTime(int weekday, int hour, int minute) {
    var scheduled = _nextInstanceOfTime(hour, minute);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  String _channelId(NotificationCategory category) => switch (category) {
        NotificationCategory.medication => 'medication',
        NotificationCategory.health => 'health_alert',
        NotificationCategory.fitness => 'workout',
        NotificationCategory.nutrition => 'general',
        NotificationCategory.system => 'general',
        NotificationCategory.reminder => 'general',
        _ => 'general',
      };

  String _channelName(NotificationCategory category) => switch (category) {
        NotificationCategory.medication => 'Medication Reminders',
        NotificationCategory.health => 'Health Alerts',
        NotificationCategory.fitness => 'Workout Reminders',
        _ => 'General Notifications',
      };

  Importance _mapPriority(NotificationPriority priority) => switch (priority) {
        NotificationPriority.high => Importance.high,
        NotificationPriority.normal => Importance.defaultImportance,
        NotificationPriority.low => Importance.low,
        _ => Importance.defaultImportance,
      };

  // ignore: undefined_prefixed_name
  dynamic _channelColor(NotificationCategory category) {
    // Return null to use the app's default icon color
    return null;
  }
}

/// Background notification response handler (must be top-level).
@pragma('vm:entry-point')
void _backgroundNotificationHandler(NotificationResponse response) {
  // Background tap handling — navigation handled when app opens
  log.info(
    'NotificationService: background tap — payload=${response.payload}',
  );
}

// ── Riverpod Provider ──────────────────────────────────────────────────────────

final notificationServiceProvider = Provider<NotificationService>(
  (_) => NotificationService.instance,
  name: 'notificationServiceProvider',
);
