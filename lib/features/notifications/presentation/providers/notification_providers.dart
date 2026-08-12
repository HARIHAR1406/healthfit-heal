import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/mock_notification_repository.dart';
import '../../data/repositories/mock_reminder_repository.dart';
import '../../data/services/background_service.dart';
import '../../data/services/notification_service.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/reminder_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/repositories/reminder_repository.dart';
import 'notification_notifier.dart';
import 'notification_state.dart';
import 'reminder_notifier.dart';
import 'reminder_state.dart';

// ══════════════════════════════════════════════════════════════════════════════
// REPOSITORY PROVIDERS
// ══════════════════════════════════════════════════════════════════════════════

final notificationRepositoryProvider = Provider<NotificationRepository>((_) {
  return MockNotificationRepository();
});

final reminderRepositoryProvider = Provider<ReminderRepository>((_) {
  return MockReminderRepository();
});

// ══════════════════════════════════════════════════════════════════════════════
// SERVICE PROVIDERS
// ══════════════════════════════════════════════════════════════════════════════

final notificationServiceProvider = Provider<NotificationService>((_) {
  return NotificationService.instance;
});

final backgroundServiceProvider = Provider<BackgroundService>((_) {
  return BackgroundService.instance;
});

// ══════════════════════════════════════════════════════════════════════════════
// NOTIFIER PROVIDERS
// ══════════════════════════════════════════════════════════════════════════════

final notificationNotifierProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref.watch(notificationRepositoryProvider));
});

final reminderNotifierProvider =
    StateNotifierProvider<ReminderNotifier, ReminderState>((ref) {
  return ReminderNotifier(ref.watch(reminderRepositoryProvider));
});

final reminderHistoryNotifierProvider =
    StateNotifierProvider<ReminderHistoryNotifier, ReminderHistoryState>((ref) {
  return ReminderHistoryNotifier(ref.watch(reminderRepositoryProvider));
});

// ══════════════════════════════════════════════════════════════════════════════
// DERIVED / SELECTOR PROVIDERS
// ══════════════════════════════════════════════════════════════════════════════

/// Unread notification count for badge display. Lightweight — no full list load.
final unreadNotificationCountProvider = Provider<int>((ref) {
  final state = ref.watch(notificationNotifierProvider);
  return state is NotificationLoaded ? state.unreadCount : 0;
});

/// Whether there are any unread notifications.
final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  return ref.watch(unreadNotificationCountProvider) > 0;
});

/// Filtered/searched notification list for the center page.
final filteredNotificationsProvider = Provider<List<NotificationEntity>>((ref) {
  final state = ref.watch(notificationNotifierProvider);
  return state is NotificationLoaded ? state.filtered : [];
});

/// All notification categories with their unread counts.
final categoryUnreadCountsProvider =
    Provider<Map<NotificationCategory, int>>((ref) {
  final state = ref.watch(notificationNotifierProvider);
  if (state is! NotificationLoaded) return {};
  final counts = <NotificationCategory, int>{};
  for (final n in state.all.where((n) => !n.isRead)) {
    counts[n.category] = (counts[n.category] ?? 0) + 1;
  }
  return counts;
});

/// Active reminders only.
final activeRemindersProvider = Provider<List<ReminderEntity>>((ref) {
  final state = ref.watch(reminderNotifierProvider);
  if (state is! ReminderLoaded) return [];
  return state.reminders.where((r) => r.isEnabled).toList();
});

/// Reminders grouped by type for the manager page.
final remindersByTypeProvider =
    Provider<Map<ReminderType, ReminderEntity?>>((ref) {
  final state = ref.watch(reminderNotifierProvider);
  if (state is! ReminderLoaded) return {};
  final map = <ReminderType, ReminderEntity?>{};
  for (final type in ReminderType.values) {
    try {
      map[type] = state.reminders.firstWhere((r) => r.type == type);
    } catch (_) {
      map[type] = null;
    }
  }
  return map;
});

/// Current notification settings from loaded state.
final notificationSettingsProvider = Provider<NotificationSettings>((ref) {
  final state = ref.watch(notificationNotifierProvider);
  if (state is NotificationLoaded) return state.settings;
  return const NotificationSettings();
});

/// Reminder statistics from the history notifier.
final reminderStatisticsProvider = Provider<ReminderStatistics?>((ref) {
  final state = ref.watch(reminderHistoryNotifierProvider);
  return state is ReminderHistoryLoaded ? state.statistics : null;
});

/// Background task provider — exposes the service for manual dispatch.
final backgroundTaskProvider = Provider<BackgroundService>((_) {
  return BackgroundService.instance;
});

