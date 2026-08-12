import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_logger.dart';
import '../../data/datasources/fitness_local_datasource.dart';
import '../../data/datasources/fitness_remote_datasource.dart';
import '../../data/repositories/fitness_repository_impl.dart';
import '../../domain/entities/fitness_stats_entity.dart';
import '../../domain/entities/workout_entity.dart';
import '../../domain/entities/workout_session_entity.dart';
import '../../domain/entities/fitness_stats_entity.dart';
import '../../domain/entities/achievement_entity.dart';
import '../../domain/repositories/fitness_repository.dart';
import 'fitness_state.dart';

// ── Repository Provider ────────────────────────────────────────────────────────

final fitnessLocalDatasourceProvider = Provider<FitnessLocalDatasource>(
  (_) => FitnessLocalDatasource(),
  name: 'fitnessLocalDatasourceProvider',
);

final fitnessRemoteDatasourceProvider = Provider<FitnessRemoteDatasource>(
  (_) => FitnessRemoteDatasource(),
  name: 'fitnessRemoteDatasourceProvider',
);

final fitnessRepositoryProvider = Provider<FitnessRepository>(
  (ref) => FitnessRepositoryImpl(
    localDatasource: ref.watch(fitnessLocalDatasourceProvider),
    remoteDatasource: ref.watch(fitnessRemoteDatasourceProvider),
  ),
  name: 'fitnessRepositoryProvider',
);

// ── Fitness Dashboard Notifier ────────────────────────────────────────────────

class FitnessNotifier extends StateNotifier<FitnessState> {
  FitnessNotifier({required FitnessRepository repository})
      : _repo = repository,
        super(const FitnessInitial());

  final FitnessRepository _repo;

  Future<void> load() async {
    if (state is FitnessLoaded) return;
    state = const FitnessLoading();
    await _fetch();
  }

  Future<void> refresh() async {
    final current = state.data;
    state = current != null
        ? FitnessRefreshing(data: current)
        : const FitnessLoading();
    await _fetch();
  }

  Future<void> _fetch() async {
    try {
      final results = await Future.wait([
        _repo.getStats(),
        _repo.getTodayActivity(),
        _repo.getWorkouts(),
        _repo.getHistory(),
        _repo.getAchievements(),
      ]);
      state = FitnessLoaded(
        stats: results[0] as FitnessStatsEntity,
        todayActivity: results[1] as DailyActivityEntity,
        workouts: results[2] as List<WorkoutEntity>,
        history: results[3] as List<WorkoutHistoryEntry>,
        achievements: results[4] as List<AchievementEntity>,
      );
    } catch (e, st) {
      log.error('FitnessNotifier: load failed', error: e, stackTrace: st);
      state = FitnessError(
        message: 'Failed to load fitness data. Pull to refresh.',
      );
    }
  }
}

// ── Workout Library Notifier ─────────────────────────────────────────────────

class WorkoutLibraryNotifier extends StateNotifier<WorkoutLibraryState> {
  WorkoutLibraryNotifier({required FitnessRepository repository})
      : _repo = repository,
        super(const WorkoutLibraryLoading()) {
    _load();
  }

  final FitnessRepository _repo;

  Future<void> _load() async {
    try {
      final workouts = await _repo.getWorkouts();
      state = WorkoutLibraryLoaded(workouts: workouts);
    } catch (e) {
      state = WorkoutLibraryError(message: e.toString());
    }
  }

  Future<void> filterByCategory(WorkoutCategory? category) async {
    state = const WorkoutLibraryLoading();
    try {
      final workouts = category == null
          ? await _repo.getWorkouts()
          : await _repo.getWorkoutsByCategory(category);
      state = WorkoutLibraryLoaded(workouts: workouts);
    } catch (e) {
      state = WorkoutLibraryError(message: e.toString());
    }
  }

  Future<void> toggleFavourite(String workoutId) async {
    final current = state;
    if (current is! WorkoutLibraryLoaded) return;
    try {
      final updated = await _repo.toggleFavourite(workoutId);
      final idx = current.workouts.indexWhere((w) => w.id == workoutId);
      if (idx == -1) return;
      final list = List<WorkoutEntity>.from(current.workouts);
      list[idx] = updated;
      state = WorkoutLibraryLoaded(workouts: list);
    } catch (e) {
      log.error('WorkoutLibraryNotifier: toggleFavourite failed', error: e);
    }
  }
}

// ── Session Notifier (Timer logic) ────────────────────────────────────────────

class WorkoutSessionNotifier extends StateNotifier<SessionState> {
  WorkoutSessionNotifier({required FitnessRepository repository})
      : _repo = repository,
        super(const SessionIdle());

  final FitnessRepository _repo;

  Timer? _elapsedTimer;
  Timer? _restTimer;

  // ── Start ─────────────────────────────────────────────────────────────────

  void startWorkout(WorkoutEntity workout) {
    _cancelTimers();
    final session = WorkoutSessionEntity(
      workout: workout,
      currentExerciseIndex: 0,
      currentSet: 1,
      elapsedSeconds: 0,
      status: SessionStatus.active,
      completedExerciseIds: [],
    );
    state = SessionActive(session: session);
    _startElapsedTimer();
  }

  // ── Pause / Resume ────────────────────────────────────────────────────────

  void pause() {
    final s = _currentSession;
    if (s == null || s.status != SessionStatus.active) return;
    _cancelTimers();
    state = SessionActive(session: s.copyWith(status: SessionStatus.paused));
  }

  void resume() {
    final s = _currentSession;
    if (s == null || s.status != SessionStatus.paused) return;
    state = SessionActive(session: s.copyWith(status: SessionStatus.active));
    _startElapsedTimer();
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void nextExercise() {
    final s = _currentSession;
    if (s == null || !s.hasNext) return;
    _cancelTimers();
    final completed = List<String>.from(s.completedExerciseIds)
      ..add(s.currentExercise.id);
    state = SessionActive(
      session: s.copyWith(
        currentExerciseIndex: s.currentExerciseIndex + 1,
        currentSet: 1,
        completedExerciseIds: completed,
        clearRest: true,
      ),
    );
    _startElapsedTimer();
  }

  void previousExercise() {
    final s = _currentSession;
    if (s == null || !s.hasPrevious) return;
    _cancelTimers();
    state = SessionActive(
      session: s.copyWith(
        currentExerciseIndex: s.currentExerciseIndex - 1,
        currentSet: 1,
        clearRest: true,
      ),
    );
    _startElapsedTimer();
  }

  void nextSet() {
    final s = _currentSession;
    if (s == null) return;
    final exercise = s.currentExercise;
    if (s.currentSet >= exercise.sets) {
      // All sets done — start rest then move on
      if (s.hasNext) {
        _startRest(exercise.restSeconds, onDone: nextExercise);
      } else {
        finishWorkout();
      }
    } else {
      _startRest(exercise.restSeconds, onDone: () {
        final updated = _currentSession;
        if (updated == null) return;
        state = SessionActive(
          session: updated.copyWith(
            currentSet: updated.currentSet + 1,
            clearRest: true,
          ),
        );
      });
    }
  }

  // ── Finish ────────────────────────────────────────────────────────────────

  void finishWorkout() {
    final s = _currentSession;
    if (s == null) return;
    _cancelTimers();
    final completed = List<String>.from(s.completedExerciseIds)
      ..add(s.currentExercise.id);
    final finished = s.copyWith(
      status: SessionStatus.finished,
      completedExerciseIds: completed,
      clearRest: true,
    );
    state = SessionFinished(session: finished);
    _logSession(finished);
  }

  void reset() {
    _cancelTimers();
    state = const SessionIdle();
  }

  // ── Private ───────────────────────────────────────────────────────────────

  WorkoutSessionEntity? get _currentSession => state.session;

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final s = _currentSession;
      if (s == null || s.status != SessionStatus.active) return;
      state = SessionActive(
        session: s.copyWith(elapsedSeconds: s.elapsedSeconds + 1),
      );
    });
  }

  void _startRest(int seconds, {required VoidCallback onDone}) {
    final s = _currentSession;
    if (s == null) return;
    state = SessionActive(session: s.copyWith(restCountdownSeconds: seconds));
    _restTimer?.cancel();
    int remaining = seconds;
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      remaining--;
      final updated = _currentSession;
      if (updated == null) {
        t.cancel();
        return;
      }
      if (remaining <= 0) {
        t.cancel();
        state = SessionActive(session: updated.copyWith(clearRest: true));
        onDone();
      } else {
        state = SessionActive(
          session: updated.copyWith(restCountdownSeconds: remaining),
        );
      }
    });
  }

  void _cancelTimers() {
    _elapsedTimer?.cancel();
    _restTimer?.cancel();
  }

  Future<void> _logSession(WorkoutSessionEntity s) async {
    try {
      await _repo.logSession(
        WorkoutHistoryEntry(
          id: 'session_${DateTime.now().millisecondsSinceEpoch}',
          workoutId: s.workout.id,
          workoutTitle: s.workout.title,
          category: s.workout.category.label,
          completedAt: DateTime.now(),
          durationMinutes: (s.elapsedSeconds / 60).round(),
          caloriesBurned: s.caloriesBurnedSoFar,
          exercisesCompleted: s.completedExerciseIds.length,
        ),
      );
    } catch (e) {
      log.error('Failed to log session', error: e);
    }
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }
}

// ── History Notifier ─────────────────────────────────────────────────────────

class WorkoutHistoryNotifier extends StateNotifier<HistoryState> {
  WorkoutHistoryNotifier({required FitnessRepository repository})
      : _repo = repository,
        super(const HistoryLoading()) {
    _load();
  }

  final FitnessRepository _repo;

  Future<void> _load() async {
    try {
      final entries = await _repo.getHistory();
      state = HistoryLoaded(entries: entries);
    } catch (e) {
      state = HistoryError(message: e.toString());
    }
  }

  Future<void> refresh() => _load();
}

typedef VoidCallback = void Function();

