import 'package:logger/logger.dart';

final _log = Logger();

// ══════════════════════════════════════════════════════════════════════════════
// BACKGROUND TASK TYPE
// ══════════════════════════════════════════════════════════════════════════════

enum BackgroundTaskType {
  dailySync('daily_sync', 'Syncs health data with the backend'),
  reminderCheck('reminder_check', 'Checks for missed or upcoming reminders'),
  dailyHealthSummary('daily_health_summary', 'Computes and stores daily metrics summary'),
  aiInsightGeneration('ai_insight_generation', 'Generates AI-powered health insights'),
  missedReminderDetection('missed_reminder_detection', 'Flags reminders that were not acted upon'),
  goalProgressRefresh('goal_progress_refresh', 'Recalculates goal completion percentages');

  const BackgroundTaskType(this.taskId, this.description);
  final String taskId;
  final String description;
}

// ══════════════════════════════════════════════════════════════════════════════
// BACKGROUND TASK RESULT
// ══════════════════════════════════════════════════════════════════════════════

sealed class BackgroundTaskResult {
  const BackgroundTaskResult();
}

final class TaskSuccess extends BackgroundTaskResult {
  const TaskSuccess(this.taskId, {this.data});
  final String taskId;
  final Map<String, dynamic>? data;
}

final class TaskFailure extends BackgroundTaskResult {
  const TaskFailure(this.taskId, this.error);
  final String taskId;
  final String error;
}

final class TaskSkipped extends BackgroundTaskResult {
  const TaskSkipped(this.taskId, this.reason);
  final String taskId;
  final String reason;
}

// ══════════════════════════════════════════════════════════════════════════════
// BACKGROUND TASK HANDLER
// ══════════════════════════════════════════════════════════════════════════════

/// Signature for a registered background task callback.
typedef BackgroundTaskCallback = Future<BackgroundTaskResult> Function(
  Map<String, dynamic> inputData,
);

// ══════════════════════════════════════════════════════════════════════════════
// BACKGROUND SERVICE
// ══════════════════════════════════════════════════════════════════════════════

/// Task registry + dispatcher for all background work.
///
/// **Integration path (when ready):**
/// - Android: replace [_dispatch] with `workmanager` periodic tasks.
/// - iOS: replace with `BGTaskScheduler` via a platform channel or `workmanager`.
///
/// All call-sites remain unchanged after the swap.
class BackgroundService {
  BackgroundService._();
  static final BackgroundService instance = BackgroundService._();

  final Map<String, BackgroundTaskCallback> _registry = {};
  bool _initialized = false;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Call once in [main] after all services are initialized.
  Future<void> initialize() async {
    if (_initialized) return;
    _log.i('BackgroundService: registering tasks');
    _registerDefaultTasks();
    _initialized = true;
    _log.i('BackgroundService: ready (${_registry.length} tasks registered)');
  }

  // ── Registration ──────────────────────────────────────────────────────────

  /// Register a callback for [taskType].
  void register(BackgroundTaskType taskType, BackgroundTaskCallback callback) {
    _registry[taskType.taskId] = callback;
    _log.d('BackgroundService: registered "${taskType.taskId}"');
  }

  // ── Dispatch ──────────────────────────────────────────────────────────────

  /// Execute the task with [taskId] immediately (e.g., for testing / debug).
  Future<BackgroundTaskResult> dispatch(
    BackgroundTaskType taskType, {
    Map<String, dynamic> inputData = const {},
  }) async {
    final callback = _registry[taskType.taskId];
    if (callback == null) {
      return TaskFailure(taskType.taskId, 'No handler registered');
    }
    _log.i('BackgroundService: dispatching "${taskType.taskId}"');
    try {
      final result = await callback(inputData);
      _log.i('BackgroundService: "${taskType.taskId}" → $result');
      return result;
    } catch (e, st) {
      _log.e('BackgroundService: "${taskType.taskId}" failed',
          error: e, stackTrace: st);
      return TaskFailure(taskType.taskId, e.toString());
    }
  }

  /// Schedule [taskType] as a periodic task via the platform's background runner.
  ///
  /// Currently a no-op — replace body with Workmanager / BGTaskScheduler call.
  Future<void> schedulePeriodicTask(
    BackgroundTaskType taskType, {
    required Duration frequency,
    Map<String, dynamic> inputData = const {},
  }) async {
    _log.i('BackgroundService.schedulePeriodicTask '
        '"${taskType.taskId}" every ${frequency.inMinutes}min (mock)');
    // TODO(setup): await Workmanager().registerPeriodicTask(
    //   taskType.taskId,
    //   taskType.taskId,
    //   frequency: frequency,
    //   inputData: inputData,
    // );
  }

  /// Cancel a previously scheduled periodic task.
  Future<void> cancelTask(BackgroundTaskType taskType) async {
    _log.i('BackgroundService.cancelTask "${taskType.taskId}"');
    // TODO(setup): await Workmanager().cancelByUniqueName(taskType.taskId);
  }

  Future<void> cancelAll() async {
    _log.i('BackgroundService.cancelAll');
    // TODO(setup): await Workmanager().cancelAll();
  }

  // ── Default task implementations ──────────────────────────────────────────

  void _registerDefaultTasks() {
    register(BackgroundTaskType.dailySync, _dailySync);
    register(BackgroundTaskType.reminderCheck, _reminderCheck);
    register(BackgroundTaskType.dailyHealthSummary, _dailyHealthSummary);
    register(BackgroundTaskType.aiInsightGeneration, _aiInsightGeneration);
    register(BackgroundTaskType.missedReminderDetection, _missedReminderDetection);
    register(BackgroundTaskType.goalProgressRefresh, _goalProgressRefresh);
  }

  // ── Task stubs (replace with real logic per feature) ─────────────────────

  Future<BackgroundTaskResult> _dailySync(Map<String, dynamic> _) async {
    _log.d('_dailySync: placeholder — sync health data with backend');
    // TODO: Fetch remote health data via Dio and persist to Hive.
    return const TaskSuccess('daily_sync', data: {'synced': 0});
  }

  Future<BackgroundTaskResult> _reminderCheck(Map<String, dynamic> _) async {
    _log.d('_reminderCheck: placeholder — check upcoming reminders');
    // TODO: Query ReminderRepository, fire NotificationService.show() for due reminders.
    return const TaskSuccess('reminder_check', data: {'fired': 0});
  }

  Future<BackgroundTaskResult> _dailyHealthSummary(Map<String, dynamic> _) async {
    _log.d('_dailyHealthSummary: placeholder — compute daily metrics');
    // TODO: Aggregate today's readings → store DailySummary entity.
    return const TaskSuccess('daily_health_summary');
  }

  Future<BackgroundTaskResult> _aiInsightGeneration(Map<String, dynamic> _) async {
    _log.d('_aiInsightGeneration: placeholder — generate AI insights');
    // TODO: Call AI repository → generate insights → notify user.
    return const TaskSuccess('ai_insight_generation');
  }

  Future<BackgroundTaskResult> _missedReminderDetection(Map<String, dynamic> _) async {
    _log.d('_missedReminderDetection: placeholder — detect missed reminders');
    // TODO: Compare reminder history vs schedule → mark missed entries.
    return const TaskSuccess('missed_reminder_detection', data: {'missed': 0});
  }

  Future<BackgroundTaskResult> _goalProgressRefresh(Map<String, dynamic> _) async {
    _log.d('_goalProgressRefresh: placeholder — refresh goal progress');
    // TODO: Recalculate step / calorie / water progress vs targets.
    return const TaskSuccess('goal_progress_refresh');
  }
}
