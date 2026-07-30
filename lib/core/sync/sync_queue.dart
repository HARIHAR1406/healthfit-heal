import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../utils/app_logger.dart';
import 'sync_entity.dart';

/// Hive-backed persistent offline sync queue.
///
/// Stores [SyncQueueItem]s that failed to reach the backend due to
/// network unavailability or transient errors. Items are processed
/// in FIFO order when connectivity is restored.
///
/// Hive box: 'sync_queue' (opened by [HiveService] on app startup)
class SyncQueue {
  SyncQueue._();

  static final SyncQueue _instance = SyncQueue._();
  static SyncQueue get instance => _instance;

  static const String _boxName = 'sync_queue';
  static const int _maxQueueSize = 500;

  Box<String>? _box;

  /// Initializes the queue. Called from [HiveService.init].
  Future<void> initialize() async {
    _box = await Hive.openBox<String>(_boxName);
    log.info('SyncQueue: initialized with ${_box!.length} pending items');
  }

  Box<String> get _storage {
    if (_box == null) throw StateError('SyncQueue not initialized');
    return _box!;
  }

  // ── Counts ─────────────────────────────────────────────────────────────────

  int get pendingCount => _storage.values
      .map(_decode)
      .where((item) => item != null && item.status == SyncStatus.pending)
      .length;

  int get failedCount => _storage.values
      .map(_decode)
      .where((item) => item != null && item.hasFailed)
      .length;

  int get totalCount => _storage.length;

  // ── Read ───────────────────────────────────────────────────────────────────

  /// Returns all items sorted by creation time (FIFO).
  List<SyncQueueItem> getAll() {
    return _storage.values
        .map(_decode)
        .whereType<SyncQueueItem>()
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Returns all items with [SyncStatus.pending] or [SyncStatus.failed] (and retryable).
  List<SyncQueueItem> getPending() {
    return getAll().where((item) {
      return item.status == SyncStatus.pending ||
          (item.hasFailed && item.canRetry);
    }).toList();
  }

  /// Returns a single item by ID, or null.
  SyncQueueItem? getById(String id) => _decode(_storage.get(id));

  // ── Write ──────────────────────────────────────────────────────────────────

  /// Enqueues a new [SyncQueueItem].
  ///
  /// Silently drops the item if the queue is at capacity.
  Future<void> enqueue(SyncQueueItem item) async {
    if (_storage.length >= _maxQueueSize) {
      log.warning(
        'SyncQueue: at capacity ($_maxQueueSize) — dropping item ${item.id}',
      );
      return;
    }

    await _storage.put(item.id, jsonEncode(item.toJson()));
    log.debug(
      'SyncQueue: enqueued ${item.operation.name} ${item.entityType}/${item.entityId}',
    );
  }

  /// Updates an existing item (e.g. to update status, retry count).
  Future<void> update(SyncQueueItem item) async {
    if (!_storage.containsKey(item.id)) return;
    await _storage.put(item.id, jsonEncode(item.toJson()));
  }

  /// Removes a successfully synced item.
  Future<void> remove(String id) async {
    await _storage.delete(id);
    log.debug('SyncQueue: removed item $id');
  }

  /// Clears all items — use only on full reset.
  Future<void> clear() async {
    await _storage.clear();
    log.info('SyncQueue: cleared');
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  SyncQueueItem? _decode(String? raw) {
    if (raw == null) return null;
    try {
      return SyncQueueItem.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (e) {
      log.warning('SyncQueue: failed to decode item', error: e);
      return null;
    }
  }
}
