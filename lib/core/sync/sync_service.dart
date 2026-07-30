import 'package:dio/dio.dart';

import '../errors/app_exception.dart';
import '../network/dio_client.dart';
import '../utils/app_logger.dart';
import 'sync_entity.dart';
import 'sync_queue.dart';

/// Processes pending sync operations from [SyncQueue].
///
/// Implements optimistic retry with back-pressure:
///   - Processes items sequentially to respect server rate limits
///   - Updates retry count on failure
///   - Marks items as [SyncStatus.conflicted] on 409 responses
///   - Uses [ConflictStrategy.serverWins] by default
///
/// Usage:
///   await SyncService.instance.processPending();
class SyncService {
  SyncService._({
    required SyncQueue queue,
    required ConflictStrategy conflictStrategy,
  })  : _queue = queue,
        _conflictStrategy = conflictStrategy;

  static SyncService? _instance;

  static SyncService get instance {
    _instance ??= SyncService._(
      queue: SyncQueue.instance,
      conflictStrategy: ConflictStrategy.serverWins,
    );
    return _instance!;
  }

  final SyncQueue _queue;
  final ConflictStrategy _conflictStrategy;

  bool _isProcessing = false;
  int _processedCount = 0;
  int _failedCount = 0;

  bool get isProcessing => _isProcessing;

  // ── Process ────────────────────────────────────────────────────────────────

  /// Processes all pending queue items.
  ///
  /// Returns a summary: (processed, failed).
  Future<({int processed, int failed})> processPending() async {
    if (_isProcessing) {
      log.debug('SyncService: already processing — skipping');
      return (processed: 0, failed: 0);
    }

    final pending = _queue.getPending();
    if (pending.isEmpty) {
      log.debug('SyncService: no pending items');
      return (processed: 0, failed: 0);
    }

    _isProcessing = true;
    _processedCount = 0;
    _failedCount = 0;

    log.info('SyncService: processing ${pending.length} pending items');

    for (final item in pending) {
      final result = await _processItem(item);
      if (result.success) {
        _processedCount++;
        await _queue.remove(item.id);
      } else {
        _failedCount++;
      }
    }

    _isProcessing = false;

    log.info(
      'SyncService: done — '
      'processed=$_processedCount, failed=$_failedCount',
    );

    return (processed: _processedCount, failed: _failedCount);
  }

  /// Processes a single [SyncQueueItem].
  Future<SyncResult> _processItem(SyncQueueItem item) async {
    // Mark as in-progress
    await _queue.update(
      item.copyWith(
        status: SyncStatus.inProgress,
        lastAttemptAt: DateTime.now(),
      ),
    );

    try {
      await _executeRequest(item);

      log.debug(
        'SyncService: ✓ synced ${item.operation.name} ${item.entityType}/${item.entityId}',
      );

      return SyncResult(item: item, success: true);
    } on AppException catch (e) {
      return _handleFailure(item, e.message ?? 'Sync failed');
    } catch (e) {
      return _handleFailure(item, e.toString());
    }
  }

  Future<SyncResult> _handleFailure(SyncQueueItem item, String error) async {
    final newRetryCount = item.retryCount + 1;
    final failed = newRetryCount >= item.maxRetries;

    log.warning(
      'SyncService: ✗ ${item.entityType}/${item.entityId} '
      '(retry $newRetryCount/${item.maxRetries}): $error',
    );

    await _queue.update(
      item.copyWith(
        status: failed ? SyncStatus.failed : SyncStatus.pending,
        retryCount: newRetryCount,
        lastError: error,
        lastAttemptAt: DateTime.now(),
      ),
    );

    return SyncResult(item: item, success: false, error: error);
  }

  // ── Request Execution ──────────────────────────────────────────────────────

  Future<void> _executeRequest(SyncQueueItem item) async {
    final dio = DioClient.authenticated;
    final endpoint = _buildEndpoint(item);

    try {
      switch (item.operation) {
        case SyncOperation.create:
          await dio.post<void>(endpoint, data: item.payload);
        case SyncOperation.update:
          await dio.put<void>(endpoint, data: item.payload);
        case SyncOperation.delete:
          await dio.delete<void>(endpoint);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        // Conflict — apply resolution strategy
        await _resolveConflict(item, e);
      }
      throw mapDioException(e);
    }
  }

  Future<void> _resolveConflict(SyncQueueItem item, DioException error) async {
    log.warning(
      'SyncService: conflict for ${item.entityType}/${item.entityId} '
      '(strategy=${_conflictStrategy.name})',
    );

    switch (_conflictStrategy) {
      case ConflictStrategy.serverWins:
        // Remove the conflicted item — server version is authoritative
        await _queue.update(item.copyWith(status: SyncStatus.conflicted));
        break;
      case ConflictStrategy.clientWins:
        // Force update with the client payload
        try {
          await DioClient.authenticated.put<void>(
            _buildEndpoint(item),
            data: {...item.payload, 'force': true},
          );
        } catch (_) {}
        break;
      case ConflictStrategy.lastWriteWins:
        // Compare timestamps and let the newer version win
        final serverUpdatedAt = error.response?.data?['updated_at'] as String?;
        final serverTime = serverUpdatedAt != null
            ? DateTime.tryParse(serverUpdatedAt)
            : null;
        if (serverTime != null && serverTime.isAfter(item.createdAt)) {
          await _queue.update(item.copyWith(status: SyncStatus.conflicted));
        }
        break;
    }
  }

  String _buildEndpoint(SyncQueueItem item) {
    return switch (item.operation) {
      SyncOperation.create => '/${item.entityType}',
      SyncOperation.update || SyncOperation.delete =>
        '/${item.entityType}/${item.entityId}',
    };
  }
}
