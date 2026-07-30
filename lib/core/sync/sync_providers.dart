import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/network_info.dart';
import 'sync_entity.dart';
import 'sync_manager.dart';
import 'sync_queue.dart';
import 'sync_service.dart';

// ── Queue ──────────────────────────────────────────────────────────────────────

final syncQueueProvider = Provider<SyncQueue>(
  (_) => SyncQueue.instance,
  name: 'syncQueueProvider',
);

// ── Service ────────────────────────────────────────────────────────────────────

final syncServiceProvider = Provider<SyncService>(
  (_) => SyncService.instance,
  name: 'syncServiceProvider',
);

// ── Manager ────────────────────────────────────────────────────────────────────

final syncManagerProvider = Provider<SyncManager>(
  (ref) {
    final networkInfo = ref.watch(networkInfoProvider);
    SyncManager.initialize(networkInfo: networkInfo);
    return SyncManager.instance;
  },
  name: 'syncManagerProvider',
);

// ── Status Stream ──────────────────────────────────────────────────────────────

/// Stream of sync status updates for UI indicators (badges, banners).
final syncStatusStreamProvider = StreamProvider<SyncManagerStatus>(
  (ref) => ref.watch(syncManagerProvider).syncStatusStream,
  name: 'syncStatusStreamProvider',
);

/// Count of pending sync items — for home screen badge.
final pendingSyncCountProvider = Provider<int>(
  (ref) => ref.watch(syncQueueProvider).pendingCount,
  name: 'pendingSyncCountProvider',
);

/// Count of failed sync items — for error indicator.
final failedSyncCountProvider = Provider<int>(
  (ref) => ref.watch(syncQueueProvider).failedCount,
  name: 'failedSyncCountProvider',
);
