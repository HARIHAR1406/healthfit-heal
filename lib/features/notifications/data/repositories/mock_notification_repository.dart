import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';

// ══════════════════════════════════════════════════════════════════════════════
// MOCK NOTIFICATION REPOSITORY
// ══════════════════════════════════════════════════════════════════════════════

/// In-memory notification store with 20+ realistic seed entries.
///
/// Replace with a Hive-backed or REST-backed implementation when ready.
class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository() {
    _notifications = List.from(_seed());
  }

  late List<NotificationEntity> _notifications;
  NotificationSettings _settings = const NotificationSettings();

  // ── Read ──────────────────────────────────────────────────────────────────

  @override
  Future<List<NotificationEntity>> getAll() async {
    await _delay();
    _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(_notifications);
  }

  @override
  Future<int> getUnreadCount() async {
    return _notifications.where((n) => !n.isRead).length;
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  @override
  Future<NotificationEntity> add(NotificationEntity notification) async {
    _notifications.insert(0, notification);
    return notification;
  }

  @override
  Future<NotificationEntity> markRead(String id) async {
    await _delay(ms: 100);
    final i = _indexOf(id);
    if (i == -1) throw StateError('Notification $id not found');
    final updated = _notifications[i].copyWith(isRead: true);
    _notifications[i] = updated;
    return updated;
  }

  @override
  Future<void> markAllRead() async {
    await _delay(ms: 150);
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
  }

  @override
  Future<bool> delete(String id) async {
    await _delay(ms: 100);
    final before = _notifications.length;
    _notifications.removeWhere((n) => n.id == id);
    return _notifications.length < before;
  }

  @override
  Future<void> deleteMany(List<String> ids) async {
    await _delay(ms: 150);
    _notifications.removeWhere((n) => ids.contains(n.id));
  }

  @override
  Future<void> clearAll() async {
    await _delay(ms: 200);
    _notifications.clear();
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  @override
  Future<NotificationSettings> getSettings() async => _settings;

  @override
  Future<void> saveSettings(NotificationSettings settings) async {
    _settings = settings;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  int _indexOf(String id) => _notifications.indexWhere((n) => n.id == id);

  Future<void> _delay({int ms = 400}) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  // ── Seed Data ─────────────────────────────────────────────────────────────

  List<NotificationEntity> _seed() {
    final now = DateTime.now();
    return [
      NotificationEntity(
        id: 'notif_001',
        title: '💊 Medication Reminder',
        body: 'Time to take your Vitamin D3 (1000 IU)',
        category: NotificationCategory.medication,
        priority: NotificationPriority.high,
        createdAt: now.subtract(const Duration(minutes: 5)),
        isRead: false,
        actionRoute: '/medication',
        actionLabel: 'View Medications',
      ),
      NotificationEntity(
        id: 'notif_002',
        title: '🏃 Workout Reminder',
        body: 'Your morning run is scheduled in 30 minutes. Ready to go?',
        category: NotificationCategory.fitness,
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(minutes: 30)),
        isRead: false,
        actionRoute: '/workouts',
        actionLabel: 'Start Workout',
      ),
      NotificationEntity(
        id: 'notif_003',
        title: '💧 Hydration Alert',
        body: 'You\'ve only had 600ml today. Drink 2 glasses now to stay on track!',
        category: NotificationCategory.health,
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(hours: 1)),
        isRead: false,
        actionRoute: '/nutrition/water',
        actionLabel: 'Log Water',
      ),
      NotificationEntity(
        id: 'notif_004',
        title: '🤖 AI Insight Ready',
        body: 'Your weekly health analysis is complete. Resting HR improved by 4 bpm!',
        category: NotificationCategory.aiCoach,
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(hours: 2)),
        isRead: false,
        actionRoute: '/ai/insights',
        actionLabel: 'View Insights',
      ),
      NotificationEntity(
        id: 'notif_005',
        title: '🏆 Achievement Unlocked!',
        body: '7-Day Workout Streak! You\'ve worked out 7 days in a row. Amazing!',
        category: NotificationCategory.achievement,
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(hours: 3)),
        isRead: true,
        actionRoute: '/workouts/achievements',
        actionLabel: 'View Achievement',
      ),
      NotificationEntity(
        id: 'notif_006',
        title: '🍽️ Meal Reminder',
        body: 'Lunch time! Don\'t forget to log your meal to stay on track.',
        category: NotificationCategory.nutrition,
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(hours: 4)),
        isRead: true,
        actionRoute: '/nutrition',
        actionLabel: 'Log Meal',
      ),
      NotificationEntity(
        id: 'notif_007',
        title: '❤️ Heart Rate Alert',
        body: 'Resting HR of 92 bpm detected. This is slightly above your normal range.',
        category: NotificationCategory.health,
        priority: NotificationPriority.high,
        createdAt: now.subtract(const Duration(hours: 5)),
        isRead: true,
        actionRoute: '/health/heart-rate',
        actionLabel: 'Check Heart Rate',
      ),
      NotificationEntity(
        id: 'notif_008',
        title: '📊 Weekly Report Ready',
        body: 'Your health report for last week is now available. Overall score: 82/100.',
        category: NotificationCategory.system,
        priority: NotificationPriority.low,
        createdAt: now.subtract(const Duration(hours: 6)),
        isRead: true,
        actionRoute: '/reports',
        actionLabel: 'View Report',
      ),
      NotificationEntity(
        id: 'notif_009',
        title: '💊 Omega-3 Reminder',
        body: 'Evening dose of Omega-3 Fish Oil (1000mg) is due.',
        category: NotificationCategory.medication,
        priority: NotificationPriority.high,
        createdAt: now.subtract(const Duration(hours: 8)),
        isRead: true,
        actionRoute: '/medication',
      ),
      NotificationEntity(
        id: 'notif_010',
        title: '🏆 New Personal Best!',
        body: 'You walked 12,500 steps today — your new record! Keep it up!',
        category: NotificationCategory.achievement,
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(hours: 10)),
        isRead: true,
        actionRoute: '/workouts/achievements',
      ),
      NotificationEntity(
        id: 'notif_011',
        title: '🩸 Blood Sugar Check',
        body: 'It\'s been 4 hours since your last blood sugar reading.',
        category: NotificationCategory.health,
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(hours: 12)),
        isRead: true,
        actionRoute: '/health/blood-sugar',
      ),
      NotificationEntity(
        id: 'notif_012',
        title: '🤖 Smart Tip',
        body: 'Drink water before meals to reduce calorie intake by up to 13%.',
        category: NotificationCategory.aiCoach,
        priority: NotificationPriority.low,
        createdAt: now.subtract(const Duration(hours: 14)),
        isRead: true,
        actionRoute: '/ai/coach',
      ),
      NotificationEntity(
        id: 'notif_013',
        title: '😴 Sleep Reminder',
        body: 'It\'s 10:30 PM. Time to wind down for your 8-hour sleep goal.',
        category: NotificationCategory.health,
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(hours: 16)),
        isRead: true,
      ),
      NotificationEntity(
        id: 'notif_014',
        title: '⚖️ Weekly Weight Check',
        body: 'Log your weight for this week\'s progress report.',
        category: NotificationCategory.health,
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: true,
        actionRoute: '/nutrition/weight',
      ),
      NotificationEntity(
        id: 'notif_015',
        title: '🔔 Workout Streak at Risk!',
        body: 'You haven\'t logged a workout today. Complete one to keep your 6-day streak!',
        category: NotificationCategory.fitness,
        priority: NotificationPriority.high,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        isRead: true,
        actionRoute: '/workouts',
      ),
      NotificationEntity(
        id: 'notif_016',
        title: '💊 Magnesium Dose Due',
        body: 'Your evening Magnesium Glycinate (400mg) is scheduled for 9:00 PM.',
        category: NotificationCategory.medication,
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(days: 1, hours: 4)),
        isRead: true,
        actionRoute: '/medication',
      ),
      NotificationEntity(
        id: 'notif_017',
        title: '📈 BP Reading Reminder',
        body: 'Morning blood pressure check due. Readings are most accurate in the morning.',
        category: NotificationCategory.health,
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(days: 2)),
        isRead: true,
        actionRoute: '/health/blood-pressure',
      ),
      NotificationEntity(
        id: 'notif_018',
        title: '🥗 Nutrition Goal Achieved!',
        body: 'You hit your calorie target of 2,000 kcal for 3 days in a row!',
        category: NotificationCategory.achievement,
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(days: 2, hours: 3)),
        isRead: true,
        actionRoute: '/workouts/achievements',
      ),
      NotificationEntity(
        id: 'notif_019',
        title: '🔄 App Updated',
        body: 'HealthFit Heal v1.1 is now available with new AI features.',
        category: NotificationCategory.system,
        priority: NotificationPriority.low,
        createdAt: now.subtract(const Duration(days: 3)),
        isRead: true,
      ),
      NotificationEntity(
        id: 'notif_020',
        title: '🤖 AI Coach Recommendation',
        body: 'Based on your sleep data, try a 10-min meditation before bed.',
        category: NotificationCategory.aiCoach,
        priority: NotificationPriority.low,
        createdAt: now.subtract(const Duration(days: 3, hours: 6)),
        isRead: true,
        actionRoute: '/ai/coach',
      ),
    ];
  }
}

