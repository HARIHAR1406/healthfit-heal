import 'package:logger/logger.dart';

import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/reminder_entity.dart';

final _log = Logger();

// ══════════════════════════════════════════════════════════════════════════════
// NOTIFICATION SERVICE
// ══════════════════════════════════════════════════════════════════════════════

/// Facade over the platform notification SDK (flutter_local_notifications).
///
/// **Current state:** Architecture-only mock.
/// To activate real notifications:
/// 1. Add `flutter_local_notifications: ^17.x.x` to pubspec.yaml.
/// 2. Configure AndroidManifest.xml (RECEIVE_BOOT_COMPLETED, etc.).
/// 3. Configure iOS Info.plist (NSUserNotificationUsageDescription).
/// 4. Replace the method bodies below with real SDK calls.
///
/// All call sites remain unchanged — swap the impl, not the interface.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  bool _initialized = false;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Call once in [main] after WidgetsFlutterBinding.ensureInitialized().
  Future<void> initialize() async {
    if (_initialized) return;
    _log.i('NotificationService: initializing (mock mode)');

    // TODO(setup): Uncomment when flutter_local_notifications is added.
    // const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    // const iosInit = DarwinInitializationSettings(
    //   requestAlertPermission: true,
    //   requestBadgePermission: true,
    //   requestSoundPermission: true,
    // );
    // const initSettings = InitializationSettings(
    //   android: androidInit,
    //   iOS: iosInit,
    // );
    // await _plugin.initialize(initSettings, onDidReceiveNotificationResponse: _onTap);

    _initialized = true;
    _log.i('NotificationService: initialized');
  }

  /// Request OS notification permissions (Android 13+ / iOS).
  Future<bool> requestPermission() async {
    _log.i('NotificationService: requestPermission (mock → true)');
    // TODO(setup): return await _plugin.resolvePlatformSpecificImplementation<
    //     AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission() ?? false;
    return true;
  }

  // ── Show ──────────────────────────────────────────────────────────────────

  /// Show an immediate notification.
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationCategory category = NotificationCategory.system,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    _log.i('NotificationService.show [$id] "$title"');
    // TODO(setup):
    // await _plugin.show(
    //   id,
    //   title,
    //   body,
    //   NotificationDetails(
    //     android: AndroidNotificationDetails(
    //       category.name,
    //       category.label,
    //       importance: _mapPriority(priority),
    //       priority: Priority.high,
    //       color: category.color,
    //     ),
    //     iOS: const DarwinNotificationDetails(presentSound: true),
    //   ),
    //   payload: payload,
    // );
  }

  // ── Schedule ──────────────────────────────────────────────────────────────

  /// Schedule a one-shot notification at [scheduledAt].
  Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    String? payload,
    NotificationCategory category = NotificationCategory.system,
  }) async {
    _log.i('NotificationService.scheduleOnce [$id] at $scheduledAt');
    // TODO(setup): await _plugin.zonedSchedule(...)
  }

  /// Schedule a daily repeating notification at [hour]:[minute].
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
    NotificationCategory category = NotificationCategory.system,
  }) async {
    _log.i('NotificationService.scheduleDaily [$id] at $hour:$minute');
    // TODO(setup): await _plugin.periodicallyShow / zonedSchedule with DateTimeComponents.time
  }

  /// Schedule a weekly notification on [weekday] (1=Mon … 7=Sun).
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
    _log.i('NotificationService.scheduleWeekly [$id] weekday=$weekday $hour:$minute');
    // TODO(setup): zonedSchedule with DateTimeComponents.dayOfWeekAndTime
  }

  // ── Cancel ────────────────────────────────────────────────────────────────

  Future<void> cancel(int id) async {
    _log.i('NotificationService.cancel [$id]');
    // TODO(setup): await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    _log.i('NotificationService.cancelAll');
    // TODO(setup): await _plugin.cancelAll();
  }

  // ── Badge ─────────────────────────────────────────────────────────────────

  Future<void> setBadge(int count) async {
    _log.d('NotificationService.setBadge [$count]');
    // TODO(setup): platform channel or flutter_app_badger package
  }

  Future<void> clearBadge() => setBadge(0);

  // ── Tap handler ───────────────────────────────────────────────────────────

  /// Called when user taps a notification.
  /// [payload] is the GoRouter route to navigate to.
  void _onTap(dynamic response) {
    _log.i('NotificationService._onTap payload=${response?.payload}');
    // TODO(setup): router.push(response.payload)
  }
}
