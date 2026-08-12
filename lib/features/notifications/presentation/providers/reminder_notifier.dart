import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/reminder_entity.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../../data/services/reminder_scheduler.dart';
import 'reminder_state.dart';

final _log = Logger();

// ══════════════════════════════════════════════════════════════════════════════
// REMINDER NOTIFIER
// ══════════════════════════════════════════════════════════════════════════════

class ReminderNotifier extends StateNotifier<ReminderState> {
  ReminderNotifier(this._repo) : super(const ReminderInitial());

  final ReminderRepository _repo;
  final _scheduler = ReminderScheduler.instance;

  Future<void> load() async {
    state = const ReminderLoading();
    try {
      final all = await _repo.getAll();
      state = ReminderLoaded(
        reminders: all,
        activeCount: all.where((r) => r.isEnabled).length,
        disabledCount: all.where((r) => !r.isEnabled).length,
      );
    } catch (e, st) {
      _log.e('ReminderNotifier.load', error: e, stackTrace: st);
      state = ReminderError(e.toString());
    }
  }

  // ── Toggle ────────────────────────────────────────────────────────────────

  Future<void> toggle(String id) async {
    try {
      final updated = await _repo.toggle(id);
      await _scheduler.reschedule(updated);
      await _refreshList();
    } catch (e, st) {
      _log.e('ReminderNotifier.toggle', error: e, stackTrace: st);
    }
  }

  // ── Update time ───────────────────────────────────────────────────────────

  Future<void> updateTime(String id, TimeOfDay time) async {
    try {
      final updated = await _repo.updateTime(id, time);
      await _scheduler.reschedule(updated);
      await _refreshList();
    } catch (e, st) {
      _log.e('ReminderNotifier.updateTime', error: e, stackTrace: st);
    }
  }

  // ── Save (create / update full entity) ───────────────────────────────────

  Future<void> save(ReminderEntity reminder) async {
    try {
      final saved = await _repo.save(reminder);
      await _scheduler.schedule(saved);
      await _refreshList();
    } catch (e, st) {
      _log.e('ReminderNotifier.save', error: e, stackTrace: st);
    }
  }

  // ── Snooze ────────────────────────────────────────────────────────────────

  Future<void> snooze(String id, {int minutes = 10}) async {
    try {
      final reminder = await _repo.getById(id);
      if (reminder == null) return;
      await _repo.snooze(id, minutes: minutes);
      await _scheduler.snooze(reminder, minutes: minutes);
      await _repo.logHistory(ReminderHistoryEntry(
        id: 'hist_${DateTime.now().millisecondsSinceEpoch}',
        reminderId: id,
        type: reminder.type,
        title: reminder.title,
        scheduledAt: DateTime.now(),
        status: ReminderHistoryStatus.snoozed,
      ));
      await _refreshList();
    } catch (e, st) {
      _log.e('ReminderNotifier.snooze', error: e, stackTrace: st);
    }
  }

  // ── Skip ──────────────────────────────────────────────────────────────────

  Future<void> skip(String id) async {
    try {
      await _repo.skip(id);
      await _refreshList();
    } catch (e, st) {
      _log.e('ReminderNotifier.skip', error: e, stackTrace: st);
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> delete(String id) async {
    try {
      final reminder = await _repo.getById(id);
      if (reminder != null) await _scheduler.cancel(reminder);
      await _repo.delete(id);
      await _refreshList();
    } catch (e, st) {
      _log.e('ReminderNotifier.delete', error: e, stackTrace: st);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _refreshList() async {
    final all = await _repo.getAll();
    state = ReminderLoaded(
      reminders: all,
      activeCount: all.where((r) => r.isEnabled).length,
      disabledCount: all.where((r) => !r.isEnabled).length,
    );
  }

  void reset() => state = const ReminderInitial();
}

// ══════════════════════════════════════════════════════════════════════════════
// REMINDER HISTORY NOTIFIER
// ══════════════════════════════════════════════════════════════════════════════

class ReminderHistoryNotifier extends StateNotifier<ReminderHistoryState> {
  ReminderHistoryNotifier(this._repo) : super(const ReminderHistoryInitial());

  final ReminderRepository _repo;

  Future<void> load() async {
    state = const ReminderHistoryLoading();
    try {
      final entries = await _repo.getHistory();
      final stats = await _repo.getStatistics();
      state = ReminderHistoryLoaded(
        entries: entries,
        statistics: stats,
        activeFilter: null,
      );
    } catch (e, st) {
      _log.e('ReminderHistoryNotifier.load', error: e, stackTrace: st);
      state = ReminderHistoryError(e.toString());
    }
  }

  Future<void> setFilter(ReminderHistoryStatus? status) async {
    final s = state;
    if (s is! ReminderHistoryLoaded) return;
    final entries = await _repo.getHistory(status: status);
    state = s.copyWith(
      entries: entries,
      activeFilter: () => status,
    );
  }

  void reset() => state = const ReminderHistoryInitial();
}

