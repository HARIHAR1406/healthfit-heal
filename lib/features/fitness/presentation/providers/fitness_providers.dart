import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/achievement_entity.dart';
import '../../domain/entities/fitness_stats_entity.dart';
import '../../domain/entities/workout_entity.dart';
import '../../domain/entities/workout_session_entity.dart';
import 'fitness_notifier.dart';
import 'fitness_state.dart';

// ── Master State ──────────────────────────────────────────────────────────────

final fitnessNotifierProvider =
    StateNotifierProvider<FitnessNotifier, FitnessState>(
  (ref) => FitnessNotifier(
    repository: ref.watch(fitnessRepositoryProvider),
  ),
  name: 'fitnessNotifierProvider',
);

// ── Data Selectors ────────────────────────────────────────────────────────────

final fitnessLoadedDataProvider = Provider<FitnessLoaded?>(
  (ref) => ref.watch(fitnessNotifierProvider).data,
  name: 'fitnessLoadedDataProvider',
);

final fitnessStatsProvider = Provider<FitnessStatsEntity?>(
  (ref) => ref.watch(fitnessLoadedDataProvider)?.stats,
  name: 'fitnessStatsProvider',
);

final todayActivityProvider = Provider<DailyActivityEntity?>(
  (ref) => ref.watch(fitnessLoadedDataProvider)?.todayActivity,
  name: 'todayActivityProvider',
);

final allWorkoutsProvider = Provider<List<WorkoutEntity>>(
  (ref) => ref.watch(fitnessLoadedDataProvider)?.workouts ?? [],
  name: 'allWorkoutsProvider',
);

final recentWorkoutHistoryProvider = Provider<List<WorkoutHistoryEntry>>(
  (ref) => (ref.watch(fitnessLoadedDataProvider)?.history ?? []).take(5).toList(),
  name: 'recentWorkoutHistoryProvider',
);

final allAchievementsProvider = Provider<List<AchievementEntity>>(
  (ref) => ref.watch(fitnessLoadedDataProvider)?.achievements ?? [],
  name: 'allAchievementsProvider',
);

final unlockedAchievementsProvider = Provider<List<AchievementEntity>>(
  (ref) => ref
      .watch(allAchievementsProvider)
      .where((a) => a.isUnlocked)
      .toList(),
  name: 'unlockedAchievementsProvider',
);

// ── Workout Library ───────────────────────────────────────────────────────────

final workoutLibraryProvider =
    StateNotifierProvider<WorkoutLibraryNotifier, WorkoutLibraryState>(
  (ref) => WorkoutLibraryNotifier(
    repository: ref.watch(fitnessRepositoryProvider),
  ),
  name: 'workoutLibraryProvider',
);

/// Currently selected category filter (null = All).
final selectedCategoryProvider = StateProvider<WorkoutCategory?>(
  (_) => null,
  name: 'selectedCategoryProvider',
);

/// Filtered workouts based on selected category + search query.
final filteredWorkoutsProvider = Provider<List<WorkoutEntity>>(
  (ref) {
    final libraryState = ref.watch(workoutLibraryProvider);
    if (libraryState is! WorkoutLibraryLoaded) return [];
    final query = ref.watch(workoutSearchProvider).toLowerCase().trim();
    return libraryState.workouts.where((w) {
      final matchesSearch = query.isEmpty ||
          w.title.toLowerCase().contains(query) ||
          w.category.label.toLowerCase().contains(query);
      return matchesSearch;
    }).toList();
  },
  name: 'filteredWorkoutsProvider',
);

/// Workout search query.
final workoutSearchProvider = StateProvider<String>(
  (_) => '',
  name: 'workoutSearchProvider',
);

// ── Active Session ────────────────────────────────────────────────────────────

final workoutSessionProvider =
    StateNotifierProvider<WorkoutSessionNotifier, SessionState>(
  (ref) => WorkoutSessionNotifier(
    repository: ref.watch(fitnessRepositoryProvider),
  ),
  name: 'workoutSessionProvider',
);

final activeSessionProvider = Provider<WorkoutSessionEntity?>(
  (ref) => ref.watch(workoutSessionProvider).session,
  name: 'activeSessionProvider',
);

// ── History ───────────────────────────────────────────────────────────────────

final workoutHistoryNotifierProvider =
    StateNotifierProvider<WorkoutHistoryNotifier, HistoryState>(
  (ref) => WorkoutHistoryNotifier(
    repository: ref.watch(fitnessRepositoryProvider),
  ),
  name: 'workoutHistoryNotifierProvider',
);

/// Search query for history list.
final historySearchProvider = StateProvider<String>(
  (_) => '',
  name: 'historySearchProvider',
);

/// Filtered history entries.
final filteredHistoryProvider = Provider<List<WorkoutHistoryEntry>>(
  (ref) {
    final state = ref.watch(workoutHistoryNotifierProvider);
    if (state is! HistoryLoaded) return [];
    final query = ref.watch(historySearchProvider).toLowerCase().trim();
    if (query.isEmpty) return state.entries;
    return state.entries
        .where((e) =>
            e.workoutTitle.toLowerCase().contains(query) ||
            e.category.toLowerCase().contains(query))
        .toList();
  },
  name: 'filteredHistoryProvider',
);

// ── Analytics ─────────────────────────────────────────────────────────────────

/// Selected analytics period.
enum AnalyticsPeriod { week, month }

final analyticsPeriodProvider = StateProvider<AnalyticsPeriod>(
  (_) => AnalyticsPeriod.week,
  name: 'analyticsPeriodProvider',
);

