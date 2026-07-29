import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import 'notification_state.dart';

final _log = Logger();

// ══════════════════════════════════════════════════════════════════════════════
// NOTIFICATION NOTIFIER
// ══════════════════════════════════════════════════════════════════════════════

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier(this._repo) : super(const NotificationInitial());

  final NotificationRepository _repo;

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> load() async {
    state = const NotificationLoading();
    try {
      final all = await _repo.getAll();
      final settings = await _repo.getSettings();
      final unread = all.where((n) => !n.isRead).length;
      state = NotificationLoaded(
        all: all,
        filtered: all,
        activeCategory: null,
        searchQuery: '',
        settings: settings,
        unreadCount: unread,
      );
    } catch (e, st) {
      _log.e('NotificationNotifier.load', error: e, stackTrace: st);
      state = NotificationError(e.toString());
    }
  }

  // ── Filter & Search ───────────────────────────────────────────────────────

  void setCategory(NotificationCategory? category) {
    final s = _loaded;
    if (s == null) return;
    final filtered = _applyFilters(s.all, category, s.searchQuery);
    state = s.copyWith(
      filtered: filtered,
      activeCategory: () => category,
    );
  }

  void setSearch(String query) {
    final s = _loaded;
    if (s == null) return;
    final filtered = _applyFilters(s.all, s.activeCategory, query);
    state = s.copyWith(filtered: filtered, searchQuery: query);
  }

  List<NotificationEntity> _applyFilters(
    List<NotificationEntity> all,
    NotificationCategory? category,
    String query,
  ) {
    var list = all;
    if (category != null) {
      list = list.where((n) => n.category == category).toList();
    }
    if (query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((n) =>
          n.title.toLowerCase().contains(q) ||
          n.body.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  Future<void> markRead(String id) async {
    try {
      await _repo.markRead(id);
      await _refreshList();
    } catch (e, st) {
      _log.e('NotificationNotifier.markRead', error: e, stackTrace: st);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _repo.markAllRead();
      await _refreshList();
    } catch (e, st) {
      _log.e('NotificationNotifier.markAllRead', error: e, stackTrace: st);
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> delete(String id) async {
    try {
      await _repo.delete(id);
      await _refreshList();
    } catch (e, st) {
      _log.e('NotificationNotifier.delete', error: e, stackTrace: st);
    }
  }

  Future<void> deleteSelected(List<String> ids) async {
    try {
      await _repo.deleteMany(ids);
      await _refreshList();
    } catch (e, st) {
      _log.e('NotificationNotifier.deleteSelected', error: e, stackTrace: st);
    }
  }

  Future<void> clearAll() async {
    try {
      await _repo.clearAll();
      await _refreshList();
    } catch (e, st) {
      _log.e('NotificationNotifier.clearAll', error: e, stackTrace: st);
    }
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  Future<void> updateSettings(NotificationSettings settings) async {
    try {
      await _repo.saveSettings(settings);
      final s = _loaded;
      if (s != null) state = s.copyWith(settings: settings);
    } catch (e, st) {
      _log.e('NotificationNotifier.updateSettings', error: e, stackTrace: st);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _refreshList() async {
    final s = _loaded;
    if (s == null) return;
    final all = await _repo.getAll();
    final unread = all.where((n) => !n.isRead).length;
    final filtered = _applyFilters(all, s.activeCategory, s.searchQuery);
    state = s.copyWith(all: all, filtered: filtered, unreadCount: unread);
  }

  NotificationLoaded? get _loaded =>
      state is NotificationLoaded ? state as NotificationLoaded : null;

  void reset() => state = const NotificationInitial();
}
