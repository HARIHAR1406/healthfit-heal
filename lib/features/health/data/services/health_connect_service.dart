import 'package:health/health.dart';

import '../../../../core/utils/app_logger.dart';

/// Android Health Connect service for HealthFit Heal.
///
/// Wraps the `health` package to provide typed read/write operations
/// for all supported health metrics.
///
/// ── Required AndroidManifest.xml entries ─────────────────────────────────────
/// (See android/app/src/main/AndroidManifest.xml — updated separately)
///   <uses-permission android:name="android.permission.health.READ_STEPS" />
///   <uses-permission android:name="android.permission.health.READ_HEART_RATE" />
///   ... (full list in AndroidManifest.xml)
///
/// ── Requirements ─────────────────────────────────────────────────────────────
///   - Android API level 28+ (Android 9.0+)
///   - Health Connect app installed (auto-installed on Android 14+)
///   - User must grant permissions through the Health Connect permission dialog
class HealthConnectService {
  HealthConnectService._();

  static final HealthConnectService _instance = HealthConnectService._();
  static HealthConnectService get instance => _instance;

  final Health _health = Health();

  // ── Permissions ────────────────────────────────────────────────────────────

  /// All data types the app reads/writes.
  static const List<HealthDataType> _readTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.BODY_TEMPERATURE,
    HealthDataType.WORKOUT,
  ];

  static const List<HealthDataType> _writeTypes = [
    HealthDataType.STEPS,
    HealthDataType.WEIGHT,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.WORKOUT,
  ];

  static const List<HealthDataAccess> _readAccess = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  // ── Availability ────────────────────────────────────────────────────────────

  /// Returns true if Health Connect is available on this device.
  Future<bool> isAvailable() async {
    try {
      return await _health.isHealthConnectAvailable();
    } catch (e) {
      log.warning('HealthConnect: availability check failed', error: e);
      return false;
    }
  }

  // ── Permissions ────────────────────────────────────────────────────────────

  /// Requests read permissions for all supported health data types.
  /// Returns true if all permissions were granted.
  Future<bool> requestPermissions() async {
    try {
      final granted = await _health.requestAuthorization(
        _readTypes,
        permissions: _readAccess,
      );
      log.info('HealthConnect: permissions granted=$granted');
      return granted;
    } catch (e) {
      log.error('HealthConnect: permission request failed', error: e);
      return false;
    }
  }

  /// Returns true if all read permissions are currently granted.
  Future<bool> hasPermissions() async {
    try {
      final result = await _health.hasPermissions(
        _readTypes,
        permissions: _readAccess,
      );
      return result ?? false;
    } catch (e) {
      log.warning('HealthConnect: hasPermissions check failed', error: e);
      return false;
    }
  }

  // ── Steps ──────────────────────────────────────────────────────────────────

  /// Returns total step count between [start] and [end].
  Future<int> readStepCount(DateTime start, DateTime end) async {
    try {
      final steps = await _health.getTotalStepsInInterval(start, end);
      return steps ?? 0;
    } catch (e) {
      log.error('HealthConnect: readStepCount failed', error: e);
      return 0;
    }
  }

  // ── Heart Rate ─────────────────────────────────────────────────────────────

  /// Returns heart rate readings between [start] and [end].
  Future<List<HealthDataPoint>> readHeartRate(
    DateTime start,
    DateTime end,
  ) async {
    return _readType(HealthDataType.HEART_RATE, start, end);
  }

  // ── Blood Pressure ─────────────────────────────────────────────────────────

  /// Returns blood pressure readings (systolic + diastolic) between [start] and [end].
  Future<({List<HealthDataPoint> systolic, List<HealthDataPoint> diastolic})>
      readBloodPressure(DateTime start, DateTime end) async {
    final systolic = await _readType(
      HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
      start,
      end,
    );
    final diastolic = await _readType(
      HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
      start,
      end,
    );
    return (systolic: systolic, diastolic: diastolic);
  }

  // ── Blood Glucose ──────────────────────────────────────────────────────────

  /// Returns blood glucose readings between [start] and [end].
  Future<List<HealthDataPoint>> readBloodGlucose(
    DateTime start,
    DateTime end,
  ) async {
    return _readType(HealthDataType.BLOOD_GLUCOSE, start, end);
  }

  // ── Sleep ──────────────────────────────────────────────────────────────────

  /// Returns sleep session data between [start] and [end].
  Future<List<HealthDataPoint>> readSleep(
    DateTime start,
    DateTime end,
  ) async {
    final asleep = await _readType(HealthDataType.SLEEP_ASLEEP, start, end);
    final awake = await _readType(HealthDataType.SLEEP_AWAKE, start, end);
    return [...asleep, ...awake];
  }

  // ── Calories ───────────────────────────────────────────────────────────────

  /// Returns active energy burned between [start] and [end].
  Future<List<HealthDataPoint>> readCalories(
    DateTime start,
    DateTime end,
  ) async {
    return _readType(HealthDataType.ACTIVE_ENERGY_BURNED, start, end);
  }

  // ── Weight ────────────────────────────────────────────────────────────────

  /// Returns weight readings between [start] and [end].
  Future<List<HealthDataPoint>> readWeight(
    DateTime start,
    DateTime end,
  ) async {
    return _readType(HealthDataType.WEIGHT, start, end);
  }

  // ── SpO₂ ──────────────────────────────────────────────────────────────────

  /// Returns blood oxygen (SpO₂) readings between [start] and [end].
  Future<List<HealthDataPoint>> readSpO2(DateTime start, DateTime end) async {
    return _readType(HealthDataType.BLOOD_OXYGEN, start, end);
  }

  // ── Workouts ───────────────────────────────────────────────────────────────

  /// Returns workout sessions between [start] and [end].
  Future<List<HealthDataPoint>> readWorkouts(
    DateTime start,
    DateTime end,
  ) async {
    return _readType(HealthDataType.WORKOUT, start, end);
  }

  // ── Writes ────────────────────────────────────────────────────────────────

  /// Writes a step count entry to Health Connect.
  Future<bool> writeSteps({
    required int steps,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      return await _health.writeHealthData(
        value: steps.toDouble(),
        type: HealthDataType.STEPS,
        startTime: start,
        endTime: end,
      );
    } catch (e) {
      log.error('HealthConnect: writeSteps failed', error: e);
      return false;
    }
  }

  /// Writes a weight entry (in kg) to Health Connect.
  Future<bool> writeWeight({
    required double weightKg,
    required DateTime dateTime,
  }) async {
    try {
      return await _health.writeHealthData(
        value: weightKg,
        type: HealthDataType.WEIGHT,
        startTime: dateTime,
        endTime: dateTime,
      );
    } catch (e) {
      log.error('HealthConnect: writeWeight failed', error: e);
      return false;
    }
  }

  // ── Batch Read ────────────────────────────────────────────────────────────

  /// Reads all supported health data types for the given time range.
  /// Useful for the initial sync and delta syncs.
  Future<List<HealthDataPoint>> readAll(DateTime start, DateTime end) async {
    try {
      final dataPoints = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: _readTypes,
      );
      return _health.removeDuplicates(dataPoints);
    } catch (e) {
      log.error('HealthConnect: readAll failed', error: e);
      return [];
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<List<HealthDataPoint>> _readType(
    HealthDataType type,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final points = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [type],
      );
      return _health.removeDuplicates(points);
    } catch (e) {
      log.error(
        'HealthConnect: readType(${type.name}) failed',
        error: e,
      );
      return [];
    }
  }
}

