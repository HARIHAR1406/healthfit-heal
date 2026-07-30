import 'dart:async';

import '../network/network_info.dart';
import '../utils/app_logger.dart';
import 'sync_entity.dart';
import 'sync_queue.dart';
import 'sync_service.dart';

/// Orchestrates offline sync — listens for network changes and triggers
/// [SyncService.processPending] when connectivity is restored.
///
/// Also runs a periodic sync every [_syncInterval] when the app is active.
class SyncManager {
  SyncManager._({
    required NetworkInfo networkInfo,
    required SyncService syncService,
    required SyncQueue queue,
  })  : _networkInfo = networkInfo,
        _syncService = syncService,
        _queue = queue;

  static SyncManager? _instance;

  static void initialize({
    required NetworkInfo networkInfo,
  }) {
    _instance ??= SyncManager._(
      networkInfo: networkInfo,
      syncService: SyncService.instance,
      queue: SyncQueue.instance,
    );
  }

  static SyncManager get instance {
    if (_instance == null) {
      throw StateError('SyncManager not initialized. Call SyncManager.initialize() first.');
    }
    return _instance!;
  }

  final NetworkInfo _networkInfo;
  final SyncService _syncService;
  final SyncQueue _queue;

  static const Duration _syncInterval = Duration(minutes: 5);

  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _periodicTimer;

  final _syncStatusController = StreamController<SyncManagerStatus>.broadcast();

  Stream<SyncManagerStatus> get syncStatusStream => _syncStatusController.stream;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Starts the sync manager — subscribes to connectivity and starts timer.
  void start() {
    _connectivitySubscription = _networkInfo.onConnectivityChanged.listen(
      _onConnectivityChange,
    );

    _periodicTimer = Timer.periodic(_syncInterval, (_) => _trySync());

    log.info('SyncManager: started (interval=${_syncInterval.inMinutes}min)');
  }

  /// Stops the sync manager.
  void stop() {
    _connectivitySubscription?.cancel();
    _periodicTimer?.cancel();
    log.info('SyncManager: stopped');
  }

  void dispose() {
    stop();
    _syncStatusController.close();
  }

  // ── Enqueue ────────────────────────────────────────────────────────────────

  /// Enqueues an operation for later sync.
  Future<void> enqueue({
    required String entityType,
    required String entityId,
    required SyncOperation operation,
    required Map<String, dynamic> payload,
    int maxRetries = 3,
  }) async {
    final item = SyncQueueItem(
      id: '${entityType}_${entityId}_${DateTime.now().millisecondsSinceEpoch}',
      operation: operation,
      entityType: entityType,
      entityId: entityId,
      payload: payload,
      createdAt: DateTime.now(),
      maxRetries: maxRetries,
    );

    await _queue.enqueue(item);

    _emitStatus();

    // Immediately try to sync if online
    final isOnline = await _networkInfo.isConnected;
    if (isOnline) {
      unawaited(_trySync());
    }
  }

  // ── Manual Sync ────────────────────────────────────────────────────────────

  /// Manually triggers a sync pass. Useful for pull-to-refresh.
  Future<void> syncNow() => _trySync();

  // ── Status ────────────────────────────────────────────────────────────────

  SyncManagerStatus get status => SyncManagerStatus(
        pendingCount: _queue.pendingCount,
        failedCount: _queue.failedCount,
        isSyncing: _syncService.isProcessing,
      );

  // ── Internal ──────────────────────────────────────────────────────────────

  void _onConnectivityChange(bool isOnline) {
    if (isOnline && _queue.pendingCount > 0) {
      log.info(
        'SyncManager: connectivity restored — '
        'processing ${_queue.pendingCount} pending items',
      );
      unawaited(_trySync());
    }
  }

  Future<void> _trySync() async {
    if (_syncService.isProcessing) return;

    try {
      final isOnline = await _networkInfo.isConnected;
      if (!isOnline) return;

      _syncStatusController.add(status.copyWith(isSyncing: true));
      await _syncService.processPending();
    } finally {
      _emitStatus();
    }
  }

  void _emitStatus() {
    if (!_syncStatusController.isClosed) {
      _syncStatusController.add(status);
    }
  }
}

/// Status snapshot for the sync manager.
class SyncManagerStatus {
  const SyncManagerStatus({
    required this.pendingCount,
    required this.failedCount,
    required this.isSyncing,
  });

  final int pendingCount;
  final int failedCount;
  final bool isSyncing;

  bool get hasPending => pendingCount > 0;
  bool get hasFailed => failedCount > 0;

  SyncManagerStatus copyWith({
    int? pendingCount,
    int? failedCount,
    bool? isSyncing,
  }) {
    return SyncManagerStatus(
      pendingCount: pendingCount ?? this.pendingCount,
      failedCount: failedCount ?? this.failedCount,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}

/// Fire-and-forget utility.
void unawaited(Future<void> future) {
  future.then((_) {}).catchError((Object e) {
    log.trace('SyncManager unawaited error', error: e);
  });
}
