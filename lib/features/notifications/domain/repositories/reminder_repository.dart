import 'package:flutter/material.dart';

import '../entities/reminder_entity.dart';

abstract interface class ReminderRepository {
  /// All reminders (active + disabled).
  Future<List<ReminderEntity>> getAll();

  /// Active/enabled reminders only.
  Future<List<ReminderEntity>> getActive();

  /// Single reminder by id.
  Future<ReminderEntity?> getById(String id);

  /// Create or replace a reminder.
  Future<ReminderEntity> save(ReminderEntity reminder);

  /// Toggle enabled/disabled.
  Future<ReminderEntity> toggle(String id);

  /// Update scheduled time only.
  Future<ReminderEntity> updateTime(String id, TimeOfDay time);

  /// Snooze a reminder by [minutes].
  Future<ReminderEntity> snooze(String id, {int minutes = 10});

  /// Mark reminder as skipped for the current firing.
  Future<ReminderEntity> skip(String id);

  /// Delete a reminder entirely.
  Future<bool> delete(String id);

  // ── History ───────────────────────────────────────────────────────────────

  Future<List<ReminderHistoryEntry>> getHistory({
    DateTime? from,
    DateTime? to,
    ReminderHistoryStatus? status,
    ReminderType? type,
  });

  Future<ReminderHistoryEntry> logHistory(ReminderHistoryEntry entry);

  Future<ReminderStatistics> getStatistics();
}
