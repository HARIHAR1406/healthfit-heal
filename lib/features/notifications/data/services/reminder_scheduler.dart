import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/reminder_entity.dart';
import 'notification_service.dart';

final _log = Logger();

// ══════════════════════════════════════════════════════════════════════════════
// REMINDER SCHEDULER
// ══════════════════════════════════════════════════════════════════════════════

/// Translates [ReminderEntity] objects into platform notification schedules.
///
/// **Stable ID strategy**: notification id = hash of reminderId (32-bit).
/// This ensures cancel / reschedule is idempotent.
class ReminderScheduler {
  ReminderScheduler._();
  static final ReminderScheduler instance = ReminderScheduler._();

  final _svc = NotificationService.instance;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Schedule (or reschedule) all alarms for [reminder].
  Future<void> schedule(ReminderEntity reminder) async {
    if (!reminder.isEnabled) {
      await cancel(reminder);
      return;
    }

    _log.i('ReminderScheduler.schedule [${reminder.id}] '
        '${reminder.type.label} at ${reminder.timeLabel}');

    switch (reminder.repeatSchedule) {
      case RepeatSchedule.once:
        await _scheduleOnce(reminder);
      case RepeatSchedule.daily:
        await _scheduleDaily(reminder);
      case RepeatSchedule.weekdays:
        await _scheduleWeekdays(reminder);
      case RepeatSchedule.weekends:
        await _scheduleWeekends(reminder);
      case RepeatSchedule.custom:
        await _scheduleCustomDays(reminder);
    }
  }

  /// Cancel all alarms for [reminder].
  Future<void> cancel(ReminderEntity reminder) async {
    _log.i('ReminderScheduler.cancel [${reminder.id}]');
    // Cancel up to 7 slots (one per weekday)
    for (var i = 0; i < 7; i++) {
      final id = _notifId(reminder.id, slot: i);
      await _svc.cancel(id);
    }
  }

  /// Cancel and reschedule (used after time/day edits).
  Future<void> reschedule(ReminderEntity reminder) async {
    await cancel(reminder);
    await schedule(reminder);
  }

  /// Snooze: cancel current alarm, schedule one-shot [minutes] from now.
  Future<void> snooze(ReminderEntity reminder, {int minutes = 10}) async {
    await cancel(reminder);
    final at = DateTime.now().add(Duration(minutes: minutes));
    final id = _notifId(reminder.id);
    await _svc.scheduleOnce(
      id: id,
      title: '🔔 ${reminder.title}',
      body: reminder.body,
      scheduledAt: at,
      category: _mapCategory(reminder.type),
    );
    _log.i('ReminderScheduler.snooze [${reminder.id}] until $at');
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _scheduleOnce(ReminderEntity r) async {
    final now = DateTime.now();
    var at = DateTime(
        now.year, now.month, now.day, r.scheduledTime.hour, r.scheduledTime.minute);
    if (at.isBefore(now)) at = at.add(const Duration(days: 1));

    await _svc.scheduleOnce(
      id: _notifId(r.id),
      title: r.title,
      body: r.body,
      scheduledAt: at,
      category: _mapCategory(r.type),
    );
  }

  Future<void> _scheduleDaily(ReminderEntity r) async {
    await _svc.scheduleDaily(
      id: _notifId(r.id),
      title: r.title,
      body: r.body,
      hour: r.scheduledTime.hour,
      minute: r.scheduledTime.minute,
      category: _mapCategory(r.type),
    );
  }

  Future<void> _scheduleWeekdays(ReminderEntity r) async {
    for (var day = 1; day <= 5; day++) {
      // Monday=1 … Friday=5
      await _svc.scheduleWeekly(
        id: _notifId(r.id, slot: day),
        title: r.title,
        body: r.body,
        weekday: day,
        hour: r.scheduledTime.hour,
        minute: r.scheduledTime.minute,
        category: _mapCategory(r.type),
      );
    }
  }

  Future<void> _scheduleWeekends(ReminderEntity r) async {
    for (final day in [6, 7]) {
      await _svc.scheduleWeekly(
        id: _notifId(r.id, slot: day),
        title: r.title,
        body: r.body,
        weekday: day,
        hour: r.scheduledTime.hour,
        minute: r.scheduledTime.minute,
        category: _mapCategory(r.type),
      );
    }
  }

  Future<void> _scheduleCustomDays(ReminderEntity r) async {
    for (var i = 0; i < r.activeDays.length; i++) {
      if (!r.activeDays[i]) continue;
      final weekday = i + 1; // Monday=1
      await _svc.scheduleWeekly(
        id: _notifId(r.id, slot: weekday),
        title: r.title,
        body: r.body,
        weekday: weekday,
        hour: r.scheduledTime.hour,
        minute: r.scheduledTime.minute,
        category: _mapCategory(r.type),
      );
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Stable 32-bit notification id derived from reminderId + optional slot.
  int _notifId(String reminderId, {int slot = 0}) {
    return (reminderId.hashCode & 0x7FFFFFFF) + slot;
  }

  NotificationCategory _mapCategory(ReminderType type) => switch (type) {
        ReminderType.medication => NotificationCategory.medication,
        ReminderType.water ||
        ReminderType.meal ||
        ReminderType.weight ||
        ReminderType.bloodPressure ||
        ReminderType.heartRate ||
        ReminderType.bloodSugar =>
          NotificationCategory.health,
        ReminderType.workout => NotificationCategory.fitness,
        ReminderType.sleep => NotificationCategory.health,
      };
}
