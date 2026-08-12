import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

/// Service that manages [Hive] boxes for local data persistence.
///
/// Call [HiveService.init] once at app startup before opening any boxes.
/// Use the typed [openBox] / [openLazyBox] methods to access boxes.
class HiveService {
  HiveService._();

  static final HiveService _instance = HiveService._();

  /// The singleton [HiveService] instance.
  static HiveService get instance => _instance;

  bool _initialised = false;

  // ── Initialisation ────────────────────────────────────────────────────────

  /// Initialises Hive and registers all type adapters.
  ///
  /// Must be called before [runApp] or any box access.
  Future<void> init() async {
    if (_initialised) return;

    await Hive.initFlutter();

    // ── Register Type Adapters ─────────────────────────────────────────────
    // TODO: Register generated adapters here as features are added.
    // Example:
    //   Hive.registerAdapter(UserModelAdapter());
    //   Hive.registerAdapter(WorkoutModelAdapter());

    // ── Open Core Boxes ───────────────────────────────────────────────────
    await Future.wait([
      Hive.openBox<dynamic>(AppConstants.hiveSettingsBox),
      Hive.openBox<dynamic>(AppConstants.hiveCacheBox),
    ]);

    _initialised = true;
    log.info('HiveService initialised.');
  }

  // ── Box Access ────────────────────────────────────────────────────────────

  /// Returns the already-opened [Box] with [boxName].
  /// Throws if the box has not been opened yet.
  Box<T> box<T>(String boxName) => Hive.box<T>(boxName);

  /// Opens (or returns cached) a [Box] with [boxName].
  Future<Box<T>> openBox<T>(String boxName) async {
    if (Hive.isBoxOpen(boxName)) return Hive.box<T>(boxName);
    return Hive.openBox<T>(boxName);
  }

  /// Opens (or returns cached) a [LazyBox] with [boxName].
  Future<LazyBox<T>> openLazyBox<T>(String boxName) async {
    if (Hive.isBoxOpen(boxName)) return Hive.lazyBox<T>(boxName);
    return Hive.openLazyBox<T>(boxName);
  }

  // ── Settings Box Helpers ──────────────────────────────────────────────────

  Box<dynamic> get settingsBox => Hive.box<dynamic>(AppConstants.hiveSettingsBox);
  Box<dynamic> get cacheBox => Hive.box<dynamic>(AppConstants.hiveCacheBox);

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Closes all open Hive boxes. Call on app shutdown or logout.
  Future<void> closeAll() async {
    await Hive.close();
    _initialised = false;
    log.info('HiveService closed all boxes.');
  }

  /// Deletes all data in all boxes. Use only for testing or factory reset.
  Future<void> clearAll() async {
    // Clear the boxes we know about
    for (final boxName in [
      AppConstants.hiveSettingsBox,
      AppConstants.hiveCacheBox,
    ]) {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box<dynamic>(boxName).clear();
      }
    }
    log.warning('HiveService: all boxes cleared.');
  }
}

