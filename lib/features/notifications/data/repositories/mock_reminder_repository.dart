import 'package:flutter/material.dart';

import '../../domain/entities/reminder_entity.dart';
import '../../domain/repositories/reminder_repository.dart';

// ══════════════════════════════════════════════════════════════════════════════
// MOCK REMINDER REPOSITORY
// ══════════════════════════════════════════════════════════════════════════════

/// In-memory reminder store with 9 seeded reminder templates.
///
/// Replace with Hive-backed implementation when platform is ready.
class MockReminderRepository implements ReminderRepository {
  MockReminderRepository() {
    _reminders = List.from(_seed());
    _history = List.from(_historySeeds());
  }

  late List<ReminderEntity> _reminders;
  late List<ReminderHistoryEntry> _history;

  static const _allDays = [true, true, true, true, true, true, true];
  static const _weekdays = [true, true, true, true, true, false, false];

  // ── Read ──────────────────────────────────────────────────────────────────

  @override
  Future<List<ReminderEntity>> getAll() async {
    await _delay();
    return List.unmodifiable(_reminders);
  }

  @override
  Future<List<ReminderEntity>> getActive() async {
    await _delay();
    return _reminders.where((r) => r.isEnabled).toList();
  }

  @override
  Future<ReminderEntity?> getById(String id) async {
    await _delay(ms: 100);
    try {
      return _reminders.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  @override
  Future<ReminderEntity> save(ReminderEntity reminder) async {
    await _delay(ms: 200);
    final i = _reminders.indexWhere((r) => r.id == reminder.id);
    if (i == -1) {
      _reminders.add(reminder);
    } else {
      _reminders[i] = reminder;
    }
    return reminder;
  }

  @override
  Future<ReminderEntity> toggle(String id) async {
    await _delay(ms: 150);
    final i = _indexOf(id);
    final r = _reminders[i];
    final updated = r.copyWith(
      status: r.isEnabled ? ReminderStatus.disabled : ReminderStatus.active,
    );
    _reminders[i] = updated;
    return updated;
  }

  @override
  Future<ReminderEntity> updateTime(String id, TimeOfDay time) async {
    await _delay(ms: 150);
    final i = _indexOf(id);
    final updated = _reminders[i].copyWith(scheduledTime: time);
    _reminders[i] = updated;
    return updated;
  }

  @override
  Future<ReminderEntity> snooze(String id, {int minutes = 10}) async {
    await _delay(ms: 150);
    final i = _indexOf(id);
    final updated = _reminders[i].copyWith(
      status: ReminderStatus.snoozed,
      snoozeUntil: DateTime.now().add(Duration(minutes: minutes)),
    );
    _reminders[i] = updated;
    return updated;
  }

  @override
  Future<ReminderEntity> skip(String id) async {
    await _delay(ms: 150);
    final i = _indexOf(id);
    // Skipping just logs — status returns to active on next fire.
    await logHistory(ReminderHistoryEntry(
      id: 'hist_${DateTime.now().millisecondsSinceEpoch}',
      reminderId: id,
      type: _reminders[i].type,
      title: _reminders[i].title,
      scheduledAt: DateTime.now(),
      status: ReminderHistoryStatus.skipped,
    ));
    return _reminders[i];
  }

  @override
  Future<bool> delete(String id) async {
    await _delay(ms: 150);
    final before = _reminders.length;
    _reminders.removeWhere((r) => r.id == id);
    return _reminders.length < before;
  }

  // ── History ───────────────────────────────────────────────────────────────

  @override
  Future<List<ReminderHistoryEntry>> getHistory({
    DateTime? from,
    DateTime? to,
    ReminderHistoryStatus? status,
    ReminderType? type,
  }) async {
    await _delay();
    return _history.where((h) {
      if (from != null && h.scheduledAt.isBefore(from)) return false;
      if (to != null && h.scheduledAt.isAfter(to)) return false;
      if (status != null && h.status != status) return false;
      if (type != null && h.type != type) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
  }

  @override
  Future<ReminderHistoryEntry> logHistory(ReminderHistoryEntry entry) async {
    _history.insert(0, entry);
    return entry;
  }

  @override
  Future<ReminderStatistics> getStatistics() async {
    await _delay();
    final total = _history.length;
    final completed =
        _history.where((h) => h.status == ReminderHistoryStatus.completed).length;
    final missed =
        _history.where((h) => h.status == ReminderHistoryStatus.missed).length;
    final skipped =
        _history.where((h) => h.status == ReminderHistoryStatus.skipped).length;
    final snoozed =
        _history.where((h) => h.status == ReminderHistoryStatus.snoozed).length;

    final byType = <ReminderType, int>{};
    for (final h in _history) {
      byType[h.type] = (byType[h.type] ?? 0) + 1;
    }

    return ReminderStatistics(
      totalFired: total,
      completed: completed,
      missed: missed,
      skipped: skipped,
      snoozed: snoozed,
      adherenceRate: total == 0 ? 1.0 : completed / total,
      currentStreak: 5,
      bestStreak: 14,
      byType: byType,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  int _indexOf(String id) {
    final i = _reminders.indexWhere((r) => r.id == id);
    if (i == -1) throw StateError('Reminder $id not found');
    return i;
  }

  Future<void> _delay({int ms = 400}) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  // ── Seed Data ─────────────────────────────────────────────────────────────

  List<ReminderEntity> _seed() => [
        ReminderEntity(
          id: 'rem_001',
          type: ReminderType.medication,
          title: 'Morning Medication',
          body: 'Time to take your morning medications (Vitamin D3 & Omega-3)',
          scheduledTime: const TimeOfDay(hour: 8, minute: 0),
          repeatSchedule: RepeatSchedule.daily,
          priority: ReminderPriority.high,
          status: ReminderStatus.active,
          activeDays: _allDays,
          notes: 'Take with breakfast',
        ),
        ReminderEntity(
          id: 'rem_002',
          type: ReminderType.water,
          title: 'Hydration Check',
          body: 'Stay hydrated! Drink a glass of water now.',
          scheduledTime: const TimeOfDay(hour: 10, minute: 0),
          repeatSchedule: RepeatSchedule.daily,
          priority: ReminderPriority.normal,
          status: ReminderStatus.active,
          activeDays: _allDays,
        ),
        ReminderEntity(
          id: 'rem_003',
          type: ReminderType.meal,
          title: 'Lunch Reminder',
          body: 'Time for lunch! Log your meal to track calories.',
          scheduledTime: const TimeOfDay(hour: 13, minute: 0),
          repeatSchedule: RepeatSchedule.weekdays,
          priority: ReminderPriority.normal,
          status: ReminderStatus.active,
          activeDays: _weekdays,
        ),
        ReminderEntity(
          id: 'rem_004',
          type: ReminderType.workout,
          title: 'Workout Time',
          body: 'Ready for your workout? Let\'s hit those fitness goals!',
          scheduledTime: const TimeOfDay(hour: 6, minute: 30),
          repeatSchedule: RepeatSchedule.weekdays,
          priority: ReminderPriority.high,
          status: ReminderStatus.active,
          activeDays: _weekdays,
        ),
        ReminderEntity(
          id: 'rem_005',
          type: ReminderType.sleep,
          title: 'Sleep Reminder',
          body: 'Wind down for bed. Aim for 8 hours of quality sleep.',
          scheduledTime: const TimeOfDay(hour: 22, minute: 30),
          repeatSchedule: RepeatSchedule.daily,
          priority: ReminderPriority.normal,
          status: ReminderStatus.active,
          activeDays: _allDays,
        ),
        ReminderEntity(
          id: 'rem_006',
          type: ReminderType.weight,
          title: 'Weekly Weight Check',
          body: 'Log your weight for this week\'s progress. Morning is best!',
          scheduledTime: const TimeOfDay(hour: 7, minute: 0),
          repeatSchedule: RepeatSchedule.custom,
          priority: ReminderPriority.normal,
          status: ReminderStatus.active,
          activeDays: [false, false, false, false, false, false, true], // Sunday
        ),
        ReminderEntity(
          id: 'rem_007',
          type: ReminderType.bloodPressure,
          title: 'Blood Pressure Reading',
          body: 'Take your morning BP reading. Sit quietly for 5 minutes first.',
          scheduledTime: const TimeOfDay(hour: 7, minute: 30),
          repeatSchedule: RepeatSchedule.daily,
          priority: ReminderPriority.high,
          status: ReminderStatus.disabled,
          activeDays: _allDays,
        ),
        ReminderEntity(
          id: 'rem_008',
          type: ReminderType.heartRate,
          title: 'Resting Heart Rate',
          body: 'Check your resting heart rate before getting out of bed.',
          scheduledTime: const TimeOfDay(hour: 6, minute: 0),
          repeatSchedule: RepeatSchedule.daily,
          priority: ReminderPriority.normal,
          status: ReminderStatus.disabled,
          activeDays: _allDays,
        ),
        ReminderEntity(
          id: 'rem_009',
          type: ReminderType.bloodSugar,
          title: 'Blood Sugar Check',
          body: 'Post-lunch blood sugar reading (2 hours after eating).',
          scheduledTime: const TimeOfDay(hour: 15, minute: 0),
          repeatSchedule: RepeatSchedule.daily,
          priority: ReminderPriority.high,
          status: ReminderStatus.disabled,
          activeDays: _allDays,
        ),
      ];

  List<ReminderHistoryEntry> _historySeeds() {
    final now = DateTime.now();
    return [
      ReminderHistoryEntry(
        id: 'hist_001', reminderId: 'rem_001', type: ReminderType.medication,
        title: 'Morning Medication', scheduledAt: now.subtract(const Duration(hours: 4)),
        status: ReminderHistoryStatus.completed, actedAt: now.subtract(const Duration(hours: 3, minutes: 50)),
      ),
      ReminderHistoryEntry(
        id: 'hist_002', reminderId: 'rem_002', type: ReminderType.water,
        title: 'Hydration Check', scheduledAt: now.subtract(const Duration(hours: 2)),
        status: ReminderHistoryStatus.completed, actedAt: now.subtract(const Duration(hours: 1, minutes: 55)),
      ),
      ReminderHistoryEntry(
        id: 'hist_003', reminderId: 'rem_004', type: ReminderType.workout,
        title: 'Workout Time', scheduledAt: now.subtract(const Duration(days: 1)),
        status: ReminderHistoryStatus.completed, actedAt: now.subtract(const Duration(hours: 23)),
      ),
      ReminderHistoryEntry(
        id: 'hist_004', reminderId: 'rem_005', type: ReminderType.sleep,
        title: 'Sleep Reminder', scheduledAt: now.subtract(const Duration(days: 1, hours: 2)),
        status: ReminderHistoryStatus.snoozed,
      ),
      ReminderHistoryEntry(
        id: 'hist_005', reminderId: 'rem_003', type: ReminderType.meal,
        title: 'Lunch Reminder', scheduledAt: now.subtract(const Duration(days: 1, hours: 3)),
        status: ReminderHistoryStatus.missed,
      ),
      ReminderHistoryEntry(
        id: 'hist_006', reminderId: 'rem_001', type: ReminderType.medication,
        title: 'Morning Medication', scheduledAt: now.subtract(const Duration(days: 1, hours: 16)),
        status: ReminderHistoryStatus.completed, actedAt: now.subtract(const Duration(days: 1, hours: 15, minutes: 45)),
      ),
      ReminderHistoryEntry(
        id: 'hist_007', reminderId: 'rem_002', type: ReminderType.water,
        title: 'Hydration Check', scheduledAt: now.subtract(const Duration(days: 2)),
        status: ReminderHistoryStatus.skipped,
      ),
      ReminderHistoryEntry(
        id: 'hist_008', reminderId: 'rem_004', type: ReminderType.workout,
        title: 'Workout Time', scheduledAt: now.subtract(const Duration(days: 2, hours: 1)),
        status: ReminderHistoryStatus.completed, actedAt: now.subtract(const Duration(days: 2)),
      ),
      ReminderHistoryEntry(
        id: 'hist_009', reminderId: 'rem_006', type: ReminderType.weight,
        title: 'Weekly Weight Check', scheduledAt: now.subtract(const Duration(days: 7)),
        status: ReminderHistoryStatus.completed, actedAt: now.subtract(const Duration(days: 6, hours: 23)),
      ),
      ReminderHistoryEntry(
        id: 'hist_010', reminderId: 'rem_005', type: ReminderType.sleep,
        title: 'Sleep Reminder', scheduledAt: now.subtract(const Duration(days: 2, hours: 2)),
        status: ReminderHistoryStatus.completed, actedAt: now.subtract(const Duration(days: 2, hours: 1, minutes: 30)),
      ),
    ];
  }
}
