import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../core/storage/hive_service.dart';
import 'health_connect_service.dart';

/// Manages periodic synchronization of Health Connect data.
///
/// Implements delta sync: only reads health data since the last successful
/// sync timestamp, minimizing data transfer and battery impact.
///
/// Sync schedule:
///   - Triggered on app foreground (via lifecycle observer)
///   - Every 30 minutes via periodic timer (when app is active)
///   - On Health Connect permission grant
class HealthConnectSyncService {
  HealthConnectSyncService._({
    required HealthConnectService healthConnect,
    required HiveService hive,
  })  : _healthConnect = healthConnect,
        _hive = hive;

  static HealthConnectSyncService? _instance;

  static HealthConnectSyncService get instance {
    _instance ??= HealthConnectSyncService._(
      healthConnect: HealthConnectService.instance,
      hive: HiveService.instance,
    );
    return _instance!;
  }

  final HealthConnectService _healthConnect;
  final HiveService _hive;

  static const String _lastSyncKey = 'health_connect_last_sync';
  static const Duration _maxLookback = Duration(days: 30);

  // ── Sync State ─────────────────────────────────────────────────────────────

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  List<HealthDataPoint>? _lastSyncResult;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  // ── Initialization ─────────────────────────────────────────────────────────

  Future<void> initialize() async {
    final stored = _hive.settingsBox.get(_lastSyncKey) as String?;
    if (stored != null) {
      _lastSyncTime = DateTime.tryParse(stored);
    }
    log.info(
      'HealthConnectSync: initialized (lastSync=${_lastSyncTime?.toIso8601String() ?? 'never'})',
    );
  }

  // ── Sync ──────────────────────────────────────────────────────────────────

  /// Performs a delta sync of all health data since the last sync.
  ///
  /// Returns the list of new [HealthDataPoint]s retrieved.
  /// Returns empty list if sync is not needed or not permitted.
  Future<List<HealthDataPoint>> sync() async {
    if (_isSyncing) {
      log.debug('HealthConnectSync: sync already in progress — skipping');
      return _lastSyncResult ?? [];
    }

    if (!await _healthConnect.isAvailable()) {
      log.debug('HealthConnectSync: Health Connect not available');
      return [];
    }

    if (!await _healthConnect.hasPermissions()) {
      log.debug('HealthConnectSync: permissions not granted — skipping sync');
      return [];
    }

    _isSyncing = true;

    try {
      final now = DateTime.now();
      final syncFrom = _computeSyncStart(now);

      log.info(
        'HealthConnectSync: syncing from ${syncFrom.toIso8601String()} '
        'to ${now.toIso8601String()}',
      );

      final dataPoints = await _healthConnect.readAll(syncFrom, now);

      log.info(
        'HealthConnectSync: received ${dataPoints.length} data points',
      );

      // Persist last successful sync time
      await _persistLastSyncTime(now);
      _lastSyncTime = now;
      _lastSyncResult = dataPoints;

      return dataPoints;
    } catch (e, st) {
      log.error('HealthConnectSync: sync failed', error: e, stackTrace: st);
      return [];
    } finally {
      _isSyncing = false;
    }
  }

  /// Forces a full re-sync (ignores last sync timestamp).
  Future<List<HealthDataPoint>> fullSync() async {
    _lastSyncTime = null;
    await _hive.settingsBox.delete(_lastSyncKey);
    return sync();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  DateTime _computeSyncStart(DateTime now) {
    if (_lastSyncTime == null) {
      // First sync: look back [_maxLookback] days
      return now.subtract(_maxLookback);
    }
    // Delta sync: from last sync with 5-minute overlap to catch edge cases
    return _lastSyncTime!.subtract(const Duration(minutes: 5));
  }

  Future<void> _persistLastSyncTime(DateTime time) async {
    await _hive.settingsBox.put(_lastSyncKey, time.toIso8601String());
  }
}

// ── Riverpod Providers ─────────────────────────────────────────────────────────

final healthConnectServiceProvider = Provider<HealthConnectService>(
  (_) => HealthConnectService.instance,
  name: 'healthConnectServiceProvider',
);

final healthConnectSyncProvider = Provider<HealthConnectSyncService>(
  (_) => HealthConnectSyncService.instance,
  name: 'healthConnectSyncProvider',
);

/// Reactive provider for Health Connect availability.
final healthConnectAvailableProvider = FutureProvider<bool>(
  (ref) => ref.watch(healthConnectServiceProvider).isAvailable(),
  name: 'healthConnectAvailableProvider',
);

/// Reactive provider for Health Connect permissions.
final healthConnectPermissionsProvider = FutureProvider<bool>(
  (ref) => ref.watch(healthConnectServiceProvider).hasPermissions(),
  name: 'healthConnectPermissionsProvider',
);

