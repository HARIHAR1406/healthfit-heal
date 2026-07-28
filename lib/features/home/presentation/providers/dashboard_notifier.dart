import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/repositories/dashboard_repository.dart';
import 'dashboard_state.dart';

/// Manages the Home Dashboard state.
///
/// Call [load] once on mount and [refresh] on pull-to-refresh.
class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier({required DashboardRepository repository})
      : _repository = repository,
        super(const DashboardInitial());

  final DashboardRepository _repository;

  // ── Load ──────────────────────────────────────────────────────────────────

  /// Initial data load — shows skeleton loader.
  Future<void> load() async {
    if (state is DashboardLoaded) return; // Already loaded; skip.
    state = const DashboardLoading();
    await _fetch(isRefresh: false);
  }

  // ── Refresh ───────────────────────────────────────────────────────────────

  /// Pull-to-refresh — keeps stale data visible during reload.
  Future<void> refresh() async {
    final current = state.data;
    if (current != null) {
      state = DashboardRefreshing(data: current);
    } else {
      state = const DashboardLoading();
    }
    await _fetch(isRefresh: true);
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<void> _fetch({required bool isRefresh}) async {
    try {
      final data = isRefresh
          ? await _repository.refresh()
          : await _repository.getDashboard();
      state = DashboardLoaded(data: data);
      log.info('DashboardNotifier: data loaded successfully');
    } on AppException catch (e) {
      log.error('DashboardNotifier: load failed', error: e);
      state = DashboardError(message: e.message);
    } catch (e, st) {
      log.error('DashboardNotifier: unexpected error', error: e, stackTrace: st);
      state = const DashboardError(
        message: 'Failed to load dashboard. Pull to refresh.',
      );
    }
  }
}
